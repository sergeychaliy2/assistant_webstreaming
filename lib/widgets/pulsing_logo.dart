import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Breathing MT brand logo with a soft glow halo behind it.
/// Used on splash and connecting screens to give the brand presence
/// while the app is in a waiting state.
class PulsingLogo extends StatefulWidget {
  const PulsingLogo({
    super.key,
    this.size = 240,
    this.glowColor = AppTheme.accentOrange,
    this.period = const Duration(milliseconds: 2600),
    this.minScale = 0.97,
    this.maxScale = 1.04,
  });

  final double size;
  final Color glowColor;
  final Duration period;
  final double minScale;
  final double maxScale;

  @override
  State<PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Container is a strict square so vertical+horizontal centering is
    // unambiguous regardless of the logo's intrinsic aspect ratio.
    final boxSize = widget.size * widget.maxScale;
    return SizedBox.square(
      dimension: boxSize,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final breath = 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
          final scale =
              widget.minScale + (widget.maxScale - widget.minScale) * breath;
          final glowAlpha = 0.18 + 0.22 * breath;
          final glowSpread = 6.0 + 14.0 * breath;
          return Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: widget.size * 0.85,
                  height: widget.size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: glowAlpha),
                        blurRadius: 60 + 30 * breath,
                        spreadRadius: glowSpread,
                      ),
                      BoxShadow(
                        color: AppTheme.accentBlue
                            .withValues(alpha: glowAlpha * 0.5),
                        blurRadius: 80,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: SizedBox.square(
                    dimension: widget.size,
                    child: Image.asset(
                      'assets/images/logo_mt.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
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
