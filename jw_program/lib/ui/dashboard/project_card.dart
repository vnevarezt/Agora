import 'package:flutter/material.dart';

import '../../models/congregacion.dart';
import '../../models/proyecto.dart';
import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/mini_chip.dart';
import '../widgets/progress_meter.dart';
import 'status_badge.dart';

/// Tarjeta de proyecto (`.project`): nombre, congregación, estado, semanas,
/// progreso y fecha de edición. Al tocarla se abre el editor.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.proyecto,
    required this.congregacion,
    required this.onTap,
    required this.onEdit,
  });

  final Proyecto proyecto;
  final Congregacion? congregacion;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final p = proyecto;

    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        // En escritorio el kebab aparece al hover; en móvil siempre.
        final mostrarKebab = hovered || context.isMobile;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: Dimens.dFast,
              transform: hovered
                  ? (Matrix4.identity()..translateByDouble(0, -1, 0, 1))
                  : Matrix4.identity(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hovered ? t.accent : t.border),
                boxShadow: hovered
                    ? const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 18,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nombre,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: -0.1,
                                color: t.text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (congregacion != null) ...[
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: congregacion!.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    congregacion?.nombre ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: t.textMute,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge(estado: p.estado),
                      // Hueco para el kebab superpuesto (no pisar la insignia).
                      const SizedBox(width: 22),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [for (final w in p.semanas) MiniChip.week(w)],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(child: ProgressMeter(value: p.progreso)),
                      const SizedBox(width: 10),
                      Text(
                        '${p.done}/${p.total}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: t.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Editado ${p.editado}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.textMute,
                    ),
                  ),
                ],
              ),
            ),
            if (mostrarKebab)
              Positioned(
                top: 8,
                right: 8,
                child: AppIconButton(
                  icon: Icons.more_vert,
                  size: 30,
                  tooltip: 'Editar proyecto',
                  onPressed: onEdit,
                ),
              ),
          ],
        );
      },
    );
  }
}
