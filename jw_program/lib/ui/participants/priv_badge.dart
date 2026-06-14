import 'package:flutter/material.dart';

import '../../models/participant.dart';
import '../theme/tokens.dart';
import '../widgets/pill.dart';

/// Insignia de privilegio: anciano (accent), siervo (ámbar) y publicador
/// (neutro). El ámbar lleva variante para modo oscuro.
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

    return Pill(label: role.etiqueta, background: bg, foreground: fg, border: border);
  }
}
