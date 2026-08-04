import 'package:flutter/material.dart';

import '../../models/project.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/pill.dart';

/// Project status badge: draft (accent), complete (green) and
/// exported (neutral). The green has a dark-mode variant.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final (Color bg, Color fg, Color? border) = switch (status) {
      ProjectStatus.draft => (t.accentSoft, t.accentStrong, null),
      ProjectStatus.complete => (t.successSoft, t.success, null),
      ProjectStatus.exported => (t.surface2, t.textMute, t.border2),
    };

    return Pill(
      label: status.label,
      background: bg,
      foreground: fg,
      border: border,
      fontSize: AppText.micro,
    );
  }
}
