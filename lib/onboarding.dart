import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';

typedef TourText = String Function(AppLocalizations l);

/// One stop of the guided tour: the widget to point at and what to say about it.
class TourStep {
  const TourStep(this.target, this.title, this.body);
  final GlobalKey target;
  final TourText title, body;
}

/// The bottom navigation bar lives outside the game page, so its key is shared.
final navBarKey = GlobalKey(debugLabel: 'navBar');

/// Bumped to ask the game page to run the tour again (from the help dialog).
final tourRequestProvider = NotifierProvider<TourRequest, int>(TourRequest.new);

class TourRequest extends Notifier<int> {
  @override
  int build() => 0;

  void ask() => state++;
}

/// Dims the screen, cuts a hole around each step's widget in turn and explains
/// it in a card. Completes when the user finishes or skips the tour.
Future<void> showTour(BuildContext context, List<TourStep> steps) =>
    Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, animation, _) => FadeTransition(opacity: animation, child: _Tour(steps)),
      ),
    );

class _Tour extends StatefulWidget {
  const _Tour(this.steps);
  final List<TourStep> steps;

  @override
  State<_Tour> createState() => _TourState();
}

class _TourState extends State<_Tour> with WidgetsBindingObserver {
  static const _move = Duration(milliseconds: 250);

  var _i = 0;
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(1));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The window was resized or rotated: the target has moved.
  @override
  void didChangeMetrics() => WidgetsBinding.instance.addPostFrameCallback((_) => _locate(1));

  void _go(int delta) {
    final next = _i + delta;
    if (next < 0) return;
    if (next >= widget.steps.length) return Navigator.of(context).pop();
    setState(() => _i = next);
    _locate(delta);
  }

  /// Scrolls the current target into view and measures it. A target that is
  /// not on screen is skipped in the direction the user was going.
  Future<void> _locate(int direction) async {
    if (!mounted) return;
    final target = widget.steps[_i].target.currentContext;
    if (target == null) return _go(direction);
    await Scrollable.ensureVisible(target, alignment: 0.5, duration: _move, curve: Curves.easeInOut);
    if (!mounted || !target.mounted) return;
    final box = target.findRenderObject()! as RenderBox;
    setState(() => _hole = (box.localToGlobal(Offset.zero) & box.size).inflate(6));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final hole = _hole;
    final step = widget.steps[_i];
    final last = _i == widget.steps.length - 1;

    final card = Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.tourStep(_i + 1, widget.steps.length), style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(step.title(l), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(step.body(l)),
          const SizedBox(height: 10),
          // A Wrap, so the buttons stack on narrow screens or with large fonts.
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.tourSkip)),
                if (_i > 0) TextButton(onPressed: () => _go(-1), child: Text(l.tourBack)),
                FilledButton(onPressed: () => _go(1), child: Text(last ? l.tourDone : l.tourNext)),
              ],
            ),
          ),
        ]),
      ),
    );

    Widget placed(Rect hole) {
      final width = math.min(380.0, size.width - 32);
      final left = (hole.center.dx - width / 2).clamp(16.0, size.width - 16 - width);
      final below = hole.center.dy < size.height / 2;
      final room = below ? size.height - hole.bottom - 24 : hole.top - 24;
      final box = Semantics(
        container: true,
        liveRegion: true,
        child: AnimatedSwitcher(duration: _move, child: KeyedSubtree(key: ValueKey(_i), child: card)),
      );
      // Not enough room beside the target: rest on the bottom edge instead.
      if (room < 190) {
        return Positioned(
          left: left,
          width: width,
          bottom: 16,
          child: ConstrainedBox(constraints: BoxConstraints(maxHeight: size.height * 0.5), child: box),
        );
      }
      return Positioned(
        left: left,
        width: width,
        top: below ? hole.bottom + 12 : null,
        bottom: below ? null : size.height - hole.top + 12,
        child: ConstrainedBox(constraints: BoxConstraints(maxHeight: room), child: box),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        // Swallows taps so the game underneath cannot be touched during the tour.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: hole == null
                ? CustomPaint(painter: _Scrim(null, theme.colorScheme.primary))
                : TweenAnimationBuilder<Rect?>(
                    tween: RectTween(begin: hole, end: hole),
                    duration: _move,
                    curve: Curves.easeInOut,
                    builder: (_, rect, _) => CustomPaint(painter: _Scrim(rect, theme.colorScheme.primary)),
                  ),
          ),
        ),
        if (hole != null) placed(hole),
      ]),
    );
  }
}

class _Scrim extends CustomPainter {
  _Scrim(this.hole, this.ring);
  final Rect? hole;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.72);
    final hole = this.hole;
    if (hole == null) return canvas.drawRect(Offset.zero & size, dim);
    final cut = RRect.fromRectAndRadius(hole, const Radius.circular(14));
    // Even-odd fill leaves the inner shape unpainted: the hole over the target.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(cut),
      dim,
    );
    canvas.drawRRect(
      cut,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_Scrim old) => old.hole != hole || old.ring != ring;
}
