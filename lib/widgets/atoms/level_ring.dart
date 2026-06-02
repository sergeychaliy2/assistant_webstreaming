import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Thin circular ring that fills clockwise based on [level] (0..1).
/// Sits right at the rim of a circular button to visualise mic volume.
class LevelRing extends StatelessWidget {
  const LevelRing({
    super.key,
    required this.diameter,
    required this.level,
    this.color = Colors.white,
    this.thickness = 3.0,
    this.inset = 2.0,
  });

  final double diameter;

  /// 0..1 progress around the ring.
  final double level;
  final Color color;
  final double thickness;

  /// Distance from the edge of the underlying circle.
  final double inset;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(diameter),
        painter: _LevelRingPainter(
          level: level.clamp(0.0, 1.0),
          color: color,
          thickness: thickness,
          inset: inset,
        ),
      ),
    );
  }
}

class _LevelRingPainter extends CustomPainter {
  _LevelRingPainter({
    required this.level,
    required this.color,
    required this.thickness,
    required this.inset,
  });

  final double level;
  final Color color;
  final double thickness;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;
    final r = size.shortestSide / 2 - inset - thickness / 2;
    if (r <= 0) return;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.9),
        ],
      ).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * level,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelRingPainter old) =>
      old.level != level ||
      old.color != color ||
      old.thickness != thickness ||
      old.inset != inset;
}
