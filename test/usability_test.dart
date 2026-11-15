// The "_" marks around "=" and the plates without a solution.
import 'package:emplake/game.dart';
import 'package:emplake/math_engine.dart';
import 'package:emplake/repository.dart';
import 'package:emplake/settings.dart';
import 'package:emplake/unsolvable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ = <Op>[];

class FakeRepo extends Repo {
  FakeRepo() : super('test') {
    current = Profile(0, {for (final l in Level.values) l: {}});
  }

  @override
  Future<Profile> profile() async => current!;
}

Future<ProviderContainer> game(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final r = FakeRepo();
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(p),
    repoProvider.overrideWithValue(r),
  ]);
  addTearDown(c.dispose);
  c.read(gameProvider.notifier).attach(r.current!);
  return c;
}

void main() {
  group('both sides of "="', () {
    test('place can be limited to one side of "="', () {
      final g = [_, _, [Op.equals], _, _];
      expect(place('8131', g, 2, Op.lparen, afterEq: true)![2], [Op.equals, Op.lparen]);
      expect(place('8131', g, 2, Op.lparen, afterEq: false), isNull, reason: '81 ( = 31');
      final open = place('8131', g, 0, Op.lparen)!;
      expect(place('8131', open, 2, Op.rparen, afterEq: false)![2], [Op.rparen, Op.equals]);
      expect(place('8131', open, 2, Op.rparen, afterEq: true), isNull, reason: '(81 = ) 31');
    });

    test('the "=" slot has two cursor positions and the arrows walk through all six', () async {
      final c = await game({'number': '8131'});
      final g = c.read(gameProvider.notifier);
      expect(c.read(gameProvider).positions,
          [(0, false), (1, false), (2, false), (2, true), (3, false), (4, false)]);
      final seen = <(int, bool)>[];
      for (var i = 0; i < 8; i++) {
        seen.add((c.read(gameProvider).cursor, c.read(gameProvider).after));
        g.step(1);
      }
      expect(seen.toSet().length, 6);
      expect(seen.last, (4, false));
      g.step(-99);
      expect(c.read(gameProvider).cursor, 0);
    });

    test('a symbol typed on the wrong side of "=" lands on the right one and the cursor follows', () async {
      final c = await game({'number': '8131'});
      final g = c.read(gameProvider.notifier);
      g.select(2); // before "="
      expect(g.insert(Op.sqrt), isTrue); // only fits after "="
      expect(c.read(gameProvider).gaps[2], [Op.equals, Op.sqrt]);
      expect(c.read(gameProvider).after, isTrue);
    });

    test('moving "=" away resets the side', () async {
      final c = await game({'number': '8131'});
      final g = c.read(gameProvider.notifier);
      g.select(2, after: true);
      g.select(3);
      expect(g.insert(Op.equals), isTrue);
      final s = c.read(gameProvider);
      expect(s.gaps[3], [Op.equals]);
      expect((s.cursor, s.after), (3, false));
      expect(s.positions.contains((2, true)), isFalse);
    });

    test('backspace only removes symbols on the cursor side of "="', () async {
      final c = await game({'number': '8131'});
      final g = c.read(gameProvider.notifier);
      g.select(0);
      g.insert(Op.lparen);
      g.select(2);
      g.insert(Op.rparen); // ( 81 ) =
      g.select(2, after: true);
      g.insert(Op.minus); // = −31
      expect(c.read(gameProvider).gaps[2], [Op.rparen, Op.equals, Op.minus]);
      g.select(2);
      g.backspace();
      expect(c.read(gameProvider).gaps[2], [Op.equals, Op.minus]);
      g.backspace();
      expect(c.read(gameProvider).gaps[2], [Op.equals, Op.minus], reason: 'nothing left before "="');
      g.select(2, after: true);
      g.backspace();
      expect(c.read(gameProvider).gaps[2], [Op.equals]);
    });

    test('a new "_" is offered only while another symbol still fits', () async {
      final c = await game({'number': '8131', 'level': 'hard'});
      final g = c.read(gameProvider.notifier);
      expect(c.read(gameProvider).canExtend(1, false), isTrue, reason: 'empty slot');
      g.select(1);
      g.insert(Op.plus);
      expect(c.read(gameProvider).canExtend(1, false), isTrue, reason: '8 + −1 or 8 + (1');
      expect(c.read(gameProvider).canExtend(2, false), isFalse, reason: 'nothing open to close before "="');
      expect(c.read(gameProvider).canExtend(2, true), isTrue);
      expect(c.read(gameProvider).canExtend(4, false), isFalse, reason: 'Hard has no postfix operator');
    });
  });

  group('plates without a solution', () {
    test('known cases', () {
      expect(unsolvable[Level.easy], isEmpty);
      expect(unsolvable[Level.hard], contains('8123'));
      expect(unsolvable[Level.hard], isNot(contains('1234'))); // −1 + 2 + 3 = 4
      for (final l in Level.values) {
        expect(unsolvable[l]!.every((p) => RegExp(r'^\d{4}$').hasMatch(p)), isTrue);
        expect(unsolvable[l]!.length, lessThan(6000));
      }
    });

    test('they are never dealt, not by skipping nor by changing level', () async {
      final c = await game({'number': '8123', 'level': 'hard'});
      final g = c.read(gameProvider.notifier);
      expect(c.read(gameProvider).number, isNot('8123'), reason: 'a saved impossible plate is replaced');
      for (var i = 0; i < 2000; i++) {
        final s = c.read(gameProvider);
        expect(unsolvable[s.level], isNot(contains(s.number)));
        i % 50 == 49 ? g.setLevel(Level.values[(i ~/ 50) % 4]) : g.skip();
      }
    });
  });
}
