import 'package:flutter/material.dart';

import '../../models/project.dart';
import '../theme/tokens.dart';
import '../widgets/pill.dart';

/// Insignia de status del project: borrador (accent), completo (verde) y
/// exportado (neutro). El verde lleva variante para modo dark.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final (Color bg, Color fg, Color? border) = switch (status) {
      ProjectStatus.draft => (t.accentSoft, t.accentStrong, null),
      ProjectStatus.complete => dark
          ? (const Color(0xFF1E3A2A), const Color(0xFFA9D8B8), null)
          : (const Color(0xFFDCF0E0), const Color(0xFF2E6A3E), null),
      ProjectStatus.exported => (t.surface2, t.textMute, t.border2),
    };

    return Pill(
      label: status.label,
      background: bg,
      foreground: fg,
      border: border,
      fontSize: 10.5,
    );
  }
}
