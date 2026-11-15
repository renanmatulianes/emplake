import 'dart:math' as math;

/// Every symbol the player can drop into a slot. [rawTex] is used to render
/// expressions that do not parse yet.
enum Op {
  plus('+', '+'),
  minus('−', '-'),
  times('×', r'\times'),
  divide('÷', r'\div'),
  lparen('(', '('),
  rparen(')', ')'),
  sqrt('√', r'\surd'),
  cbrt('∛', r'\sqrt[3]{\,}'),
  fact('!', '!'),
  pow('^', r'\wedge'),
  abs('|', '|'),
  floorL('⌊', r'\lfloor'),
  floorR('⌋', r'\rfloor'),
  ceilL('⌈', r'\lceil'),
  ceilR('⌉', r'\rceil'),
  equals('=', '=');

  const Op(this.symbol, this.rawTex);
  final String symbol;
  final String rawTex;
}

enum Level {
  easy(1),
  intermediate(2),
  advanced(3),
  hard(4);

  const Level(this.points);
  final int points;

  static const _base = {
    Op.plus, Op.minus, Op.times, Op.divide, Op.lparen, Op.rparen, Op.abs, //
  };

  Set<Op> get ops => switch (this) {
    hard => _base,
    advanced => {..._base, Op.sqrt, Op.fact},
    intermediate => {..._base, Op.sqrt, Op.cbrt, Op.fact, Op.pow},
    easy => {
      ..._base, Op.sqrt, Op.cbrt, Op.fact, Op.pow, //
      Op.floorL, Op.floorR, Op.ceilL, Op.ceilR,
    },
  };
}

enum ErrorCode {
  unexpected,
  incomplete,
  unclosed,
  equals,
  emptySide,
  divZero,
  nonInteger,
  factorial,
  sqrtNegative,
  power,
  tooBig,
  notAllowed,
}

class EmplakeError implements Exception {
  const EmplakeError(this.code, [this.token = '']);
  final ErrorCode code;
  final String token;

  @override
  String toString() => 'EmplakeError($code, $token)';
}

sealed class Node {
  const Node();
}

class Num extends Node {
  const Num(this.digits);
  final String digits;
}

/// Prefix/postfix operators and bracket pairs (keyed by the opening symbol).
class Un extends Node {
  const Un(this.op, this.child);
  final Op op;
  final Node child;
}

class Bin extends Node {
  const Bin(this.op, this.left, this.right);
  final Op op;
  final Node left, right;
}

/// Result of checking the player's equation; never throws.
class Check {
  const Check({required this.latex, this.left, this.right, this.error});
  final String latex;
  final double? left, right;
  final EmplakeError? error;

  bool get solved => error == null && left != null && right != null && same(left!, right!);
}

/// Largest magnitude at which every integer is still exact in a double (2^53).
const maxExact = 9007199254740992.0;

/// Integers are compared exactly; the tolerance only absorbs rounding noise of
/// roots and fractions, so it is capped instead of growing with the operands.
bool same(double a, double b) {
  if (a == a.roundToDouble() && b == b.roundToDouble()) return a == b;
  return (a - b).abs() <= math.min(1e-4, 1e-9 * math.max(1, math.max(a.abs(), b.abs())));
}

/// [gaps] has digits.length + 1 slots: slot i sits right before digit i.
/// Digits with an empty slot between them form one number (4 and 1 → 41).
List<Object> linearize(String digits, List<List<Op>> gaps) {
  final out = <Object>[];
  for (var g = 0; g < gaps.length; g++) {
    out.addAll(gaps[g]);
    if (g >= digits.length) continue;
    if (g > 0 && gaps[g].isEmpty && out.last is String) {
      out.last = (out.last as String) + digits[g];
    } else {
      out.add(digits[g]);
    }
  }
  return out;
}

enum _Want { operand, primary, value }

const _openerOf = {Op.rparen: Op.lparen, Op.floorR: Op.floorL, Op.ceilR: Op.ceilL};

/// Mirrors the parser token by token. Returns the indexes of operators that can
/// never be valid where they stand (index toks.length = an operator missing at
/// the end) plus how many brackets are still open. A digit right after a value
/// is not counted: inserting an operator between them can still fix it.
({Set<int> bad, int open}) _scan(List<Object> toks) {
  final bad = <int>{};
  final stack = <Op>[];
  var open = 0;
  var want = _Want.operand;
  for (var i = 0; i < toks.length; i++) {
    final t = toks[i];
    if (t is String) {
      want = _Want.value;
      continue;
    }
    final value = want == _Want.value;
    final op = t as Op;
    final bool ok;
    switch (op) {
      case Op.plus || Op.times || Op.divide || Op.pow:
        ok = value;
        want = _Want.operand;
      case Op.minus:
        ok = want != _Want.primary;
        want = _Want.operand;
      case Op.sqrt || Op.cbrt:
        ok = !value;
        want = _Want.primary;
      case Op.lparen || Op.floorL || Op.ceilL:
        ok = !value;
        stack.add(op);
        want = _Want.operand;
      case Op.abs when !value:
        ok = true;
        stack.add(op);
        want = _Want.operand;
      case Op.abs || Op.rparen || Op.floorR || Op.ceilR:
        ok = value && stack.isNotEmpty && stack.last == (_openerOf[op] ?? Op.abs);
        if (ok) stack.removeLast();
      case Op.fact:
        ok = value;
      case Op.equals:
        ok = value;
        open += stack.length;
        stack.clear();
        want = _Want.operand;
    }
    if (!ok) bad.add(i);
  }
  if (want != _Want.value) bad.add(toks.length);
  return (bad: bad, open: open + stack.length);
}

/// Inserts [op] at the end of [slot], keeping the equation well-formed. Symbols
/// that close the value on their left (and "=") may also land earlier in the
/// slot, e.g. ")" before "=" or "+"; "|" prefers closing an open one. "=" is
/// moved, never duplicated. Returns null when [op] fits nowhere.
///
/// In the slot that holds "=", [afterEq] limits the insertion to one side of
/// it (false = before, true = after); null accepts either side.
List<List<Op>>? place(String digits, List<List<Op>> gaps, int slot, Op op, {bool? afterEq}) {
  final before = _scan(linearize(digits, gaps)).bad.length;
  final base = [
    for (final g in gaps) [...g]..removeWhere((o) => op == Op.equals && o == Op.equals),
  ];
  const closers = {Op.rparen, Op.floorR, Op.ceilR, Op.fact, Op.abs, Op.equals};
  final end = base[slot].length;
  final eq = base[slot].indexOf(Op.equals);
  final hi = eq >= 0 && afterEq == false ? eq : end;
  final lo = eq >= 0 && afterEq == true ? eq + 1 : 0;
  List<List<Op>>? best;
  var bestOpen = 0;
  for (var j = hi; j >= (closers.contains(op) ? lo : hi); j--) {
    final c = [for (final g in base) [...g]];
    c[slot].insert(j, op);
    final s = _scan(linearize(digits, c));
    final at = linearize(digits.substring(0, slot), [...c.take(slot), c[slot].sublist(0, j + 1)]).length - 1;
    if (s.bad.contains(at) || s.bad.length > before) continue;
    if (best == null || s.open < bestOpen) (best, bestOpen) = (c, s.open);
  }
  return best;
}

Check check(String digits, List<List<Op>> gaps, Level level) {
  final toks = linearize(digits, gaps);
  String? latex;
  try {
    final bad = toks.whereType<Op>().where((o) => o != Op.equals && !level.ops.contains(o));
    if (bad.isNotEmpty) throw EmplakeError(ErrorCode.notAllowed, bad.first.symbol);
    final eq = toks.indexOf(Op.equals);
    if (eq < 0 || toks.lastIndexOf(Op.equals) != eq) throw const EmplakeError(ErrorCode.equals);
    final l = _Parser(toks.sublist(0, eq)).parse();
    final r = _Parser(toks.sublist(eq + 1)).parse();
    latex = '${tex(l)} = ${tex(r)}';
    return Check(latex: latex, left: eval(l, level), right: eval(r, level));
  } on EmplakeError catch (e) {
    return Check(
      latex: latex ?? toks.map((t) => t is Op ? t.rawTex : t).join(' '),
      error: e,
    );
  }
}

class _Parser {
  _Parser(this.toks);
  final List<Object> toks;
  int i = 0;

  static const _closers = {
    Op.lparen: Op.rparen, Op.abs: Op.abs, Op.floorL: Op.floorR, Op.ceilL: Op.ceilR, //
  };

  Object? get peek => i < toks.length ? toks[i] : null;

  bool eat(Op op) {
    if (peek != op) return false;
    i++;
    return true;
  }

  static String _sym(Object t) => t is Op ? t.symbol : '$t';

  Node parse() {
    if (toks.isEmpty) throw const EmplakeError(ErrorCode.emptySide);
    final n = expr();
    if (peek != null) throw EmplakeError(ErrorCode.unexpected, _sym(peek!));
    return n;
  }

  Node expr() {
    var n = term();
    while (true) {
      if (eat(Op.plus)) {
        n = Bin(Op.plus, n, term());
      } else if (eat(Op.minus)) {
        n = Bin(Op.minus, n, term());
      } else {
        return n;
      }
    }
  }

  Node term() {
    var n = unary();
    while (true) {
      if (eat(Op.times)) {
        n = Bin(Op.times, n, unary());
      } else if (eat(Op.divide)) {
        n = Bin(Op.divide, n, unary());
      } else {
        return n;
      }
    }
  }

  // -2^2 = -(2^2); exponent is right-associative.
  Node unary() => eat(Op.minus) ? Un(Op.minus, unary()) : power();

  Node power() {
    final base = postfix();
    return eat(Op.pow) ? Bin(Op.pow, base, unary()) : base;
  }

  Node postfix() {
    var n = prefix();
    while (eat(Op.fact)) {
      n = Un(Op.fact, n);
    }
    return n;
  }

  Node prefix() {
    if (eat(Op.sqrt)) return Un(Op.sqrt, prefix());
    if (eat(Op.cbrt)) return Un(Op.cbrt, prefix());
    return primary();
  }

  Node primary() {
    final t = peek;
    if (t == null) throw const EmplakeError(ErrorCode.incomplete);
    i++;
    if (t is String) return Num(t);
    final close = _closers[t];
    if (close == null) throw EmplakeError(ErrorCode.unexpected, _sym(t));
    final inner = expr();
    if (eat(close)) return Un(t as Op, inner);
    throw peek == null
        ? EmplakeError(ErrorCode.unclosed, close.symbol)
        : EmplakeError(ErrorCode.unexpected, _sym(peek!));
  }
}

double _snap(double x) {
  final r = x.roundToDouble();
  return same(x, r) ? r : x;
}

double eval(Node n, Level level) => switch (n) {
  Num(:final digits) => _finish(double.parse(digits)),
  Un(:final op, :final child) => applyUnary(op, eval(child, level)),
  Bin(:final op, :final left, :final right) =>
    applyBinary(op, eval(left, level), eval(right, level), level),
};

/// One operator applied to evaluated operands. Public so tool/solve.dart
/// searches for solutions with exactly the rules the game enforces.
double applyUnary(Op op, double x) => _finish(switch (op) {
  Op.minus => -x,
  Op.lparen => x,
  Op.abs => x.abs(),
  Op.floorL => x.floorToDouble(),
  Op.ceilL => x.ceilToDouble(),
  Op.sqrt => _sqrt(x),
  Op.cbrt => _cbrt(x),
  Op.fact => _fact(x),
  _ => throw StateError('not a unary operator: $op'),
});

double applyBinary(Op op, double a, double b, Level level) => _finish(switch (op) {
  Op.plus => a + b,
  Op.minus => a - b,
  Op.times => a * b,
  Op.divide => _div(a, b, level),
  Op.pow => math.pow(a, b).toDouble(),
  _ => throw StateError('not a binary operator: $op'),
});

double _finish(double v) {
  if (v.isNaN) throw const EmplakeError(ErrorCode.power);
  // Past 2^53 a double cannot tell n from n − 3, so equality would be a guess.
  if (v.abs() > maxExact) throw const EmplakeError(ErrorCode.tooBig);
  return _snap(v);
}

double _sqrt(double x) =>
    x < 0 ? throw const EmplakeError(ErrorCode.sqrtNegative) : math.sqrt(x);

double _cbrt(double x) => x.sign * math.pow(x.abs(), 1 / 3).toDouble();

double _fact(double x) {
  if (x != x.roundToDouble() || x < 0 || x > 18) {
    throw const EmplakeError(ErrorCode.factorial);
  }
  var r = 1.0;
  for (var k = 2; k <= x; k++) {
    r *= k;
  }
  return r;
}

double _div(double a, double b, Level level) {
  if (b == 0) throw const EmplakeError(ErrorCode.divZero);
  final q = a / b;
  if (level != Level.easy && _snap(q) != q.roundToDouble()) {
    throw const EmplakeError(ErrorCode.nonInteger);
  }
  return q;
}

Node _strip(Node n) => n is Un && n.op == Op.lparen ? n.child : n;

String tex(Node n) => switch (n) {
  Num(:final digits) => digits,
  Un(op: Op.lparen, :final child) => '\\left(${tex(child)}\\right)',
  Un(op: Op.minus, :final child) => '-${tex(child)}',
  Un(op: Op.abs, :final child) => '\\left|${tex(child)}\\right|',
  Un(op: Op.floorL, :final child) => '\\left\\lfloor ${tex(child)}\\right\\rfloor',
  Un(op: Op.ceilL, :final child) => '\\left\\lceil ${tex(child)}\\right\\rceil',
  Un(op: Op.sqrt, :final child) => '\\sqrt{${tex(_strip(child))}}',
  Un(op: Op.cbrt, :final child) => '\\sqrt[3]{${tex(_strip(child))}}',
  Un(op: Op.fact, :final child) when child is Un && child.op == Op.fact =>
    '\\left(${tex(child)}\\right)!',
  Un(op: Op.fact, :final child) => '${tex(child)}!',
  Bin(op: Op.pow, :final left, :final right) => '{${tex(left)}}^{${tex(_strip(right))}}',
  Bin(op: Op.divide, :final left, :final right) =>
    '\\frac{${tex(_strip(left))}}{${tex(_strip(right))}}',
  Bin(:final op, :final left, :final right) => '${tex(left)} ${op.rawTex} ${tex(right)}',
  Un() => throw StateError('unknown operator ${n.op}'),
};
