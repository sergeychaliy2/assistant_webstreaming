import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated outer halo used to indicate an active state (recording, etc.).
/// Renders 1..N expanding rings that fade as they grow.
class PulseHalo extends StatefulWidget {
  const PulseHalo({
    super.key,
    required this.active,
    required this.diameter,
    this.color = Colors.white,
    this.ringCount = 2,
    this.duration = const Duration(milliseconds: 1400),
    this.maxExpansion = 0.45,
  });

  final bool active;
  final double diameter;
  final Color color;
  final int ringCount;
  final Duration duration;

  /// How much each ring grows beyond the base diameter (0..1).
  final double maxExpansion;

  @override
  State<PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(PulseHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.diameter * (1 + widget.maxExpansion)),
          painter: _PulsePainter(
            t: _c.value,
            base: widget.diameter,
            color: widget.color,
            ringCount: widget.ringCount,
            maxExpansion: widget.maxExpansion,
          ),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.t,
    required this.base,
    required this.color,
    required this.ringCount,
    required this.maxExpansion,
  });

  final double t;
  final double base;
  final Color color;
  final int ringCount;
  final double maxExpansion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = base / 2;

    for (var i = 0; i < ringCount; i++) {
      final offset = i / ringCount;
      final phase = (t + offset) % 1.0;
      final eased = Curves.easeOutCubic.transform(phase);
      final r = baseRadius * (1 + maxExpansion * eased);
      final alpha = (1 - phase) * 0.55;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, 2.4 * (1 - phase * 0.6))
        ..color = color.withValues(alpha: alpha);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) =>
      old.t != t ||
      old.base != base ||
      old.color != color ||
      old.ringCount != ringCount ||
      old.maxExpansion != maxExpansion;
}
