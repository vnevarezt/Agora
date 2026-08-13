import '../theme/dimens.dart';
import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../models/congregation.dart';
import '../../models/project.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/ink_surface.dart';
import '../widgets/mini_chip.dart';
import '../widgets/progress_meter.dart';
import 'status_badge.dart';

/// Project card (`.project`): name, congregation, status, weeks,
/// progress and edited date. Tapping it opens the editor.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.congregation,
    required this.onTap,
    required this.onEdit,
  });

  final Project project;
  final Congregation? congregation;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final p = project;

    return InkSurface(
      onTap: onTap,
      borderRadius: 16,
      hoverElevation: 6,
      builder: (context, hovered) {
        // On desktop the kebab appears on hover; on mobile always.
        final mostrarKebab = hovered || context.isMobile;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.s18, Space.s18, Space.s18, Space.s14),
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
                              p.name,
                              style: TextStyle(
                                fontSize: AppText.bodyLarge,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: -0.1,
                                color: t.text,
                              ),
                            ),
                            const SizedBox(height: Space.s4),
                            Row(
                              children: [
                                if (congregation != null) ...[
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Color(congregation!.color),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: Space.s6),
                                ],
                                Flexible(
                                  child: Text(
                                    congregation?.name ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: AppText.caption,
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
                      const SizedBox(width: Space.s10),
                      StatusBadge(status: p.status),
                      // Space for the overlaid kebab (keep clear of the badge).
                      const SizedBox(width: Space.s24),
                    ],
                  ),
                  const SizedBox(height: Space.s14),
                  Wrap(
                    spacing: Space.s6,
                    runSpacing: Space.s6,
                    children: [for (final w in p.weeks) MiniChip.week(w)],
                  ),
                  const SizedBox(height: Space.s14),
                  Row(
                    children: [
                      Expanded(child: ProgressMeter(value: p.progress)),
                      const SizedBox(width: Space.s10),
                      Text(
                        '${p.done}/${p.total}',
                        style: TextStyle(
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w800,
                          color: t.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.s10),
                  Text(
                    context.t.projectCard.edited(label: p.editedLabel),
                    style: TextStyle(
                      fontSize: AppText.caption,
                      fontWeight: FontWeight.w600,
                      color: t.textMute,
                    ),
                  ),
                ],
              ),
            ),
            if (mostrarKebab)
              Positioned(
                // AppIconButton pads its tap area to Dimens.hTouchMin (48)
                // around the 30px paint; -9 keeps the visible icon exactly
                // where an 8/8 inset would put a 30px control.
                top: -1,
                right: -1,
                child: AppIconButton(
                  icon: Icons.more_vert,
                  size: 30,
                  tooltip: context.t.projectCard.editProject,
                  onPressed: onEdit,
                ),
              ),
          ],
        );
      },
    );
  }
}
