import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../models/person.dart';
import '../theme/tokens.dart';
import '../widgets/pill.dart';

class PrivBadge extends StatelessWidget {
  const PrivBadge({super.key, required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final (Color bg, Color fg, Color? border) = switch (role) {
      Role.elder => (t.accentSoft, t.accentStrong, null),
      Role.ministerialServant => (t.warningSoft, t.warning, null),
      Role.publisher => (t.surface2, t.textDim, t.border2),
    };

    return Pill(label: role.label(context.t), background: bg, foreground: fg, border: border);
  }
}
