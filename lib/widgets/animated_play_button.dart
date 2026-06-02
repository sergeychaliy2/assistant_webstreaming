import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'atoms/circle_press_target.dart';
import 'atoms/glass_circle.dart';

/// Large hero button used on the connecting / restart screen.
///
/// Visual: rotating ring with three orange brand dots (matches Unity ref)
/// around a neutral glass center with a play glyph.
class AnimatedPlayButton extends StatefulWidget {
  const AnimatedPlayButton({
    super.key,
    required this.onPressed,
    this.size = AppTheme.playButtonSize,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final double size;
  final bool enabled;

  @override
  State<AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<AnimatedPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final innerSize = s * 0.66;

    return CirclePressTarget(
      diameter: s,
      enabled: widget.enabled,
      onTap: widget.enabled ? widget.onPressed : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _spin,
            builder: (context, _) => Transform.rotate(
              angle: _spin.value * 2 * math.pi,
              child: CustomPaint(
                size: Size.square(s),
                painter: const _OrbitRingPainter(),
              ),
            ),
          ),
          GlassCircle(
            size: innerSize,
            fillOpacity: 0.14,
            strokeOpacity: 0.45,
            child: Icon(
              Icons.play_arrow_rounded,
              size: innerSize * 0.45,
              color: AppTheme.textPrimary,
              shadows: const [
                Shadow(
                  color: Color(0x88000000),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter();

  static const Color _ring = Color(0x33FFFFFF);
  static const Color _dot = AppTheme.accentOrange;
  static const int _dotCount = 3;
  static const double _dotRadius = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - _dotRadius - 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _ring;
    canvas.drawCircle(c, r, ring);

    final dot = Paint()..color = _dot;
    final glow = Paint()
      ..color = _dot.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (var i = 0; i < _dotCount; i++) {
      final a = (i / _dotCount) * 2 * math.pi - math.pi / 2;
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      canvas.drawCircle(p, _dotRadius + 2, glow);
      canvas.drawCircle(p, _dotRadius, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
