import 'package:flutter/material.dart';

import '../../models/hermano.dart';
import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import '../widgets/mini_chip.dart';

/// Fila de la lista de gestión: avatar, nombre, etiquetas (privilegio,
/// incompleto, inactivo) y congregación a la derecha en escritorio.
class PersonaRow extends StatelessWidget {
  const PersonaRow({
    super.key,
    required this.hermano,
    required this.onTap,
    this.selected = false,
  });

  final Hermano hermano;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isMobile = context.isMobile;

    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        return AnimatedContainer(
          duration: Dimens.dFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? t.accentSoft
                : hovered
                    ? t.surface2
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimens.rControl),
          ),
          child: Opacity(
            opacity: hermano.activo ? 1 : 0.55,
            child: Row(
              children: [
                PersonAvatar(nombre: hermano.nombre),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hermano.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  ),
                ),
                if (hermano.privilegio != Privilegio.publicador) ...[
                  const SizedBox(width: 8),
                  MiniChip.tag(hermano.privilegio.etiqueta),
                ],
                if (hermano.incompleto) ...[
                  const SizedBox(width: 8),
                  const MiniChip.aux('Incompleto'),
                ],
                if (!hermano.activo) ...[
                  const SizedBox(width: 8),
                  const MiniChip.tag('Inactivo'),
                ],
                if (!isMobile && hermano.congregacion.trim().isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      hermano.congregacion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.textMute,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
