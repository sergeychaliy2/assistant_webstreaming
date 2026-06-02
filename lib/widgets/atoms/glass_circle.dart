import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A circular frosted-glass surface used as the visual base for any
/// round button or indicator in the app.
///
/// Keeps the visual language consistent: backdrop blur, soft white fill,
/// thin white-translucent stroke, subtle inner highlight + outer shadow.
class GlassCircle extends StatelessWidget {
  const GlassCircle({
    super.key,
    required this.size,
    this.child,
    this.fillOpacity = 0.10,
    this.strokeOpacity = 0.35,
    this.blurSigma = AppTheme.glassBlurSigma,
    this.glowColor,
    this.glowStrength = 0.0,
  });

  final double size;
  final Widget? child;
  final double fillOpacity;
  final double strokeOpacity;
  final double blurSigma;

  /// Optional outer glow colour. When non-null and [glowStrength] > 0,
  /// a soft halo of this colour is rendered around the circle.
  final Color? glowColor;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    final shadows = <BoxShadow>[
      const BoxShadow(
        color: Color(0x55000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
      if (glowColor != null && glowStrength > 0)
        BoxShadow(
          color: glowColor!.withValues(alpha: 0.45 * glowStrength.clamp(0, 1)),
          blurRadius: 28 + 14 * glowStrength,
          spreadRadius: 2 + 4 * glowStrength,
        ),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: shadows,
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.4),
                  radius: 0.95,
                  colors: [
                    Colors.white.withValues(alpha: fillOpacity + 0.10),
                    Colors.white.withValues(alpha: fillOpacity),
                    Colors.white.withValues(alpha: fillOpacity * 0.6),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: strokeOpacity),
                  width: 1.2,
                ),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
