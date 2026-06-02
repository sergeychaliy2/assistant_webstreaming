import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, this.child});
  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.bgGradient),
            ),
            CustomPaint(
              painter: _BlobsPainter(t),
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

class _BlobsPainter extends CustomPainter {
  _BlobsPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void blob(Color color, double cx, double cy, double r) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    final phase1 = t * 2 * math.pi;
    final phase2 = (t + 0.33) * 2 * math.pi;
    final phase3 = (t + 0.66) * 2 * math.pi;

    blob(
      AppTheme.accentBlue,
      w * (0.25 + 0.05 * math.sin(phase1)),
      h * (0.30 + 0.05 * math.cos(phase1)),
      w * 0.45,
    );
    blob(
      AppTheme.accentOrange,
      w * (0.78 + 0.04 * math.cos(phase2)),
      h * (0.78 + 0.03 * math.sin(phase2)),
      w * 0.40,
    );
    blob(
      const Color(0xFF1B3270),
      w * (0.5 + 0.03 * math.sin(phase3)),
      h * (0.6 + 0.04 * math.cos(phase3)),
      w * 0.55,
    );
  }

  @override
  bool shouldRepaint(covariant _BlobsPainter oldDelegate) => oldDelegate.t != t;
}
