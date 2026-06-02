import 'package:flutter/material.dart';

import '../l10n/app_localization.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({
    super.key,
    required this.remaining,
    required this.total,
    this.onStop,
  });

  final Duration remaining;
  final Duration total;
  final VoidCallback? onStop;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final p = total.inMilliseconds == 0
        ? 0.0
        : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SizedBox(
        width: 250,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppTheme.accentOrange.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: Text(
                '${AppLocalization.of(context).timerLabel} ${_fmt(remaining)}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(color: Colors.white.withValues(alpha: 0.10)),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: p,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: AppTheme.orangeGradient,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkResponse(
              onTap: onStop,
              radius: 18,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC83C2F),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC83C2F).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
