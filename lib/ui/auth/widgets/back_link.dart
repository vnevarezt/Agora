import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/app_button.dart';

/// `.auth-back`: arrow + label that brightens on hover.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        onTap: onTap,
        builder: (context, hovered, _) {
          final color = hovered ? t.text : t.textMute;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
