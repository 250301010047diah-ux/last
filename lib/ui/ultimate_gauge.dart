import 'package:flutter/material.dart';

/// Ultimate charge gauge: gold-framed crystal bar split into 4 segments,
/// magenta→cyan gradient fill with a moving shine, percentage on the right,
/// and a pulsing "ULTI SIAP!" state when full.
class UltimateGauge extends StatefulWidget {
  const UltimateGauge({super.key, required this.value});

  final double value;

  @override
  State<UltimateGauge> createState() => _UltimateGaugeState();
}

class _UltimateGaugeState extends State<UltimateGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value.clamp(0.0, 1.0);
    final full = v >= 1;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          final pulse = full ? (0.5 + 0.5 * (1 - (2 * t - 1).abs())) : 0.0;
          return Row(
            children: [
              Icon(
                Icons.whatshot_rounded,
                size: 18,
                color: Color.lerp(
                  const Color(0xffff5fd2),
                  Colors.white,
                  pulse * 0.6,
                ),
                shadows: [
                  Shadow(
                    color: const Color(0xffff5fd2),
                    blurRadius: 6 + 8 * pulse,
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 14,
                  child: CustomPaint(
                    painter: _GaugePainter(value: v, shine: t, pulse: pulse),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(
                  full ? 'SIAP!' : '${(v * 100).floor()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: full
                        ? Color.lerp(
                            const Color(0xffff8ae2),
                            Colors.white,
                            pulse,
                          )
                        : Colors.white70,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.shine,
    required this.pulse,
  });

  final double value;
  final double shine;
  final double pulse;

  static const _gold = Color(0xffe8b04a);
  static const _segments = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );

    // Glow behind when full.
    if (pulse > 0) {
      canvas.drawRRect(
        outer.inflate(3),
        Paint()
          ..color = const Color(
            0xffff5fd2,
          ).withValues(alpha: 0.25 + 0.35 * pulse),
      );
    }

    // Track.
    canvas.drawRRect(outer, Paint()..color = const Color(0xcc080c1c));

    // Fill.
    final inner = outer.deflate(2.5);
    if (value > 0) {
      final fillRect = Rect.fromLTWH(
        inner.left,
        inner.top,
        inner.width * value,
        inner.height,
      );
      canvas.save();
      canvas.clipRRect(inner);
      canvas.drawRect(
        fillRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xffb02cff), Color(0xffff5fd2), Color(0xff5ee7ff)],
          ).createShader(inner.outerRect),
      );
      // Moving shine band.
      final sx = inner.left + (inner.width + 40) * shine - 20;
      canvas.clipRect(fillRect);
      canvas.drawRect(
        Rect.fromLTWH(sx - 14, inner.top, 28, inner.height),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(sx - 14, 0, 28, 1)),
      );
      // Top highlight.
      canvas.drawRect(
        Rect.fromLTWH(
          fillRect.left,
          inner.top,
          fillRect.width,
          inner.height * 0.35,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.restore();
    }

    // Segment dividers.
    final div = Paint()
      ..color = const Color(0xff05070f)
      ..strokeWidth = 2;
    for (int i = 1; i < _segments; i++) {
      final x = inner.left + inner.width * i / _segments;
      canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), div);
    }

    // Gold frame.
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = const LinearGradient(
          colors: [_gold, Color(0xfffff1c1), _gold, Color(0xff8a5a14)],
        ).createShader(outer.outerRect),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.shine != shine || old.pulse != pulse;
}
