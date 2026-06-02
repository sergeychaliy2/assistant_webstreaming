import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localization.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/pulsing_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onDone,
    this.duration = const Duration(milliseconds: 2400),
  });

  final VoidCallback onDone;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _exitTimer;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _exitTimer = Timer(widget.duration, () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: AnimatedBackground(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _intro,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulsingLogo(size: 320),
                const SizedBox(height: 24),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _intro,
                    curve:
                        const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _intro,
                      curve: const Interval(0.4, 1.0,
                          curve: Curves.easeOutCubic),
                    ),
                    child: Text(
                      AppLocalization.of(context).brandTagline,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 14,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
