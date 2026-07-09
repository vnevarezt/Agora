import 'package:flutter/material.dart';

import '../../models/participant.dart';
import '../theme/tokens.dart';
import '../widgets/pill.dart';

/// Privilege badge: elder (accent), servant (amber) and publisher
/// (neutral). The amber has a dark-mode variant.
class PrivBadge extends StatelessWidget {
  const PrivBadge({super.key, required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final (Color bg, Color fg, Color? border) = switch (role) {
      Role.elder => (t.accentSoft, t.accentStrong, null),
      Role.ministerialServant => dark
          ? (const Color(0xFF3A3115), const Color(0xFFD9C27A), null)
          : (const Color(0xFFF3ECD2), const Color(0xFF7A6512), null),
      Role.publisher => (t.surface2, t.textDim, t.border2),
    };

    return Pill(label: role.label, background: bg, foreground: fg, border: border);
  }
}
