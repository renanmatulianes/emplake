import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'calculator.dart';
import 'l10n/app_localizations.dart';
import 'math_engine.dart';
import 'onboarding.dart';
import 'repository.dart';
import 'settings.dart';
import 'sound.dart';
import 'unsolvable.dart';

class GameState {
  const GameState({
    required this.level,
    required this.gaps,
    this.number,
    this.cursor = 0,
    this.at = 0,
    this.score = 0,
    this.shake = 0,
    this.busy = false,
    this.exhausted = false,
    this.verdict,
    this.saveError,
    this.rejected,
  });

  final Level level;
  final String? number;
  final List<List<Op>> gaps; // 5 slots around the 4 digits

  /// The cursor: slot [cursor], and [at] = index inside it where the next
  /// symbol is typed (0 = before its first symbol).
  final int cursor, at;
  final int score, shake;
  final bool busy, exhausted;
  final Check? verdict;
  final CloudError? saveError;
  final Op? rejected;

  /// Index right after the last symbol of one side of [slot]: before its "="
  /// or, with [after] (and in slots without "="), at its very end.
  static int endOf(List<Op> slot, bool after) {
    final eq = slot.indexOf(Op.equals);
    return eq < 0 || after ? slot.length : eq;
  }

  /// In the slot that holds "=", whether the cursor is after it (else before).
  bool get after {
    final eq = gaps[cursor].indexOf(Op.equals);
    return eq >= 0 && at > eq;
  }

  /// Whether the cursor is at the end of its side (where a "_" is drawn)
  /// rather than between two symbols.
  bool get atEnd => at == endOf(gaps[cursor], after);

  /// Every place a symbol can be typed, left to right: before, between and
  /// after the symbols of each slot.
  List<(int, int)> get positions => [
    for (var g = 0; g < gaps.length; g++)
      for (var k = 0; k <= gaps[g].length; k++) (g, k),
  ];

  /// Whether some operator of the level still fits at the end of a side.
  bool canExtend(int g, bool after) {
    final side = gaps[g].contains(Op.equals) ? after : null;
    return level.ops.any((op) => place(number ?? '0000', gaps, g, op, afterEq: side) != null);
  }

  /// [verdict], [saveError] and [rejected] are cleared unless passed again.
  GameState copyWith({
    Level? level, String? number, List<List<Op>>? gaps, int? cursor, int? at, int? score, int? shake, //
    bool? busy, bool? exhausted, Check? verdict, CloudError? saveError, Op? rejected,
  }) => GameState(
    level: level ?? this.level,
    number: number ?? this.number,
    gaps: gaps ?? this.gaps,
    cursor: cursor ?? this.cursor,
    at: at ?? this.at,
    score: score ?? this.score,
    shake: shake ?? this.shake,
    busy: busy ?? this.busy,
    exhausted: exhausted ?? this.exhausted,
    verdict: verdict,
    saveError: saveError,
    rejected: rejected,
  );
}

final gameProvider = NotifierProvider<GameController, GameState>(GameController.new);

class GameController extends Notifier<GameState> {
  final _rng = math.Random();

  Repo get _repo => ref.read(repoProvider);

  static List<List<Op>> _fresh([int eq = 2]) =>
      List.generate(5, (g) => g == eq ? [Op.equals] : <Op>[]);

  List<List<Op>> _copy() => [for (final g in state.gaps) [...g]];

  @override
  GameState build() {
    ref.watch(repoProvider);
    final p = ref.read(prefsProvider);
    final saved = p.getString('number');
    return GameState(
      level: Level.values.asNameMap()[p.getString('level')] ?? Level.easy,
      number: saved != null && RegExp(r'^\d{4}$').hasMatch(saved) ? saved : null,
      gaps: _fresh(),
    );
  }

  // Whether a slot is the one holding "=", which has two sides to type in.
  static bool _hasEq(List<Op> slot) => slot.contains(Op.equals);

  bool _playable(Level l, String n) =>
      !(_repo.current?.isSolved(l, n) ?? false) && !unsolvable[l]!.contains(n);

  void attach(Profile p) {
    state = state.copyWith(score: p.score);
    final n = state.number;
    if (n == null || !_playable(state.level, n)) _next();
  }

  /// Picks a random plate that has a solution and that the user has not solved
  /// at the current level.
  void _next({String? exclude, Check? verdict}) {
    final free = [
      for (var i = 0; i < 10000; i++) i.toString().padLeft(4, '0'),
    ].where((n) => _playable(state.level, n)).toList();
    if (free.isEmpty) {
      state = state.copyWith(exhausted: true, gaps: _fresh(), at: 0);
      return;
    }
    // Skipping the only number left just shows it again.
    if (free.length > 1) free.remove(exclude);
    final n = free[_rng.nextInt(free.length)];
    ref.read(prefsProvider).setString('number', n);
    state = state.copyWith(
      number: n, gaps: _fresh(), cursor: 0, at: 0, exhausted: false, verdict: verdict, //
    );
  }

  void setLevel(Level l) {
    ref.read(prefsProvider).setString('level', l.name);
    state = state.copyWith(level: l, gaps: _fresh(), at: 0, exhausted: false);
    final n = state.number;
    if (n == null || !_playable(l, n)) _next();
  }

  /// Puts the cursor at the end of a slot; [after] picks the side of "=" in
  /// the slot that holds it.
  void select(int g, {bool after = false}) {
    final slot = g.clamp(0, 4);
    state = state.copyWith(cursor: slot, at: GameState.endOf(state.gaps[slot], after));
  }

  /// Puts the cursor before symbol [k] of slot [g], to type between symbols.
  void selectAt(int g, int k) {
    final slot = g.clamp(0, 4);
    state = state.copyWith(cursor: slot, at: k.clamp(0, state.gaps[slot].length));
  }

  /// Moves the cursor through every place a symbol can go, left to right.
  void step(int delta) {
    final all = state.positions;
    final here = all.indexOf((state.cursor, state.at));
    final (g, k) = all[((here < 0 ? 0 : here) + delta).clamp(0, all.length - 1)];
    selectAt(g, k);
  }

  /// False (and a shake) when [op] cannot stand where the cursor is.
  ///
  /// Between two symbols it goes exactly there. At the end of a side the slot
  /// may reorder it (")" lands before "+"), and next to "=" a symbol that only
  /// fits on the other side goes there. The cursor ends up right after it.
  bool insert(Op op) {
    final n = state.number ?? '0000';
    final g = state.cursor;
    List<List<Op>>? gaps;
    var at = 0;
    if (op == Op.equals) {
      gaps = place(n, state.gaps, g, op);
      at = gaps?[g].indexOf(Op.equals) ?? 0;
    } else if (!state.atEnd) {
      gaps = place(n, state.gaps, g, op, exact: state.at);
      at = state.at + 1;
    } else {
      final split = _hasEq(state.gaps[g]);
      var after = split && state.after;
      gaps = place(n, state.gaps, g, op, afterEq: split ? after : null);
      if (gaps == null && split) {
        after = !after;
        gaps = place(n, state.gaps, g, op, afterEq: after);
      }
      if (gaps != null) at = GameState.endOf(gaps[g], after);
    }
    state = gaps == null
        ? state.copyWith(rejected: op, shake: state.shake + 1)
        : state.copyWith(gaps: gaps, at: at);
    return gaps != null;
  }

  /// Removes the symbol right before the cursor. The "=" is never removed,
  /// only moved.
  void backspace() {
    final gaps = _copy();
    final slot = gaps[state.cursor];
    final i = state.at - 1;
    if (i < 0 || i >= slot.length || slot[i] == Op.equals) return;
    slot.removeAt(i);
    state = state.copyWith(gaps: gaps, at: i);
  }

  void clear() => state = state.copyWith(
    gaps: _fresh(state.gaps.indexWhere((g) => g.contains(Op.equals))),
    at: 0,
  );

  void skip() => _next(exclude: state.number);

  /// True when the equation is correct and saved to Firestore.
  Future<bool> verify() async {
    final n = state.number;
    if (n == null || state.busy || state.exhausted) return false;
    final c = check(n, state.gaps, state.level);
    if (!c.solved) {
      state = state.copyWith(verdict: c, shake: state.shake + 1);
      return false;
    }
    state = state.copyWith(busy: true, verdict: c);
    try {
      await _repo.markSolved(state.level, n, c.latex);
    } catch (e) {
      if (ref.mounted) state = state.copyWith(busy: false, saveError: cloudError(e));
      return false;
    }
    if (!ref.mounted) return false;
    state = state.copyWith(busy: false, verdict: c, score: _repo.current?.score);
    return true;
  }

  void nextAfterSolve() => _next(verdict: state.verdict);
}

String levelName(AppLocalizations l, Level v) => switch (v) {
  Level.easy => l.levelEasy,
  Level.intermediate => l.levelIntermediate,
  Level.advanced => l.levelAdvanced,
  Level.hard => l.levelHard,
};

String opName(AppLocalizations l, Op o) => switch (o) {
  Op.plus => l.opPlus,
  Op.minus => l.opMinus,
  Op.times => l.opTimes,
  Op.divide => l.opDivide,
  Op.lparen => l.opLParen,
  Op.rparen => l.opRParen,
  Op.sqrt => l.opSqrt,
  Op.cbrt => l.opCbrt,
  Op.fact => l.opFact,
  Op.pow => l.opPow,
  Op.abs => l.opAbs,
  Op.floorL => l.opFloorL,
  Op.floorR => l.opFloorR,
  Op.ceilL => l.opCeilL,
  Op.ceilR => l.opCeilR,
  Op.equals => l.opEquals,
};

String errorText(AppLocalizations l, EmplakeError e) => switch (e.code) {
  ErrorCode.unexpected => l.errUnexpected(e.token),
  ErrorCode.incomplete => l.errIncomplete,
  ErrorCode.unclosed => l.errUnclosed(e.token),
  ErrorCode.equals => l.errEquals,
  ErrorCode.emptySide => l.errEmptySide,
  ErrorCode.divZero => l.errDivZero,
  ErrorCode.nonInteger => l.errNonInteger,
  ErrorCode.factorial => l.errFactorial,
  ErrorCode.sqrtNegative => l.errSqrtNegative,
  ErrorCode.power => l.errPower,
  ErrorCode.tooBig => l.errTooBig,
  ErrorCode.notAllowed => l.errNotAllowed(e.token),
};

String cloudErrorText(AppLocalizations l, CloudError e) => switch (e) {
  CloudError.offline => l.cloudOffline,
  CloudError.denied => l.cloudDenied,
  CloudError.unknown => l.cloudUnknown,
};

String fmt(AppLocalizations l, double v) =>
    v.abs() >= 1e12 ? v.toStringAsExponential(4) : NumberFormat('0.######', l.localeName).format(v);

class Loading extends StatelessWidget {
  const Loading({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      LoadingAnimationWidget.fourRotatingDots(color: Theme.of(context).colorScheme.primary, size: 56),
      const SizedBox(height: 16),
      Text(text),
    ]),
  );
}

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  late Future<Profile> _future = _attach(ref.read(repoProvider).profile());

  Future<Profile> _attach(Future<Profile> f) => f.then((p) {
    ref.read(gameProvider.notifier).attach(p);
    return p;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<Profile>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 12),
                Text(l.loadError(cloudErrorText(l, cloudError(snap.error))), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() => _future = _attach(ref.read(repoProvider).reload())),
                  child: Text(l.retry),
                ),
              ]),
            ),
          );
        }
        if (!snap.hasData) return Loading(text: l.loading);
        return const _Board();
      },
    );
  }
}

// How many "show the tour" requests have been served; see [tourRequestProvider].
int _tourRequestsHandled = 0;

/// The game screen, drawn as a retro LCD calculator with a receipt printer.
class _Board extends ConsumerStatefulWidget {
  const _Board();

  @override
  ConsumerState<_Board> createState() => _BoardState();
}

class _BoardState extends ConsumerState<_Board> {
  final _tokenKeys = <String, GlobalKey>{};
  final _keypadKeys = {for (final o in Op.values) o: GlobalKey()};

  /// True while "=" is picked up: the next "_" tapped receives it.
  bool _movingEq = false;

  /// True for a moment after a correct answer, while the solved equation stays
  /// on the display so the player sees that it was right.
  bool _celebrating = false;

  // Parts of the screen the guided tour points at.
  final _lcdKey = GlobalKey(), _equationKey = GlobalKey(), _equalsKey = GlobalKey();
  final _receiptKey = GlobalKey(), _levelKey = GlobalKey(), _opsKey = GlobalKey();
  final _editKey = GlobalKey(), _skipKey = GlobalKey(), _verifyKey = GlobalKey();
  bool _touring = false;

  /// Remembered per account on this device, so each player sees the tour once.
  String get _tourPref => 'tourSeen:${ref.read(repoProvider).uid}';

  @override
  void initState() {
    super.initState();
    final seen = ref.read(prefsProvider).getBool(_tourPref) ?? false;
    // Also runs when it was asked for (help dialog) before this page existed.
    if (!seen || ref.read(tourRequestProvider) > _tourRequestsHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
    }
  }

  /// Walks a first-time player through what each part of the screen is for.
  Future<void> _startTour() async {
    if (_touring || !mounted) return;
    _touring = true;
    _tourRequestsHandled = ref.read(tourRequestProvider);
    // Lets fonts and the entrance animations settle so the highlights line up.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      if (_movingEq) setState(() => _movingEq = false);
      await showTour(context, [
        TourStep(_lcdKey, (l) => l.tourDisplayTitle, (l) => l.tourDisplayBody),
        TourStep(_equationKey, (l) => l.tourMarksTitle, (l) => l.tourMarksBody),
        TourStep(_equalsKey, (l) => l.tourEqualsTitle, (l) => l.tourEqualsBody),
        TourStep(_receiptKey, (l) => l.tourFormulaTitle, (l) => l.tourFormulaBody),
        TourStep(_levelKey, (l) => l.tourLevelTitle, (l) => l.tourLevelBody),
        TourStep(_opsKey, (l) => l.tourOperatorsTitle, (l) => l.tourOperatorsBody),
        TourStep(_editKey, (l) => l.tourEditTitle, (l) => l.tourEditBody),
        TourStep(_skipKey, (l) => l.tourSkipTitle, (l) => l.tourSkipBody),
        TourStep(_verifyKey, (l) => l.tourVerifyTitle, (l) => l.tourVerifyBody),
        TourStep(navBarKey, (l) => l.tourMenuTitle, (l) => l.tourMenuBody),
      ]);
      if (mounted) await ref.read(prefsProvider).setBool(_tourPref, true);
    }
    _touring = false;
  }

  GameController get _ctrl => ref.read(gameProvider.notifier);

  void _tap(VoidCallback f) {
    if (_movingEq) setState(() => _movingEq = false);
    playSfx(ref, Sfx.tap);
    f();
  }

  Future<void> _verify() async {
    final ok = await _ctrl.verify();
    if (!mounted) return;
    playSfx(ref, ok ? Sfx.correct : Sfx.wrong);
    if (!ok) return;
    // Hold the solved equation on the display before dealing the next plate,
    // otherwise the player cannot tell that the answer was accepted.
    setState(() => _celebrating = true);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _celebrating = false);
    _flyBack();
    _ctrl.nextAfterSolve();
  }

  void _clear() {
    _flyBack();
    _ctrl.clear();
  }

  /// Animates every placed operator (except "=") from the LCD back onto its key.
  void _flyBack() {
    final overlay = Overlay.of(context, rootOverlay: true);
    final origin = overlay.context.findRenderObject() as RenderBox;
    final style = CalcPalette.of(context).lcdText(60);
    final gaps = ref.read(gameProvider).gaps;
    for (var g = 0; g < gaps.length; g++) {
      for (var j = 0; j < gaps[g].length; j++) {
        final op = gaps[g][j];
        final from = _tokenKeys['$g:$j']?.currentContext?.findRenderObject() as RenderBox?;
        final to = _keypadKeys[op]!.currentContext?.findRenderObject() as RenderBox?;
        if (op == Op.equals || from == null || to == null) continue;
        final a = from.localToGlobal(Offset.zero, ancestor: origin);
        final b = to.localToGlobal(to.size.center(Offset.zero), ancestor: origin) -
            from.size.center(Offset.zero);
        late final OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => TweenAnimationBuilder<Offset>(
            tween: Tween(begin: a, end: b),
            duration: Duration(milliseconds: 600 + 80 * j),
            curve: Curves.easeInOutCubic,
            onEnd: () => entry.remove(),
            builder: (_, o, child) => Positioned(left: o.dx, top: o.dy, child: child!),
            child: IgnorePointer(
              child: Material(type: MaterialType.transparency, child: Text(op.symbol, style: style)),
            ),
          ),
        );
        overlay.insert(entry);
      }
    }
  }

  /// Moves "=" to slot [g]; used by dragging it or by tapping it and then a "_".
  void _dropEquals(int g) {
    setState(() => _movingEq = false);
    _ctrl.select(g);
    playSfx(ref, _ctrl.insert(Op.equals) ? Sfx.tap : Sfx.wrong);
  }

  /// One slot between digits: its symbols, plus a "_" wherever another symbol
  /// can still be typed. The slot holding "=" has one "_" on each side of it.
  /// Tapping a symbol moves the cursor next to it, to type between symbols.
  Widget _slot(int g, GameState s, CalcPalette p) {
    final l = AppLocalizations.of(context);
    final ops = s.gaps[g];
    final eq = ops.indexOf(Op.equals);
    final locked = s.busy || s.exhausted || _celebrating;
    // Index where the cursor stands between two symbols of this slot, if it does.
    final caret = g == s.cursor && !s.atEnd ? s.at : -1;

    Widget token(int j) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 84,
        child: Center(
          widthFactor: 1,
          child: _PopIn(
            key: _tokenKeys.putIfAbsent('$g:$j', GlobalKey.new),
            child: Text(ops[j].symbol, style: p.lcdText(60)),
          ),
        ),
      ),
    );

    Widget mark({required bool lit, required bool blink, double width = 26}) {
      final bar = Container(
        height: 4,
        width: width,
        color: lit ? p.ink : p.ink.withValues(alpha: _movingEq ? 0.6 : 0.3),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: 90, width: width),
          blink ? Blink(child: bar) : bar,
        ]),
      );
    }

    // A placed symbol: tapping its left or right half puts the cursor there.
    Widget symbol(int j) => Builder(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: locked
            ? null
            : (d) {
                if (_movingEq) return _dropEquals(g);
                final right = d.localPosition.dx > context.size!.width / 2;
                _tap(() => _ctrl.selectAt(g, right ? j + 1 : j));
              },
        child: token(j),
      ),
    );

    // The "=" on the display: drag it to a "_", or tap it and then tap a "_".
    Widget equalsSign() {
      final sign = _movingEq ? Blink(child: token(eq)) : token(eq);
      if (locked) return sign;
      return Tooltip(
        message: l.equalsTip,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Draggable<Op>(
            data: Op.equals,
            axis: Axis.horizontal,
            onDragStarted: () => setState(() => _movingEq = true),
            onDragEnd: (_) => setState(() => _movingEq = false),
            feedback: Material(
              type: MaterialType.transparency,
              child: Text(Op.equals.symbol, style: p.lcdText(60)),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: token(eq)),
            child: Semantics(
              button: true,
              label: l.equalsTip,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  playSfx(ref, Sfx.tap);
                  setState(() => _movingEq = !_movingEq);
                },
                child: sign,
              ),
            ),
          ),
        ),
      );
    }

    // Symbols [from, to) and the "_" that follows them.
    Widget side(int from, int to, bool after) {
      final selected = g == s.cursor && s.at == to;
      final open = selected || from == to || _movingEq || s.canExtend(g, after);
      return DragTarget<Op>(
        onAcceptWithDetails: (_) => _dropEquals(g),
        builder: (context, incoming, _) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var j = from; j < to; j++) ...[
            if (j == caret) mark(lit: true, blink: true, width: 14),
            symbol(j),
          ],
          if (open)
            Semantics(
              button: true,
              selected: selected,
              label: l.slotLabel(s.positions.indexOf((g, to)) + 1),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: locked
                    ? null
                    : () => _movingEq ? _dropEquals(g) : _tap(() => _ctrl.select(g, after: after)),
                child: mark(
                  lit: selected || incoming.isNotEmpty,
                  blink: selected && !_movingEq && !locked,
                ),
              ),
            ),
        ]),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (eq < 0)
        side(0, ops.length, false)
      else ...[
        side(0, eq, false),
        KeyedSubtree(key: _equalsKey, child: equalsSign()),
        side(eq + 1, ops.length, true),
      ],
    ]);
  }

  /// Bottom LCD line: the most relevant message for the current state.
  ({String text, bool alert}) _message(AppLocalizations l, GameState s, Check live) {
    if (s.exhausted) return (text: l.allSolved, alert: false);
    if (_celebrating) return (text: l.correct(s.level.points), alert: true);
    if (_movingEq) return (text: l.moveEqualsHint, alert: false);
    if (s.saveError != null) return (text: l.saveError(cloudErrorText(l, s.saveError!)), alert: true);
    if (s.rejected case final op?) return (text: l.cantPlace(op.symbol), alert: true);
    if (s.verdict case final v?) {
      if (v.solved) return (text: l.correct(s.level.points), alert: false);
      return (text: v.error != null ? errorText(l, v.error!) : l.wrong(fmt(l, v.left!), fmt(l, v.right!)), alert: true);
    }
    if (live.left != null && live.right != null) {
      return (text: l.sides(fmt(l, live.left!), fmt(l, live.right!)), alert: false);
    }
    return (text: l.selectSlotHint, alert: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(gameProvider);
    ref.listen(tourRequestProvider, (_, _) => _startTour());
    final cs = Theme.of(context).colorScheme;
    final p = CalcPalette.of(context);
    final number = s.number ?? '0000';
    final live = check(number, s.gaps, s.level);
    final locked = s.busy || s.exhausted || _celebrating;
    final msg = _message(l, s, live);
    final engraving = Color.lerp(p.body, p.dark ? Colors.white : Colors.black, 0.45)!;

    final brand = Row(children: [
      Container(
        width: 112,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: p.bezel, borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          for (var i = 0; i < 4; i++)
            Expanded(child: Container(margin: const EdgeInsets.all(1), color: const Color(0xFF3D2F36))),
        ]),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l.appTitle.toUpperCase(),
              style: TextStyle(color: engraving, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18),
            ),
          ),
        ),
      ),
    ]);

    final lcd = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: p.bezel, borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(color: p.lcd, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(levelName(l, s.level).toUpperCase(), style: p.lcdText(20)),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l.score(s.score).toUpperCase(), style: p.lcdText(20)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _Flash(
            key: _equationKey,
            active: _celebrating,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var g = 0; g < 5; g++) ...[
                  _slot(g, s, p),
                  if (g < 4)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SevenSegment(number[g], color: p.ink, glow: p.dark),
                    ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            // Two lines are always reserved so the keys below never jump.
            child: Stack(alignment: Alignment.center, children: [
              ExcludeSemantics(
                child: Opacity(
                  opacity: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('\n', style: p.lcdText(20)),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                width: msg.alert ? double.infinity : null,
                color: msg.alert ? p.ink : Colors.transparent,
                child: Text(
                  msg.text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: p.lcdText(20).copyWith(color: msg.alert ? p.lcd : null, shadows: msg.alert ? const [] : null),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );

    final receipt = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(height: 8, decoration: BoxDecoration(color: p.bezel, borderRadius: BorderRadius.circular(4))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (c, a) => SizeTransition(sizeFactor: a, alignment: Alignment.topCenter, child: c),
            child: KeyedSubtree(
              key: ValueKey(number),
              child: Receipt(
                title: l.preview,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(
                      live.latex,
                      textStyle: const TextStyle(fontSize: 28, color: Colors.black87),
                      onErrorFallback: (_) => Text(live.latex, style: const TextStyle(color: Colors.black87)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );

    Widget opKey(Op op) => CalcKey(
      key: _keypadKeys[op],
      tooltip: opName(l, op),
      color: op == Op.equals ? cs.tertiary : p.key,
      onPressed: locked
          ? null
          : () {
              if (_movingEq) setState(() => _movingEq = false);
              playSfx(ref, _ctrl.insert(op) ? Sfx.tap : Sfx.wrong);
            },
      child: Text(op.symbol, style: const TextStyle(fontSize: 24)),
    );
    Widget label(String t) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(t.toUpperCase(), style: const TextStyle(letterSpacing: 1))),
    );
    List<Widget> grid(List<Widget> cells) => [
      for (var i = 0; i < cells.length; i += 4)
        Row(children: [
          for (var j = i; j < i + 4; j++)
            Expanded(child: Padding(padding: const EdgeInsets.all(5), child: j < cells.length ? cells[j] : null)),
        ]),
    ];

    final keys = [
      Column(key: _opsKey, mainAxisSize: MainAxisSize.min, children: grid([
        for (final op in Op.values)
          if (op == Op.equals || s.level.ops.contains(op)) opKey(op),
      ])),
      const SizedBox(height: 6),
      Column(key: _editKey, mainAxisSize: MainAxisSize.min, children: grid([
        CalcKey(
          tooltip: l.prevSlot,
          color: p.grayKey,
          onPressed: locked ? null : () => _tap(() => _ctrl.step(-1)),
          child: const Icon(Icons.chevron_left),
        ),
        CalcKey(
          tooltip: l.nextSlot,
          color: p.grayKey,
          onPressed: locked ? null : () => _tap(() => _ctrl.step(1)),
          child: const Icon(Icons.chevron_right),
        ),
        CalcKey(
          tooltip: l.undo,
          color: p.grayKey,
          onPressed: locked ? null : () => _tap(_ctrl.backspace),
          child: const Icon(Icons.backspace_outlined),
        ),
        CalcKey(color: cs.error, onPressed: locked ? null : () => _tap(_clear), child: label(l.clear)),
      ])),
      Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: CalcKey(
              key: _skipKey,
              color: cs.secondary,
              onPressed: s.busy || _celebrating ? null : () => _tap(_ctrl.skip),
              child: label(l.skip),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: CalcKey(
              key: _verifyKey,
              color: cs.primary,
              onPressed: locked ? null : _verify,
              child: s.busy
                  ? LoadingAnimationWidget.threeArchedCircle(color: cs.onPrimary, size: 24)
                  : label(l.verify),
            ),
          ),
        ),
      ]),
    ];

    final screw = Screw(color: Color.lerp(p.body, Colors.black, 0.3)!);
    final body = Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: p.body,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Color.lerp(p.body, Colors.black, 0.25)!, width: 2),
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: brand),
          const SizedBox(height: 14),
          KeyedSubtree(key: _lcdKey, child: lcd),
          KeyedSubtree(key: _receiptKey, child: receipt),
          const SizedBox(height: 8),
          ModeSwitch<Level>(
            key: _levelKey,
            values: Level.values,
            selected: s.level,
            label: (v) => levelName(l, v),
            palette: p,
            onChanged: s.busy || _celebrating ? null : (v) => _tap(() => _ctrl.setLevel(v)),
          ),
          const SizedBox(height: 8),
          ...keys,
        ]),
        Positioned(left: -12, top: -10, child: screw),
        Positioned(right: -12, top: -10, child: screw),
        Positioned(left: -12, bottom: -14, child: screw),
        Positioned(right: -12, bottom: -14, child: screw),
      ]),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 110),
      child: Center(child: _Shake(trigger: s.shake, child: body)),
    );
  }
}

class _PopIn extends StatelessWidget {
  const _PopIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutBack,
    builder: (_, v, c) => Transform.scale(scale: v, child: c),
    child: child,
  );
}

/// Shakes its child each time [trigger] increases.
class _Shake extends StatelessWidget {
  const _Shake({required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: trigger.toDouble()),
    duration: const Duration(milliseconds: 450),
    builder: (_, t, c) {
      final f = t - t.floorToDouble();
      return Transform.translate(offset: Offset(math.sin(f * math.pi * 6) * 12 * (1 - f), 0), child: c);
    },
    child: child,
  );
}

/// Makes its child pulse while [active]: the display flashing a right answer.
/// Stays still when the OS asks for reduced motion.
class _Flash extends StatefulWidget {
  const _Flash({super.key, required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  State<_Flash> createState() => _FlashState();
}

class _FlashState extends State<_Flash> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 280), value: 1);

  @override
  void didUpdateWidget(_Flash old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    if (widget.active && !MediaQuery.of(context).disableAnimations) {
      _c.repeat(reverse: true);
    } else {
      _c
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: Tween(begin: 0.3, end: 1.0).animate(_c), child: widget.child);
}
