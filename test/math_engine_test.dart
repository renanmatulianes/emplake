import 'dart:math' as math;

import 'package:emplake/math_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _ = <Op>[];

Check run(String digits, List<List<Op>> gaps, [Level level = Level.easy]) =>
    check(digits, gaps, level);

List<List<Op>> fresh([int eq = 2]) => List.generate(5, (g) => g == eq ? [Op.equals] : <Op>[]);

/// Presses keys like the player: (slot, op) pairs; null as soon as one is refused.
List<List<Op>>? press(String digits, List<(int, Op)> keys, [int eq = 2]) {
  List<List<Op>>? gaps = fresh(eq);
  for (final (slot, op) in keys) {
    gaps = place(digits, gaps!, slot, op);
    if (gaps == null) return null;
  }
  return gaps;
}

const parseErrors = {
  ErrorCode.unexpected, ErrorCode.incomplete, ErrorCode.unclosed, //
  ErrorCode.equals, ErrorCode.emptySide, ErrorCode.notAllowed,
};

void main() {
  group('place', () {
    test('refuses combinations that can never be valid', () {
      final plus = press('8131', [(1, Op.plus)])!;
      expect(place('8131', plus, 1, Op.plus), isNull, reason: '8 + + 1');
      expect(place('8131', plus, 1, Op.times), isNull, reason: '8 + × 1');
      expect(press('8131', [(1, Op.lparen)]), isNull, reason: '8 ( 1');
      expect(press('8131', [(0, Op.sqrt), (0, Op.minus)]), isNull, reason: '√ − 8');
      expect(press('8131', [(0, Op.sqrt), (0, Op.plus)]), isNull, reason: '√ + 8');
      expect(press('8131', [(0, Op.plus)]), isNull, reason: 'side starting with +');
      expect(press('8131', [(4, Op.plus)]), isNull, reason: 'ends with +');
      expect(press('8131', [(4, Op.rparen)]), isNull, reason: ') with nothing open');
      expect(press('8131', [(0, Op.lparen), (2, Op.floorR)]), isNull, reason: '( closed by ⌋');
      expect(press('8131', [(0, Op.lparen), (1, Op.rparen), (1, Op.lparen)]), isNull,
          reason: '(8)(1 needs an operator between');
    });

    test('accepts sequences that make sense together', () {
      expect(press('8131', [(1, Op.plus), (1, Op.minus)]), isNotNull, reason: '8 + −1');
      expect(press('8131', [(0, Op.sqrt), (0, Op.lparen)]), isNotNull, reason: '√(');
      expect(press('8131', [(0, Op.sqrt), (0, Op.sqrt)]), isNotNull, reason: '√√8');
      expect(press('3131', [(1, Op.fact), (1, Op.fact)]), isNotNull, reason: '3!!');
      expect(press('2201', [(1, Op.pow), (1, Op.minus)]), isNotNull, reason: '2^−2');
    });

    test('a digit right after a value is allowed: an operator can still go between', () {
      final g = press('3161', [(1, Op.fact)])!; // 3!1 = 61, then 3!×1
      expect(place('3161', g, 1, Op.times)?[1], [Op.fact, Op.times]);
    });

    test('puts each symbol where it belongs inside the slot', () {
      expect(press('8131', [(2, Op.lparen)])![2], [Op.equals, Op.lparen], reason: 'opens the right side');
      expect(press('8131', [(0, Op.lparen), (2, Op.rparen)])![2], [Op.rparen, Op.equals],
          reason: 'closes the left side');
      expect(press('8131', [(0, Op.lparen), (1, Op.plus), (1, Op.rparen)])![1], [Op.rparen, Op.plus],
          reason: '(8)+1: ")" goes before "+"');
      expect(press('8131', [(0, Op.abs), (2, Op.abs)])![2], [Op.abs, Op.equals], reason: '|81| closes');
      expect(press('8131', [(2, Op.abs)])![2], [Op.equals, Op.abs], reason: 'nothing open: | opens');
      expect(press('5261', [(0, Op.lparen), (1, Op.minus), (2, Op.rparen), (2, Op.fact)])![2],
          [Op.rparen, Op.fact, Op.equals]);
    });

    test('"=" moves instead of duplicating and cannot leave a side empty', () {
      final g = press('8131', [(3, Op.equals)])!;
      expect(g.expand((s) => s).where((o) => o == Op.equals), hasLength(1));
      expect(g[3], [Op.equals]);
      expect(press('8131', [(0, Op.equals)]), isNull);
      expect(press('8131', [(4, Op.equals)]), isNull);
      expect(press('8131', [(1, Op.plus), (1, Op.equals)]), isNull, reason: '8 + = would follow +');
    });

    test('the examples can be typed in natural order', () {
      final g = press('8131', [(0, Op.sqrt), (0, Op.lparen), (1, Op.plus), (2, Op.rparen), (3, Op.pow)])!;
      expect(run('8131', g).latex, r'\sqrt{8 + 1} = {3}^{1}');
      expect(run('8131', g).solved, isTrue);
      final f = press('7252', [
        (0, Op.floorL), (1, Op.divide), (2, Op.floorR), (2, Op.ceilL), (3, Op.divide), (4, Op.ceilR), //
      ])!;
      expect(run('7252', f).solved, isTrue);
    });

    test('random key presses never build a malformed equation', () {
      final rng = math.Random(7);
      final ops = [...Level.easy.ops, Op.equals];
      for (var game = 0; game < 3000; game++) {
        final digits = rng.nextInt(10000).toString().padLeft(4, '0');
        var gaps = fresh();
        for (var k = 0; k < 15; k++) {
          gaps = place(digits, gaps, rng.nextInt(5), ops[rng.nextInt(ops.length)]) ?? gaps;
          final c = run(digits, gaps);
          final why = '$digits ${linearize(digits, gaps)} → ${c.error}';
          expect(gaps.expand((s) => s).where((o) => o == Op.equals), hasLength(1), reason: why);
          final code = c.error?.code;
          if (code == ErrorCode.unexpected) {
            expect(c.error!.token, matches(RegExp(r'^\d+$')), reason: why); // operator still missing
          } else if (code != ErrorCode.unclosed) {
            expect(parseErrors, isNot(contains(code)), reason: why);
          }
        }
      }
    });

    test('every well-formed equation can be typed left to right', () {
      final rng = math.Random(11);
      final ops = Level.easy.ops.toList();
      var found = 0;
      for (var i = 0; i < 200000 && found < 500; i++) {
        final digits = rng.nextInt(10000).toString().padLeft(4, '0');
        final eq = 1 + rng.nextInt(3);
        final target = [
          for (var g = 0; g < 5; g++) [
            for (var k = rng.nextInt(3); k > 0; k--) ops[rng.nextInt(ops.length)],
            if (g == eq) Op.equals,
            for (var k = g == eq ? rng.nextInt(2) : 0; k > 0; k--) ops[rng.nextInt(ops.length)],
          ],
        ];
        if (parseErrors.contains(run(digits, target).error?.code)) continue;
        found++;
        final keys = [
          for (var g = 0; g < 5; g++)
            for (final o in target[g])
              if (o != Op.equals) (g, o),
        ];
        expect(press(digits, keys, eq), target, reason: '$digits ${linearize(digits, target)}');
      }
      expect(found, greaterThan(100));
    });
  });

  test('√(8+1) = 3^1 is solved and rendered as LaTeX', () {
    final c = run('8131', [
      [Op.sqrt, Op.lparen], [Op.plus], [Op.rparen, Op.equals], [Op.pow], _, //
    ]);
    expect(c.solved, isTrue);
    expect(c.latex, r'\sqrt{8 + 1} = {3}^{1}');
  });

  test('digits with an empty slot between them form one number', () {
    final c = run('4114', [_, _, [Op.equals], [Op.plus], _]); // 41 = 1 + 4
    expect(c.left, 41);
    expect(c.right, 5);
    expect(c.solved, isFalse);
  });

  test('non-integer division only allowed at Easy', () {
    final gaps = [_, [Op.divide], [Op.equals], [Op.divide], _]; // 5/2 = 5/2
    expect(run('5252', gaps).solved, isTrue);
    expect(run('5252', gaps, Level.hard).error?.code, ErrorCode.nonInteger);
    expect(run('6262', gaps, Level.hard).solved, isTrue);
  });

  test('(5-2)! = 6*1', () {
    final c = run('5261', [
      [Op.lparen], [Op.minus], [Op.rparen, Op.fact, Op.equals], [Op.times], _, //
    ], Level.advanced);
    expect(c.solved, isTrue);
  });

  test('floor, ceil and precedence of unary minus over power', () {
    // ⌊7/2⌋ = ⌈5/2⌉ → 3 = 3
    expect(run('7252', [
      [Op.floorL], [Op.divide], [Op.floorR, Op.equals, Op.ceilL], [Op.divide], [Op.ceilR], //
    ]).solved, isTrue);
    // -2^2 = -4 → -(2^2)
    expect(run('2204', [
      [Op.minus], [Op.pow], [Op.equals], [Op.minus], _, //
    ]).left, -4);
  });

  test('errors: unclosed bracket, operator not allowed, missing operand', () {
    expect(run('1111', [[Op.lparen], _, [Op.equals], _, _]).error?.code, ErrorCode.unclosed);
    expect(run('1111', [[Op.sqrt], _, [Op.equals], _, _], Level.hard).error?.code,
        ErrorCode.notAllowed);
    expect(run('1111', [_, [Op.plus, Op.equals], _, _, _]).error?.code, ErrorCode.incomplete);
    expect(run('1111', [[Op.equals], _, _, _, _]).error?.code, ErrorCode.emptySide);
  });
}
