import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

class SendingIndicator extends StatelessWidget {
  const SendingIndicator({super.key, this.label = 'Sending...'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppTheme.accentOrange,
              backgroundColor: Color(0x22FFFFFF),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
