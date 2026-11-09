import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A two-axis touch control. Values are normalized to the unit circle.
class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    super.key,
    required this.label,
    required this.color,
    required this.onChanged,
    this.size = 108,
  });

  final String label;
  final Color color;
  final ValueChanged<Offset> onChanged;
  final double size;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  int? _pointer;
  Offset _value = Offset.zero;

  void _update(Offset position) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size * 0.34;
    final raw = (position - center) / radius;
    final distance = raw.distance;
    final next = distance < 0.12
        ? Offset.zero
        : distance > 1
        ? raw / distance
        : raw;
    if (next == _value) return;
    setState(() => _value = next);
    widget.onChanged(next);
  }

  void _release(int pointer) {
    if (_pointer != pointer) return;
    _pointer = null;
    if (_value != Offset.zero) {
      setState(() => _value = Offset.zero);
      widget.onChanged(Offset.zero);
    }
  }

  @override
  void dispose() {
    if (_value != Offset.zero) widget.onChanged(Offset.zero);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final color = widget.color;
    final knobOffset = _value * (size * 0.28);
    return Semantics(
      label: '${widget.label} joystick',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (_pointer != null) return;
          _pointer = event.pointer;
          _update(event.localPosition);
        },
        onPointerMove: (event) {
          if (event.pointer == _pointer) _update(event.localPosition);
        },
        onPointerUp: (event) => _release(event.pointer),
        onPointerCancel: (event) => _release(event.pointer),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xb00a1222),
                  border: Border.all(
                    color: color.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              Container(
                width: size * 0.62,
                height: size * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.32)),
                ),
              ),
              for (var i = 0; i < 4; i++)
                Transform.rotate(
                  angle: i * math.pi / 2,
                  child: Align(
                    alignment: const Alignment(0, -0.78),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 17,
                      color: color.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              Transform.translate(
                offset: knobOffset,
                child: Container(
                  width: size * 0.43,
                  height: size * 0.43,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(color, Colors.white, 0.3)!,
                        color.withValues(alpha: 0.75),
                        const Color(0xff132237),
                      ],
                    ),
                    border: Border.all(color: Colors.white70, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.label == 'Gerak'
                        ? Icons.open_with_rounded
                        : Icons.gps_fixed_rounded,
                    color: Colors.white,
                    size: size * 0.22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
