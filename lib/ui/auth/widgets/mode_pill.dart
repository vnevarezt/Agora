import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// `.mode-pill`: uppercase chip with an icon marking the chosen mode.
class ModePill extends StatelessWidget {
  const ModePill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: t.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: t.accentStrong),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.44,
              color: t.accentStrong,
            ),
          ),
        ],
      ),
    );
  }
}
