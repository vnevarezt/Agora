import 'package:flutter/material.dart';

import '../../models/hermano.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';

/// Insignia de privilegio (`.priv--*`): anciano (accent), siervo (ámbar) y
/// publicador (neutro). El ámbar lleva variante para modo oscuro.
class PrivBadge extends StatelessWidget {
  const PrivBadge({super.key, required this.privilegio});

  final Privilegio privilegio;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    final (Color bg, Color fg, Color? borde) = switch (privilegio) {
      Privilegio.anciano => (t.accentSoft, t.accentStrong, null),
      Privilegio.siervoMinisterial => oscuro
          ? (const Color(0xFF3A3115), const Color(0xFFD9C27A), null)
          : (const Color(0xFFF3ECD2), const Color(0xFF7A6512), null),
      Privilegio.publicador => (t.surface2, t.textDim, t.border2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dimens.rPill),
        border: borde != null ? Border.all(color: borde) : null,
      ),
      child: Text(
        privilegio.etiqueta.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
    );
  }
}
