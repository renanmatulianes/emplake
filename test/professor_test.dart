// The expressions the professor listed as mandatory: compound expressions
// must be typeable, and precedence must match the original Emplake.
import 'package:emplake/math_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _ = <Op>[];

/// Types [target] like a player, slot by slot and left to right ("=" is already
/// on the plate), and returns what ended up on the display.
List<List<Op>>? type(String digits, List<List<Op>> target) {
  final eq = target.indexWhere((g) => g.contains(Op.equals));
  List<List<Op>>? gaps = List.generate(5, (g) => g == eq ? [Op.equals] : <Op>[]);
  for (var g = 0; g < 5; g++) {
    final at = target[g].indexOf(Op.equals);
    for (var j = 0; j < target[g].length; j++) {
      if (j == at) continue;
      gaps = place(digits, gaps!, g, target[g][j], afterEq: at < 0 ? null : j > at);
      if (gaps == null) return null;
    }
  }
  return gaps;
}

const syntaxErrors = {
  ErrorCode.unexpected, ErrorCode.incomplete, ErrorCode.unclosed, //
  ErrorCode.equals, ErrorCode.emptySide, ErrorCode.notAllowed,
};

void main() {
  group('compound expressions can be typed', () {
    test('−−(∛(−(3!−√(8))) + 7!!) = ∛(√(8!))', () {
      final target = [
        [Op.minus, Op.minus, Op.lparen, Op.cbrt, Op.lparen, Op.minus, Op.lparen],
        [Op.fact, Op.minus, Op.sqrt, Op.lparen],
        [Op.rparen, Op.rparen, Op.rparen, Op.plus],
        [Op.fact, Op.fact, Op.rparen, Op.equals, Op.cbrt, Op.lparen, Op.sqrt, Op.lparen],
        [Op.fact, Op.rparen, Op.rparen],
      ];
      expect(type('3878', target), target);
      final c = check('3878', target, Level.easy);
      expect(syntaxErrors, isNot(contains(c.error?.code)), reason: '${c.error}');
    });

    test('√(√(−(2−6)!!)!) = (√8)×1!', () {
      final target = [
        [Op.sqrt, Op.lparen, Op.sqrt, Op.lparen, Op.minus, Op.lparen],
        [Op.minus],
        [Op.rparen, Op.fact, Op.fact, Op.rparen, Op.fact, Op.rparen, Op.equals, Op.lparen, Op.sqrt],
        [Op.rparen, Op.times],
        [Op.fact],
      ];
      expect(type('2681', target), target);
      final c = check('2681', target, Level.easy);
      expect(syntaxErrors, isNot(contains(c.error?.code)), reason: '${c.error}');
    });

    test('a delimiter can follow any other delimiter', () {
      // ( ( | ⌊ ⌈ − √ ∛ ( 8 ...
      final g = type('8131', [
        [Op.lparen, Op.lparen, Op.abs, Op.floorL, Op.ceilL, Op.minus, Op.sqrt, Op.cbrt, Op.lparen],
        [Op.rparen, Op.ceilR, Op.floorR, Op.abs, Op.rparen, Op.rparen, Op.plus],
        [Op.equals],
        _,
        _,
      ]);
      expect(g, isNotNull);
      expect(check('8131', g!, Level.easy).error, isNull);
    });
  });

  group('precedence', () {
    Check solve(String digits, List<List<Op>> target, [Level level = Level.easy]) {
      expect(type(digits, target), target, reason: 'typeable');
      return check(digits, target, level);
    }

    test('1 + 2×3 = 7', () {
      expect(solve('1237', [_, [Op.plus], [Op.times], [Op.equals], _]).solved, isTrue);
    });

    test('∛8! + 0 = 1 + 1 is (∛8)! + 0', () {
      final c = solve('8011', [[Op.cbrt], [Op.fact, Op.plus], [Op.equals], [Op.plus], _]);
      expect(c.solved, isTrue, reason: '${c.left} ${c.right} ${c.error}');
    });

    test('√8! is (√8)!, not √(8!)', () {
      final c = solve('8011', [[Op.sqrt], [Op.fact, Op.plus], [Op.equals], [Op.plus], _]);
      expect(c.error?.code, ErrorCode.factorial, reason: 'the factorial is applied to √8');
    });

    test('2×3! = 8 + 4 is 2×(3!)', () {
      expect(solve('2384', [_, [Op.times], [Op.fact, Op.equals], [Op.plus], _]).solved, isTrue);
    });

    test('−2 + 2 = 0 + 0 is (−2) + 2', () {
      expect(solve('2200', [[Op.minus], [Op.plus], [Op.equals], [Op.plus], _]).solved, isTrue);
    });

    test('−−2 + 0! = 3 + 0', () {
      expect(solve('2030', [[Op.minus, Op.minus], [Op.plus], [Op.fact, Op.equals], [Op.plus], _]).solved,
          isTrue);
    });

    test('−(−2 + 5) = 4 − 7', () {
      expect(
        solve('2547', [[Op.minus, Op.lparen, Op.minus], [Op.plus], [Op.rparen, Op.equals], [Op.minus], _]).solved,
        isTrue,
      );
    });

    test('these also hold at every level that has the operators', () {
      expect(solve('1237', [_, [Op.plus], [Op.times], [Op.equals], _], Level.hard).solved, isTrue);
      expect(solve('2384', [_, [Op.times], [Op.fact, Op.equals], [Op.plus], _], Level.advanced).solved, isTrue);
      expect(solve('2547', [[Op.minus, Op.lparen, Op.minus], [Op.plus], [Op.rparen, Op.equals], [Op.minus], _],
          Level.hard).solved, isTrue);
    });
  });
}
