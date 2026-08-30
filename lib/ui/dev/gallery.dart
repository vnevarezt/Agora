import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/week.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/agora_mark.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/app_spinner.dart';
import '../widgets/app_switch.dart';
import '../widgets/avatar.dart';
import '../widgets/block_title.dart';
import '../widgets/danger_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_pill.dart';
import '../widgets/mini_chip.dart';
import '../widgets/pill.dart';
import '../widgets/progress_meter.dart';
import '../widgets/progress_ring.dart';
import '../widgets/section_header.dart';
import '../widgets/segmented_control.dart';

/// The catalogue, composed once.
///
/// Two things read this: [GalleryScreen], which is how a person looks at the
/// components, and `test/ui/golden/`, which is how a machine notices one of
/// them changing. Composing it here rather than in the test is what keeps
/// those two the same catalogue — a gallery that has drifted from the images
/// defending it is worse than no gallery, because it looks like coverage.
///
/// It ships in the bundle only if something references it outside a
/// [kDebugMode] guard. [GalleryScreen] is behind one, so release builds tree
/// out the whole file.
typedef GallerySection = ({String label, List<Widget> children});

List<GallerySection> galleryControls() => [
  (
    label: 'AppButton',
    children: [
      AppButton(label: 'Guardar cambios', onPressed: () {}),
      AppButton(icon: Icons.add, label: 'Con icono', onPressed: () {}),
      AppButton(
        variant: AppButtonVariant.ghost,
        icon: Icons.download,
        label: 'Ghost',
        onPressed: () {},
      ),
      const AppButton(label: 'Deshabilitado', onPressed: null),
      AppButton(label: 'Ocupado', busy: true, onPressed: () {}),
      AppButton(icon: Icons.close, onPressed: () {}),
    ],
  ),
  (
    label: 'AppIconButton',
    children: [
      AppIconButton(icon: Icons.more_vert, tooltip: 'Menú', onPressed: () {}),
      AppIconButton(
        icon: Icons.close,
        bordered: true,
        tooltip: 'Cerrar',
        onPressed: () {},
      ),
      AppIconButton(
        icon: Icons.zoom_in,
        elevated: true,
        tooltip: 'Acercar',
        onPressed: () {},
      ),
    ],
  ),
  (
    label: 'DangerButton · AppSwitch',
    children: [
      DangerButton(label: 'Eliminar cuenta', onTap: () {}),
      AppSwitch(value: true, onChanged: (_) {}),
      AppSwitch(value: false, onChanged: (_) {}),
    ],
  ),
  (
    label: 'SegmentedTabs',
    children: [
      SizedBox(
        width: 260,
        child: SegmentedTabs(
          index: 0,
          segments: const [
            (icon: Icons.edit_outlined, label: 'Asignar'),
            (icon: Icons.description_outlined, label: 'Vista previa'),
          ],
          onChanged: (_) {},
        ),
      ),
    ],
  ),
];

List<GallerySection> galleryMarkers(AppTokens t) => [
  (
    label: 'Pill',
    children: [
      Pill(label: 'COMPLETO', background: t.successSoft, foreground: t.success),
      Pill(
        label: 'PENDIENTE',
        background: t.warningSoft,
        foreground: t.warning,
      ),
      Pill(
        label: 'BORRADOR',
        background: t.accentSoft,
        foreground: t.accentOnSoft,
      ),
    ],
  ),
  (
    label: 'MiniChip',
    children: const [
      MiniChip.time('19:00'),
      MiniChip.allMeeting('TODA LA REUNIÓN'),
      MiniChip.duration('10 min'),
      MiniChip.tag('Cántico'),
      MiniChip.aux('Sala auxiliar'),
      MiniChip.week('6-12 DE JULIO'),
    ],
  ),
  (
    label: 'FilterPill',
    children: [
      FilterPill(label: 'Activo', active: true, count: 12, onTap: () {}),
      FilterPill(label: 'Inactivo', active: false, onTap: () {}),
      FilterPill(
        label: 'Con punto',
        active: false,
        dotColor: t.warningStrong,
        onTap: () {},
      ),
    ],
  ),
  (
    label: 'Progress',
    children: const [
      ProgressRing(done: 7, total: 12),
      SizedBox(width: 200, child: ProgressMeter(value: 0.58)),
      AppSpinner(),
    ],
  ),
  (
    label: 'PersonAvatar',
    children: const [
      PersonAvatar(name: 'Ana Rodríguez'),
      PersonAvatar(name: 'Bruno Silva', size: Dimens.avatarCard),
      PersonAvatar(size: Dimens.avatarRow),
    ],
  ),
];

List<GallerySection> galleryStructure() => [
  (
    label: 'SectionHeader',
    children: [
      SizedBox(
        width: 340,
        child: SectionHeader(
          title: 'Tesoros de la Biblia',
          dotColor: kSectionColors[Section.treasures],
          done: 3,
          total: 4,
        ),
      ),
    ],
  ),
  (
    label: 'BlockTitle',
    children: [
      SizedBox(
        width: 340,
        child: BlockTitle(
          title: 'Proyectos',
          count: 4,
          linkLabel: 'Ver todo',
          onLink: () {},
        ),
      ),
    ],
  ),
  (
    label: 'AgoraMark · AgoraLockup',
    children: const [
      AgoraMark(size: Dimens.markNav),
      AgoraLockup(),
    ],
  ),
  (
    label: 'EmptyState',
    children: [
      SizedBox(
        width: 420,
        height: 240,
        child: EmptyState(
          icon: Icons.groups_outlined,
          title: 'Sin congregación',
          message:
              'Todo se archiva bajo una congregación. Crea o únete a una '
              'para empezar.',
          action: AppButton(icon: Icons.add, label: 'Crear', onPressed: () {}),
        ),
      ),
    ],
  ),
];

/// A section's label above its variants. Shared with the goldens so a diff
/// says which row moved.
class GalleryRow extends StatelessWidget {
  const GalleryRow(this.section, {super.key});

  final GallerySection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.label,
          style: AppText.label(
            size: AppText.micro,
            color: context.tokens.textMute,
          ),
        ),
        const SizedBox(height: Space.s8),
        Wrap(
          spacing: Space.s12,
          runSpacing: Space.s12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: section.children,
        ),
      ],
    );
  }
}

/// Debug-only catalogue screen: the whole of the above, scrollable, with the
/// snackbar and the theme reachable from the app bar.
///
/// Not reachable in a release build — see [kDebugMode] at its call site — and
/// deliberately not translated: it is a developer tool, and every string in it
/// is a component's name.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final sections = [
      ...galleryControls(),
      ...galleryMarkers(t),
      ...galleryStructure(),
    ];

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        title: Text(
          'Catalogue',
          style: TextStyle(
            fontSize: AppText.title,
            fontWeight: FontWeight.w800,
            color: t.text,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.s12),
            child: Builder(
              builder: (context) => AppButton(
                variant: AppButtonVariant.ghost,
                icon: Icons.notifications_outlined,
                label: 'Snack',
                onPressed: () => showAppSnack(
                  ScaffoldMessenger.of(context),
                  message: 'Copia restaurada: 42 registros',
                  kind: AppSnackKind.success,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(Space.s24),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: Space.s18),
        itemBuilder: (context, i) => GalleryRow(sections[i]),
      ),
    );
  }
}
