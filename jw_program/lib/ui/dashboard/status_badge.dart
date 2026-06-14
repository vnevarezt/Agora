import 'package:flutter/material.dart';

import '../../models/project.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';

/// Insignia de estado del proyecto (`.status--*`): borrador (accent), completo
/// (verde) y exportado (neutro). El verde lleva variante para modo oscuro.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.estado});

  final ProjectStatus estado;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    final (Color bg, Color fg, Color? borde) = switch (estado) {
      ProjectStatus.borrador => (t.accentSoft, t.accentStrong, null),
      ProjectStatus.completo => oscuro
          ? (const Color(0xFF1E3A2A), const Color(0xFFA9D8B8), null)
          : (const Color(0xFFDCF0E0), const Color(0xFF2E6A3E), null),
      ProjectStatus.exportado => (t.surface2, t.textMute, t.border2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dimens.rPill),
        border: borde != null ? Border.all(color: borde) : null,
      ),
      child: Text(
        estado.etiqueta.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.42,
          color: fg,
        ),
      ),
    );
  }
}
