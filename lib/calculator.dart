import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Calculator colors, tinted by the theme so the seed color and dark mode still apply.
class CalcPalette {
  const CalcPalette._({
    required this.dark,
    required this.body,
    required this.bezel,
    required this.lcd,
    required this.ink,
    required this.key,
    required this.grayKey,
  });

  final bool dark;
  final Color body, bezel, lcd, ink, key, grayKey;

  factory CalcPalette.of(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = cs.brightness == Brightness.dark;
    Color tint(Color base, double a) => Color.alphaBlend(cs.primary.withValues(alpha: a), base);
    return CalcPalette._(
      dark: dark,
      body: tint(dark ? const Color(0xFF262523) : const Color(0xFFE6DDC8), 0.08),
      bezel: dark ? const Color(0xFF111111) : const Color(0xFF4A4740),
      lcd: tint(dark ? const Color(0xFF0D150F) : const Color(0xFFA7B59A), dark ? 0.06 : 0.12),
      ink: dark ? Color.lerp(const Color(0xFF8DF08A), cs.primary, 0.3)! : const Color(0xFF1C2415),
      key: const Color(0xFF34322F),
      grayKey: const Color(0xFF77736B),
    );
  }

  TextStyle lcdText(double size) => GoogleFonts.vt323(
    fontSize: size,
    height: 1,
    color: ink,
    shadows: dark ? [Shadow(color: ink.withValues(alpha: 0.7), blurRadius: 8)] : null,
  );
}

/// One LCD digit; unlit segments stay faintly visible like on a real display.
class SevenSegment extends StatelessWidget {
  const SevenSegment(this.digit, {super.key, required this.color, this.glow = false, this.height = 84});
  final String digit;
  final Color color;
  final bool glow;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: digit,
    child: CustomPaint(
      size: Size(height * 0.64, height),
      painter: _SegmentPainter(int.parse(digit), color, glow),
    ),
  );
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter(this.digit, this.color, this.glow);
  final int digit;
  final Color color;
  final bool glow;

  // Bits for segments a b c d e f g (bit 0 = a).
  static const _map = [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F];

  @override
  void paint(Canvas canvas, Size size) {
    const slant = 0.08;
    final h = size.height, w = size.width - h * slant, t = w * 0.2, g = t * 0.15;
    canvas
      ..translate(h * slant, 0)
      ..skew(-slant, 0);

    Path hBar(double y) => Path()
      ..moveTo(t / 2 + g, y)
      ..lineTo(t + g, y - t / 2)
      ..lineTo(w - t - g, y - t / 2)
      ..lineTo(w - t / 2 - g, y)
      ..lineTo(w - t - g, y + t / 2)
      ..lineTo(t + g, y + t / 2)
      ..close();
    Path vBar(double x, double y1, double y2) => Path()
      ..moveTo(x, y1)
      ..lineTo(x + t / 2, y1 + t / 2)
      ..lineTo(x + t / 2, y2 - t / 2)
      ..lineTo(x, y2)
      ..lineTo(x - t / 2, y2 - t / 2)
      ..lineTo(x - t / 2, y1 + t / 2)
      ..close();

    final top = t / 2 + g, mid = h / 2, bottom = h - t / 2 - g, l = t / 2, r = w - t / 2;
    final segments = [
      hBar(t / 2), vBar(r, top, mid - g), vBar(r, mid + g, bottom), hBar(h - t / 2), //
      vBar(l, mid + g, bottom), vBar(l, top, mid - g), hBar(mid),
    ];
    final off = Paint()..color = color.withValues(alpha: 0.08);
    final on = Paint()..color = color;
    final halo = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (var i = 0; i < 7; i++) {
      final lit = _map[digit] & (1 << i) != 0;
      if (lit && glow) canvas.drawPath(segments[i], halo);
      canvas.drawPath(segments[i], lit ? on : off);
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) => old.digit != digit || old.color != color || old.glow != glow;
}

/// Chunky key that sinks while pressed.
class CalcKey extends StatefulWidget {
  const CalcKey({super.key, required this.color, required this.child, this.onPressed, this.tooltip});
  final Color color;
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  State<CalcKey> createState() => _CalcKeyState();
}

class _CalcKeyState extends State<CalcKey> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final face = widget.onPressed == null ? Color.lerp(widget.color, Colors.grey, 0.55)! : widget.color;
    final fg = ThemeData.estimateBrightnessForColor(face) == Brightness.dark ? Colors.white : Colors.black;
    final depth = _down ? 1.0 : 5.0;
    final radius = BorderRadius.circular(12);
    final key = AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      margin: EdgeInsets.only(top: 5 - depth),
      padding: EdgeInsets.only(bottom: depth),
      decoration: BoxDecoration(color: Color.lerp(face, Colors.black, 0.45), borderRadius: radius),
      child: Material(
        color: face,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _down = v),
          child: SizedBox(
            height: 52,
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(color: fg),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return widget.tooltip == null ? key : Tooltip(message: widget.tooltip, child: key);
  }
}

/// Printer paper strip with a torn bottom edge.
class Receipt extends StatelessWidget {
  const Receipt({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _TornEdge(),
    child: Container(
      color: const Color(0xFFFBF7EC),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.vt323(fontSize: 16, color: Colors.black54, letterSpacing: 2),
        ),
        const SizedBox(height: 4),
        child,
      ]),
    ),
  );
}

class _TornEdge extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const tooth = 8.0;
    final p = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - tooth);
    var x = size.width;
    var low = true;
    while (x > 0) {
      x = math.max(0, x - tooth);
      p.lineTo(x, low ? size.height : size.height - tooth);
      low = !low;
    }
    return p..close();
  }

  @override
  bool shouldReclip(_TornEdge old) => false;
}

/// Sliding mode switch, like the DEG/RAD switch of a scientific calculator.
class ModeSwitch<T> extends StatelessWidget {
  const ModeSwitch({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.palette,
    this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final CalcPalette palette;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final i = values.indexOf(selected);
    final text = palette.dark ? Colors.white70 : Colors.black87;
    // Tapping or dragging along the track picks the value under the pointer.
    void pick(double dx, double width) {
      final v = values[(dx / width * values.length).floor().clamp(0, values.length - 1)];
      if (v != selected) onChanged?.call(v);
    }

    return Column(children: [
      LayoutBuilder(
        builder: (context, box) => MouseRegion(
          cursor: onChanged == null ? MouseCursor.defer : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition.dx, box.maxWidth),
            onHorizontalDragUpdate: (d) => pick(d.localPosition.dx, box.maxWidth),
            // Taller than the track itself so it is easy to hit with a finger.
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                height: 22,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: palette.bezel, borderRadius: BorderRadius.circular(11)),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  alignment: Alignment(values.length == 1 ? 0 : -1 + 2 * i / (values.length - 1), 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / values.length,
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFFC9C3B6), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Row(children: [
        for (final v in values)
          Expanded(
            child: Semantics(
              button: true,
              selected: v == selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onChanged == null ? null : () => onChanged!(v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label(v).toUpperCase(),
                      style: TextStyle(
                        color: text,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: v == selected ? FontWeight.w900 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    ]);
  }
}

/// Blinking LCD cursor; stays still when the OS asks for reduced motion.
class Blink extends StatefulWidget {
  const Blink({super.key, required this.child});
  final Widget child;

  @override
  State<Blink> createState() => _BlinkState();
}

class _BlinkState extends State<Blink> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 530))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      MediaQuery.of(context).disableAnimations ? widget.child : FadeTransition(opacity: _c, child: widget.child);
}

class Screw extends StatelessWidget {
  const Screw({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Transform.rotate(
      angle: 0.6,
      child: Container(width: 8, height: 2, color: Colors.black38),
    ),
  );
}
