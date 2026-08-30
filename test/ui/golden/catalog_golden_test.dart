import 'package:agora/models/week.dart';
import 'package:agora/ui/theme/dimens.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/agora_mark.dart';
import 'package:agora/ui/widgets/app_button.dart';
import 'package:agora/ui/widgets/app_spinner.dart';
import 'package:agora/ui/widgets/app_switch.dart';
import 'package:agora/ui/widgets/avatar.dart';
import 'package:agora/ui/widgets/block_title.dart';
import 'package:agora/ui/widgets/danger_button.dart';
import 'package:agora/ui/widgets/empty_state.dart';
import 'package:agora/ui/widgets/filter_pill.dart';
import 'package:agora/ui/widgets/mini_chip.dart';
import 'package:agora/ui/widgets/pill.dart';
import 'package:agora/ui/widgets/progress_meter.dart';
import 'package:agora/ui/widgets/progress_ring.dart';
import 'package:agora/ui/widgets/section_header.dart';
import 'package:agora/ui/widgets/segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog.dart';

/// The catalogue's appearance, which until now was verified only by reading
/// it. Behaviour has had tests for a while — contrast, motion, scaling,
/// keyboard, semantics — and every one of them can pass on a control that
/// looks wrong.
///
/// Both themes, because half the token contract only exists in the other one:
/// a value that reads on white and vanishes on near-black is the single most
/// common defect these images are here to catch.
///
/// Regenerate with `flutter test --update-goldens test/ui/golden`, and look at
/// the diff before accepting it — an updated golden is a claim that the new
/// appearance is the intended one.
void main() {
  setUpAll(loadAppFonts);

  List<Widget> controls() => [
    GoldenRow('AppButton', [
      AppButton(label: 'Guardar cambios', onPressed: () {}),
      AppButton(
        icon: Icons.add,
        label: 'Con icono',
        onPressed: () {},
      ),
      AppButton(
        variant: AppButtonVariant.ghost,
        icon: Icons.download,
        label: 'Ghost',
        onPressed: () {},
      ),
      const AppButton(label: 'Deshabilitado', onPressed: null),
      AppButton(label: 'Ocupado', busy: true, onPressed: () {}),
      AppButton(icon: Icons.close, onPressed: () {}),
    ]),
    GoldenRow('AppIconButton', [
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
    ]),
    GoldenRow('DangerButton · AppSwitch', [
      DangerButton(label: 'Eliminar cuenta', onTap: () {}),
      AppSwitch(value: true, onChanged: (_) {}),
      AppSwitch(value: false, onChanged: (_) {}),
    ]),
    GoldenRow('SegmentedTabs', [
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
    ]),
  ];

  List<Widget> markers(AppTokens t) => [
    GoldenRow('Pill', [
      Pill(
        label: 'COMPLETO',
        background: t.successSoft,
        foreground: t.success,
      ),
      Pill(
        label: 'PENDIENTE',
        background: t.warningSoft,
        foreground: t.warning,
      ),
      Pill(label: 'BORRADOR', background: t.accentSoft, foreground: t.accentOnSoft),
    ]),
    GoldenRow('MiniChip', const [
      MiniChip.time('19:00'),
      MiniChip.allMeeting('TODA LA REUNIÓN'),
      MiniChip.duration('10 min'),
      MiniChip.tag('Cántico'),
      MiniChip.aux('Sala auxiliar'),
      MiniChip.week('6-12 DE JULIO'),
    ]),
    GoldenRow('FilterPill', [
      FilterPill(label: 'Activo', active: true, count: 12, onTap: () {}),
      FilterPill(label: 'Inactivo', active: false, onTap: () {}),
      FilterPill(
        label: 'Con punto',
        active: false,
        dotColor: t.warningStrong,
        onTap: () {},
      ),
    ]),
    GoldenRow('Progress', [
      const ProgressRing(done: 7, total: 12),
      const SizedBox(width: 200, child: ProgressMeter(value: 0.58)),
      const AppSpinner(),
    ]),
    GoldenRow('PersonAvatar', const [
      PersonAvatar(name: 'Ana Rodríguez'),
      PersonAvatar(name: 'Bruno Silva', size: Dimens.avatarCard),
      PersonAvatar(size: Dimens.avatarRow),
    ]),
  ];

  List<Widget> structure() => [
    GoldenRow('SectionHeader', [
      SizedBox(
        width: 340,
        child: SectionHeader(
          title: 'Tesoros de la Biblia',
          dotColor: kSectionColors[Section.treasures],
          done: 3,
          total: 4,
        ),
      ),
    ]),
    GoldenRow('BlockTitle', [
      SizedBox(
        width: 340,
        child: BlockTitle(title: 'Proyectos', count: 4, linkLabel: 'Ver todo', onLink: () {}),
      ),
    ]),
    GoldenRow('AgoraMark · AgoraLockup', const [
      AgoraMark(size: Dimens.markNav),
      AgoraLockup(),
    ]),
    GoldenRow('EmptyState', [
      SizedBox(
        width: 420,
        height: 240,
        child: EmptyState(
          icon: Icons.groups_outlined,
          title: 'Sin congregación',
          message: 'Todo se archiva bajo una congregación. Crea o únete a una '
              'para empezar.',
          action: AppButton(icon: Icons.add, label: 'Crear', onPressed: () {}),
        ),
      ),
    ]),
  ];

  for (final mode in [
    (name: 'light', brightness: Brightness.light, tokens: pizarra.light),
    (name: 'dark', brightness: Brightness.dark, tokens: pizarra.dark),
  ]) {
    testWidgets('controls · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(brightness: mode.brightness, children: controls()),
        'controls_${mode.name}',
      );
    });

    testWidgets('markers · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(brightness: mode.brightness, children: markers(mode.tokens)),
        'markers_${mode.name}',
        size: const Size(760, 400),
      );
    });

    testWidgets('structure · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(brightness: mode.brightness, children: structure()),
        'structure_${mode.name}',
        size: const Size(760, 520),
      );
    });
  }
}
