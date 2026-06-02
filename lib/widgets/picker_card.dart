import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Glass card used in pickers (avatar / voice). When [selected] is true the
/// card shows a soft border highlight and a star icon to mark the current
/// choice — the user requested that the active option be marked like a
/// favourite.
class PickerCard extends StatelessWidget {
  const PickerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.leading,
    this.tagLabel,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? leading;
  final String? tagLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOrange.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            )
          : const BoxDecoration(),
      child: GlassContainer(
        borderRadius: 20,
        strong: selected,
        borderColor: selected
            ? AppTheme.accentOrange.withValues(alpha: 0.55)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tagLabel != null) ...[
                          const SizedBox(width: 8),
                          _Tag(label: tagLabel!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: selected
                    ? const Icon(
                        Icons.star_rounded,
                        key: ValueKey('star'),
                        color: AppTheme.accentOrange,
                        size: 22,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('off'),
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        size: 22,
                      ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentOrange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.accentOrange,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
