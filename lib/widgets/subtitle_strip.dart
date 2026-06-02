import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Centered glass caption panel. The text grows from the bottom edge as
/// new tokens stream in (latest line stays visible), while older lines
/// move upward and remain accessible by scrolling.
class SubtitleStrip extends StatelessWidget {
  const SubtitleStrip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 240),
        child: GlassContainer(
          borderRadius: 22,
          strong: true,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          // `reverse: true` anchors the scroll origin to the bottom, so the
          // newest text is always pinned to the lower edge while older
          // lines scroll up out of view. The user can drag up to read
          // previous text without us re-running animateTo on every
          // streamed chunk.
          child: SingleChildScrollView(
            reverse: true,
            physics: const BouncingScrollPhysics(),
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
