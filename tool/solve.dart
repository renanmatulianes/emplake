// Finds which plates have no solution at each level and writes
// lib/unsolvable.dart, so the game never deals an impossible plate.
//
//   dart run tool/solve.dart
//
// Every solution found is rebuilt as key presses and checked by the game's own
// engine, so a plate is only kept when it can really be typed and verified.
// At Hard the search is exhaustive. At the other levels roots and factorials
// can be nested forever, so the search stops at a fixed depth: a plate listed
// there might have a far-fetched solution, but it is left out to be safe.
import 'dart:io';

import 'package:emplake/math_engine.dart';

class Val {
  const Val(this.v, this.n);
  final double v;
  final Node n;
}

typedef Vals = Map<double, Val>;

double keyOf(double v) =>
    v == 0 ? 0 : (v == v.roundToDouble() ? v : (v * 1e7).roundToDouble() / 1e7);

class Solver {
  Solver(this.level, this.depth)
    : unary = [
        Op.minus,
        for (final o in [Op.sqrt, Op.cbrt, Op.fact, Op.floorL, Op.ceilL])
          if (level.ops.contains(o)) o,
      ],
      binary = [
        for (final o in [Op.plus, Op.minus, Op.times, Op.divide, Op.pow])
          if (level.ops.contains(o)) o,
      ];

  final Level level;

  /// How many unary operators may be stacked on a value built from 1, 2 or 3 digits.
  final List<int> depth;
  final List<Op> unary, binary;
  final _memo = <String, Vals>{};

  double? _un(Op op, double x) {
    switch (op) {
      case Op.minus:
        if (x == 0) return null;
      case Op.sqrt:
        if (x <= 0 || x == 1) return null;
      case Op.cbrt:
        if (x == 0 || x.abs() == 1) return null;
      case Op.fact:
        if (x != x.roundToDouble() || x < 0 || x > 18 || x == 1 || x == 2) return null;
      case Op.floorL || Op.ceilL:
        if (x == x.roundToDouble()) return null;
      default:
    }
    try {
      return applyUnary(op, x);
    } on EmplakeError {
      return null;
    }
  }

  double? _bin(Op op, double a, double b) {
    if (op == Op.divide) {
      if (b == 0) return null;
      final q = a / b;
      if (level != Level.easy && (q - q.roundToDouble()).abs() > 1e-6) return null;
    }
    if (op == Op.pow && (b.abs() > 64 || (a == 0 && b < 0))) return null;
    try {
      return applyBinary(op, a, b, level);
    } on EmplakeError {
      return null;
    }
  }

  void _close(Vals m, int depth) {
    var frontier = m.values.toList();
    for (var d = 0; d < depth && frontier.isNotEmpty; d++) {
      final next = <Val>[];
      for (final x in frontier) {
        for (final op in unary) {
          final v = _un(op, x.v);
          if (v == null) continue;
          final k = keyOf(v);
          if (m.containsKey(k)) continue;
          next.add(m[k] = Val(v, Un(op, x.n)));
        }
      }
      frontier = next;
    }
  }

  /// Every value the digits [s] can make, in order, with one expression for each.
  Vals values(String s, {bool memo = true}) {
    final hit = _memo[s];
    if (hit != null) return hit;
    final m = <double, Val>{keyOf(double.parse(s)): Val(double.parse(s), Num(s))};
    for (var k = 1; k < s.length; k++) {
      final left = values(s.substring(0, k)), right = values(s.substring(k));
      for (final a in left.values) {
        for (final b in right.values) {
          for (final op in binary) {
            final v = _bin(op, a.v, b.v);
            if (v == null) continue;
            m.putIfAbsent(keyOf(v), () => Val(v, Bin(op, a.n, b.n)));
          }
        }
      }
    }
    _close(m, depth[s.length - 1]);
    if (memo) _memo[s] = m;
    return m;
  }
}

/// Tokens of [n], with every operand that is not a plain number in parentheses.
void emit(Node n, List<Object> out) {
  void atom(Node c) {
    if (c is Num) return emit(c, out);
    out.add(Op.lparen);
    emit(c, out);
    out.add(Op.rparen);
  }

  switch (n) {
    case Num(:final digits):
      out.addAll(digits.split(''));
    case Un(op: Op.fact, :final child):
      atom(child);
      out.add(Op.fact);
    case Un(op: Op.floorL, :final child):
      out.add(Op.floorL);
      emit(child, out);
      out.add(Op.floorR);
    case Un(op: Op.ceilL, :final child):
      out.add(Op.ceilL);
      emit(child, out);
      out.add(Op.ceilR);
    case Un(:final op, :final child):
      out.add(op);
      atom(child);
    case Bin(:final op, :final left, :final right):
      atom(left);
      out.add(op);
      atom(right);
  }
}

List<List<Op>> gapsOf(Node left, Node right) {
  final toks = <Object>[];
  emit(left, toks);
  toks.add(Op.equals);
  emit(right, toks);
  final gaps = List.generate(5, (_) => <Op>[]);
  var digit = 0;
  for (final t in toks) {
    t is Op ? gaps[digit].add(t) : digit++;
  }
  return gaps;
}

/// Types [target] the way a player would: slot by slot, left to right.
bool typeable(String digits, List<List<Op>> target) {
  final eq = target.indexWhere((g) => g.contains(Op.equals));
  List<List<Op>>? gaps = List.generate(5, (g) => g == eq ? [Op.equals] : <Op>[]);
  for (var g = 0; g < 5; g++) {
    for (final op in target[g]) {
      if (op == Op.equals) continue;
      gaps = place(digits, gaps!, g, op);
      if (gaps == null) return false;
    }
  }
  return '$gaps' == '$target';
}

var rejectedWitnesses = 0;

bool solves(String digits, Level level, Vals a, Vals b) {
  final (small, big) = a.length <= b.length ? (a, b) : (b, a);
  var tries = 0;
  for (final k in small.keys) {
    if (!big.containsKey(k)) continue;
    final gaps = gapsOf(a[k]!.n, b[k]!.n);
    if (check(digits, gaps, level).solved && typeable(digits, gaps)) return true;
    rejectedWitnesses++;
    if (++tries > 40) break;
  }
  return false;
}

void main() {
  final all = [for (var i = 0; i < 10000; i++) i.toString().padLeft(4, '0')];
  final result = <Level, List<String>>{};
  for (final level in Level.values) {
    final sw = Stopwatch()..start();
    var open = all.toSet();
    final tiers = level == Level.hard
        ? [
            [1, 1, 1],
          ]
        : [
            [1, 1, 1],
            [2, 1, 1],
            [2, 2, 1],
            [3, 2, 2],
            [3, 3, 2],
            [4, 3, 3],
          ];
    for (final tier in tiers) {
      if (open.isEmpty) break;
      final s = Solver(level, tier);
      // "ab = cd"
      open.removeWhere((p) => solves(p, level, s.values(p.substring(0, 2)), s.values(p.substring(2))));
      // "a = bcd" and "abc = d"
      for (var t = 0; t < 1000 && open.isNotEmpty; t++) {
        final three = t.toString().padLeft(3, '0');
        final plates = [
          for (var d = 0; d < 10; d++) ...['$d$three', '$three$d'],
        ].where(open.contains).toList();
        if (plates.isEmpty) continue;
        final big = s.values(three, memo: false);
        for (final p in plates) {
          final ok = p.endsWith(three) && solves(p, level, s.values(p[0]), big) ||
              p.startsWith(three) && solves(p, level, big, s.values(p[3]));
          if (ok) open.remove(p);
        }
      }
      stdout.writeln('${level.name} depth $tier: ${open.length} without solution '
          '(${sw.elapsed.inSeconds}s)');
    }
    result[level] = open.toList()..sort();
  }
  stdout.writeln('witnesses rejected by the engine: $rejectedWitnesses');

  final out = StringBuffer()
    ..writeln('// GENERATED by tool/solve.dart. Do not edit by hand.')
    ..writeln("import 'math_engine.dart';")
    ..writeln()
    ..writeln('/// Plates with no known solution at each level; the game never deals them.')
    ..writeln('final Map<Level, Set<String>> unsolvable = {')
    ..writeln('  for (final e in _data.entries) e.key: {...e.value.split(\' \').where((p) => p.isNotEmpty)},')
    ..writeln('};')
    ..writeln()
    ..writeln('const _data = {');
  for (final e in result.entries) {
    out.writeln("  Level.${e.key.name}: '${e.value.join(' ')}',");
  }
  out.writeln('};');
  File('lib/unsolvable.dart').writeAsStringSync(out.toString());
  stdout.writeln('wrote lib/unsolvable.dart');
}
