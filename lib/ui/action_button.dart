import 'dart:math' as math;

import 'package:flutter/material.dart';

/// In-game action button: a dark crystal disc with a gold rim, an icon glowing
/// in the action's colour, a cooldown sweep with seconds left, and (for the
/// ultimate) a charge ring that pulses when full.
class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.cooldown = 0,
    this.cooldownMax = 1,
    this.charge,
    this.enabled = true,
    this.highlight = false,
    this.size = 58,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// Seconds left on the cooldown, and the cooldown's full length.
  final double cooldown;
  final double cooldownMax;

  /// 0..1 charge for buttons that fill up (the ultimate); null otherwise.
  final double? charge;

  /// False dims the button (e.g. jump while airborne).
  final bool enabled;

  /// Tutorial highlight: a blinking amber ring.
  final bool highlight;
  final double size;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  bool _pressed = false;

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final coolingDown = w.cooldown > 0.05;
    final charge = w.charge;
    final ready = !coolingDown && w.enabled && (charge == null || charge >= 1);
    final s = w.size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) {
        _setPressed(false);
        w.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _pressed ? 0.86 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedBuilder(
              animation: _glow,
              builder: (context, _) {
                final g = Curves.easeInOut.transform(_glow.value);
                final fullUlt = charge != null && charge >= 1;
                return SizedBox(
                  width: s + 10,
                  height: s + 10,
                  child: CustomPaint(
                    painter: _ButtonPainter(
                      color: w.color,
                      ready: ready,
                      pressed: _pressed,
                      glow: fullUlt ? g : 0.35,
                      cooldownFraction: coolingDown
                          ? (w.cooldown / math.max(0.01, w.cooldownMax)).clamp(0.0, 1.0)
                          : 0,
                      charge: charge,
                      highlight: w.highlight ? g : null,
                    ),
                    child: Center(
                      child: coolingDown
                          ? Text(
                              w.cooldown >= 1
                                  ? w.cooldown.ceil().toString()
                                  : w.cooldown.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            )
                          : Icon(
                              w.icon,
                              size: s * 0.42,
                              color: ready ? Colors.white : Colors.white38,
                              shadows: ready
                                  ? [Shadow(color: w.color, blurRadius: 12 + 8 * g)]
                                  : null,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 1),
          Text(
            charge != null && charge >= 1 ? 'SIAP!' : w.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: charge != null && charge >= 1 ? w.color : Colors.white70,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonPainter extends CustomPainter {
  _ButtonPainter({
    required this.color,
    required this.ready,
    required this.pressed,
    required this.glow,
    required this.cooldownFraction,
    required this.charge,
    required this.highlight,
  });

  final Color color;
  final bool ready;
  final bool pressed;
  final double glow;
  final double cooldownFraction;
  final double? charge;
  final double? highlight;

  static const _gold = Color(0xffe8b04a);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 5;

    // Outer glow when the action is usable.
    if (ready) {
      canvas.drawCircle(
        c,
        r + 2,
        Paint()
          ..color = color.withValues(alpha: 0.25 + 0.35 * glow + (pressed ? 0.3 : 0))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 6 * glow),
      );
    }

    // Crystal disc.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Color.lerp(color, Colors.black, ready ? 0.45 : 0.75)!,
            const Color(0xff0c1022),
            const Color(0xff05070f),
          ],
          stops: const [0, 0.65, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Gold rim with an inner coloured ring.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = SweepGradient(
          colors: [
            _gold,
            const Color(0xfffff1c1),
            _gold,
            const Color(0xff8a5a14),
            _gold,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: ready ? 0.7 : 0.25),
    );

    // Rune ticks around the rim.
    final tick = Paint()
      ..color = _gold.withValues(alpha: 0.8)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 - math.pi / 4;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r + 1.5),
        c + Offset(math.cos(a), math.sin(a)) * (r + 4.5),
        tick,
      );
    }

    // Cooldown sweep (dark wedge for the time remaining).
    if (cooldownFraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 1),
        -math.pi / 2,
        math.pi * 2 * cooldownFraction,
        true,
        Paint()..color = Colors.black.withValues(alpha: 0.6),
      );
    }

    // Charge ring (ultimate).
    final ch = charge;
    if (ch != null) {
      final rect = Rect.fromCircle(center: c, radius: r + 3);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white12,
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * ch.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(color, Colors.white, ch >= 1 ? 0.3 * glow : 0)!,
      );
    }

    // Tutorial highlight.
    final h = highlight;
    if (h != null) {
      canvas.drawCircle(
        c,
        r + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 2 * h
          ..color = Colors.amber.withValues(alpha: 0.5 + 0.5 * h),
      );
    }
  }

  @override
  bool shouldRepaint(_ButtonPainter old) =>
      old.color != color ||
      old.ready != ready ||
      old.pressed != pressed ||
      old.glow != glow ||
      old.cooldownFraction != cooldownFraction ||
      old.charge != charge ||
      old.highlight != highlight;
}
