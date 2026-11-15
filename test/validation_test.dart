// Adversarial tests: what happens when the player tries something wrong.
import 'dart:math' as math;

import 'package:emplake/game.dart';
import 'package:emplake/math_engine.dart';
import 'package:emplake/repository.dart';
import 'package:emplake/settings.dart';
import 'package:flutter_math_fork/tex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide same;
import 'package:shared_preferences/shared_preferences.dart';

const _ = <Op>[];

class FakeRepo extends Repo {
  FakeRepo({Map<Level, Set<String>> solved = const {}, this.fail = false}) : super('test') {
    current = Profile(0, {
      for (final l in Level.values) l: {for (final n in solved[l] ?? const <String>{}) n: ''},
    });
  }
  bool fail;
  int saves = 0;

  @override
  Future<Profile> profile() async => current!;

  @override
  Future<Profile> reload() async => current!;

  @override
  Future<void> markSolved(Level level, String number, String latex) async {
    if (fail) throw Exception('offline');
    final p = current!;
    if (p.isSolved(level, number)) return;
    saves++;
    p.score += level.points;
    p.solved[level]![number] = latex;
  }
}

Future<(ProviderContainer, FakeRepo)> game({Map<String, Object> prefs = const {}, FakeRepo? repo}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final r = repo ?? FakeRepo();
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(p),
    repoProvider.overrideWithValue(r),
  ]);
  addTearDown(c.dispose);
  c.read(gameProvider.notifier).attach(r.current!);
  return (c, r);
}

void main() {
  group('engine never crashes', () {
    test('arbitrary symbol soup at every level returns a Check with parseable LaTeX', () {
      final rng = math.Random(3);
      for (var i = 0; i < 40000; i++) {
        final digits = rng.nextInt(10000).toString().padLeft(4, '0');
        final gaps = [
          for (var g = 0; g < 5; g++) [for (var k = rng.nextInt(4); k > 0; k--) Op.values[rng.nextInt(Op.values.length)]],
        ];
        final level = Level.values[rng.nextInt(4)];
        final why = '$digits ${linearize(digits, gaps)} $level';
        late Check c;
        expect(() => c = check(digits, gaps, level), returnsNormally, reason: why);
        if (c.error == null) {
          expect(c.left!.isFinite && c.right!.isFinite, isTrue, reason: why);
        }
        expect(() => SyntaxTree(greenRoot: TexParser(c.latex, const TexParserSettings()).parse()), returnsNormally,
            reason: '$why → ${c.latex}');
      }
    });

    test('operators outside the level are always refused', () {
      for (final level in Level.values) {
        for (final op in Op.values.where((o) => o != Op.equals && !level.ops.contains(o))) {
          final c = check('1111', [[op], _, [Op.equals], _, _], level);
          expect(c.error?.code, ErrorCode.notAllowed, reason: '$level $op');
          expect(c.solved, isFalse);
        }
      }
    });
  });

  group('math edge cases', () {
    ErrorCode? err(String d, List<List<Op>> g, [Level l = Level.easy]) => check(d, g, l).error?.code;

    test('division by zero, including 0/0', () {
      expect(err('1010', [_, [Op.divide], [Op.equals], [Op.divide], _]), ErrorCode.divZero);
      expect(err('0000', [_, [Op.divide], [Op.equals], _, _]), ErrorCode.divZero);
    });

    test('roots and factorial of invalid values', () {
      // √(1−5) = 11
      expect(err('1511', [[Op.sqrt, Op.lparen], [Op.minus], [Op.rparen, Op.equals], _, _]), ErrorCode.sqrtNegative);
      // (5/2)! = 11
      expect(err('5211', [[Op.lparen], [Op.divide], [Op.rparen, Op.fact, Op.equals], _, _]), ErrorCode.factorial);
      // (1−5)! = 11
      expect(err('1511', [[Op.lparen], [Op.minus], [Op.rparen, Op.fact, Op.equals], _, _]), ErrorCode.factorial);
      // 9!!! = 1 (overflow)
      expect(err('9111', [_, [Op.fact, Op.fact, Op.fact, Op.equals], _, _, _]), isNotNull);
      // ∛(−8) = −2
      final c = check('0802', [[Op.cbrt, Op.lparen], [Op.minus], [Op.rparen, Op.equals, Op.minus], _, _], Level.easy);
      expect(c.left, -2, reason: '${c.error}');
    });

    test('powers: 0^0, 0^−1, huge, negative base with fractional exponent', () {
      expect(check('0011', [_, [Op.pow], [Op.equals], _, _], Level.easy).left, 1);
      expect(err('0111', [_, [Op.pow, Op.minus], [Op.equals], _, _]), isNotNull); // 0^−1
      expect(err('9999', [_, [Op.pow], [Op.pow], [Op.equals], _]), ErrorCode.tooBig); // 9^9^9 = 9
      // (1−9)^(1/2) = 2 → not a real number
      expect(
        err('1912', [[Op.lparen], [Op.minus], [Op.rparen, Op.pow, Op.lparen], [Op.divide], [Op.rparen, Op.equals]]),
        isNotNull,
      );
    });

    test('non-integer division is refused at every level but Easy, even inside a larger expression', () {
      // (5/2)*2 = 5 → 5/2 is not an integer
      final g = [[Op.lparen], [Op.divide], [Op.rparen, Op.times], [Op.equals], _];
      expect(check('5225', g, Level.easy).solved, isTrue);
      for (final l in [Level.intermediate, Level.advanced, Level.hard]) {
        expect(err('5225', g, l), ErrorCode.nonInteger, reason: '$l');
      }
    });

    test('a false equation with huge numbers is NOT accepted', () {
      // 4!! = 24! − 3  → 24! ≠ 24! − 3
      final c = check('4243', [_, [Op.fact, Op.fact, Op.equals], _, [Op.fact, Op.minus], _], Level.advanced);
      expect(c.solved, isFalse, reason: 'left=${c.left} right=${c.right} error=${c.error}');
    });

    test('a false equation just above 1e9 is NOT accepted', () {
      // 13! = 13! + 0 is fine, but 99^5 (9509900499) vs 99^5 + 1 must differ.
      expect(same(9509900499, 9509900500), isFalse);
    });

    test('trivially true plates still need "=" between two valid sides', () {
      expect(check('1111', [_, _, [Op.equals], _, _], Level.hard).solved, isTrue); // 11 = 11
      expect(check('1112', [_, _, [Op.equals], _, _], Level.hard).solved, isFalse);
    });
  });

  group('game controller misuse', () {
    test('restored garbage in SharedPreferences falls back to defaults', () async {
      final (c, _) = await game(prefs: {'level': 'nope', 'number': '0042'});
      expect(c.read(gameProvider).level, Level.easy);
      expect(c.read(gameProvider).number, '0042');
    });

    test('a non-numeric saved number does not crash the engine', () async {
      final (c, _) = await game(prefs: {'number': 'abcd'});
      final s = c.read(gameProvider);
      expect(() => check(s.number!, s.gaps, s.level), returnsNormally);
    });

    test('cursor stays in range; backspace/clear on an empty board are harmless', () async {
      final (c, _) = await game();
      final g = c.read(gameProvider.notifier);
      g.select(-5);
      expect(c.read(gameProvider).cursor, 0);
      g.select(99);
      expect(c.read(gameProvider).cursor, 4);
      for (var i = 0; i < 5; i++) {
        g.select(i);
        g.backspace();
        g.backspace();
      }
      g.clear();
      expect(c.read(gameProvider).gaps.expand((e) => e), [Op.equals]);
    });

    test('"=" survives backspace, clear and being moved', () async {
      final (c, _) = await game();
      final g = c.read(gameProvider.notifier);
      g.select(3);
      expect(g.insert(Op.equals), isTrue);
      g.backspace();
      g.clear();
      expect(c.read(gameProvider).gaps[3], [Op.equals]);
    });

    test('a refused operator leaves the board untouched and reports it', () async {
      final (c, _) = await game();
      final g = c.read(gameProvider.notifier);
      g.select(0);
      final before = c.read(gameProvider).gaps.toString();
      expect(g.insert(Op.plus), isFalse);
      expect(c.read(gameProvider).gaps.toString(), before);
      expect(c.read(gameProvider).rejected, Op.plus);
    });

    test('verifying a wrong or incomplete answer never saves', () async {
      final (c, r) = await game(prefs: {'number': '1234'});
      final g = c.read(gameProvider.notifier);
      expect(await g.verify(), isFalse); // 12 = 34
      g.select(0);
      g.insert(Op.lparen);
      expect(await g.verify(), isFalse); // (12 = 34
      expect(r.saves, 0);
      expect(c.read(gameProvider).score, 0);
      expect(c.read(gameProvider).number, '1234');
    });

    test('a correct answer saves once, scores, and the number never comes back', () async {
      final (c, r) = await game(prefs: {'number': '1111', 'level': 'hard'});
      final g = c.read(gameProvider.notifier);
      expect(await g.verify(), isTrue);
      expect(await g.verify(), isTrue, reason: 'double tap');
      expect(r.saves, 1);
      expect(c.read(gameProvider).score, 4);
      g.nextAfterSolve();
      for (var i = 0; i < 300; i++) {
        expect(c.read(gameProvider).number, isNot('1111'));
        g.skip();
      }
    });

    test('a save failure unlocks the board and keeps the number', () async {
      final (c, r) = await game(prefs: {'number': '1111'}, repo: FakeRepo(fail: true));
      final g = c.read(gameProvider.notifier);
      expect(await g.verify(), isFalse);
      final s = c.read(gameProvider);
      expect(s.busy, isFalse);
      expect(s.saveError, isNotNull);
      expect(s.number, '1111');
      r.fail = false;
      expect(await g.verify(), isTrue);
    });

    test('changing level keeps an unsolved number and replaces a solved one', () async {
      final (c, _) = await game(
        prefs: {'number': '1111'},
        repo: FakeRepo(solved: {Level.hard: {'1111'}}),
      );
      final g = c.read(gameProvider.notifier);
      g.setLevel(Level.advanced);
      expect(c.read(gameProvider).number, '1111');
      g.setLevel(Level.hard);
      expect(c.read(gameProvider).number, isNot('1111'));
    });

    test('operators placed at Easy cannot be smuggled into Hard', () async {
      final (c, _) = await game(prefs: {'number': '9339'});
      final g = c.read(gameProvider.notifier);
      g.select(0);
      g.insert(Op.sqrt); // √9 3 = 3 9
      g.setLevel(Level.hard);
      final s = c.read(gameProvider);
      expect(check(s.number!, s.gaps, s.level).error?.code, anyOf(isNull, ErrorCode.notAllowed));
      expect(s.gaps.expand((e) => e).where((o) => o != Op.equals && !Level.hard.ops.contains(o)), isEmpty);
    });

    test('skipping the last unsolved number does not claim everything is solved', () async {
      final all = {for (var i = 0; i < 10000; i++) i.toString().padLeft(4, '0')}..remove('0007');
      final (c, _) = await game(repo: FakeRepo(solved: {Level.easy: all}));
      final g = c.read(gameProvider.notifier);
      expect(c.read(gameProvider).number, '0007');
      g.skip();
      expect(c.read(gameProvider).exhausted, isFalse);
      expect(c.read(gameProvider).number, '0007');
    });

    test('with every number solved the game reports it and verify does nothing', () async {
      final all = {for (var i = 0; i < 10000; i++) i.toString().padLeft(4, '0')};
      final (c, r) = await game(repo: FakeRepo(solved: {Level.easy: all}));
      final g = c.read(gameProvider.notifier);
      expect(c.read(gameProvider).exhausted, isTrue);
      expect(await g.verify(), isFalse);
      g.skip();
      expect(r.saves, 0);
      g.setLevel(Level.hard);
      expect(c.read(gameProvider).exhausted, isFalse);
    });
  });

  test('profile parsing tolerates malformed Firestore documents', () {
    expect(Profile.fromData(null).score, 0);
    expect(Profile.fromData({'score': 2.0, 'solved': {'easy': {'0001': {'latex': 'x'}, '0002': null}}}).solved[Level.easy],
        {'0001': 'x', '0002': ''});
    expect(() => Profile.fromData({'score': 'abc'}), returnsNormally);
    expect(() => Profile.fromData({'solved': 'abc'}), returnsNormally);
    expect(() => Profile.fromData({'solved': {'easy': {'0001': 'abc'}}}), returnsNormally);
  });
}
