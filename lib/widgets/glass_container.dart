import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.blur = 18,
    this.strong = false,
    this.borderColor,
    this.fillColor,
    this.shadow = true,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final bool strong;
  final Color? borderColor;
  final Color? fillColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final fill =
        fillColor ?? (strong ? AppTheme.glassFillStrong : AppTheme.glassFill);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? AppTheme.glassStroke,
              width: 1,
            ),
            boxShadow: shadow
                ? const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
