import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'animated_play_button.dart';
import 'pulsing_logo.dart';

class ConnectingView extends StatelessWidget {
  const ConnectingView({
    super.key,
    required this.label,
    required this.onStart,
    required this.showPlayButton,
  });

  final String label;
  final VoidCallback onStart;
  final bool showPlayButton;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingLogo(size: 220),
          const SizedBox(height: 60),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: showPlayButton
                ? AnimatedPlayButton(
                    key: const ValueKey('play'),
                    onPressed: onStart,
                    size: AppTheme.playButtonSize,
                  )
                : const _ConnectingSpinner(key: ValueKey('spinner')),
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              label,
              key: ValueKey(label),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectingSpinner extends StatelessWidget {
  const _ConnectingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppTheme.playButtonSize,
      height: AppTheme.playButtonSize,
      child: const Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppTheme.accentOrange,
            backgroundColor: Color(0x14FFFFFF),
          ),
        ),
      ),
    );
  }
}
