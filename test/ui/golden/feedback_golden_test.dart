import 'package:agora/ui/theme/dimens.dart';
import 'package:agora/ui/widgets/app_snack_bar.dart';
import 'package:agora/ui/widgets/bound_text_field.dart';
import 'package:agora/ui/widgets/export_panel.dart';
import 'package:agora/ui/widgets/labeled_field.dart';
import 'package:agora/ui/widgets/modal_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog.dart';

/// The surfaces the catalogue goldens could not reach, because each is
/// normally arrived at through a route: the modal, the export sheet and the
/// snackbar. They are ordinary widgets underneath, so they are mounted
/// directly here rather than driven — what these images defend is how the
/// surface looks, not how it is opened.
void main() {
  setUpAll(loadAppFonts);

  Widget modal({required bool sheet, String? danger}) => SizedBox(
    width: 520,
    child: ModalShell(
      sheet: sheet,
      onClose: () {},
      title: 'Editar participante',
      desc: 'Los cambios se guardan al confirmar.',
      primaryLabel: 'Guardar cambios',
      onPrimary: () {},
      dangerLabel: danger,
      onDanger: danger == null ? null : () {},
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.s14,
        children: [
          LabeledField(
            label: 'NOMBRE',
            child: BoundTextField(initial: 'Ana Rodríguez', onChanged: (_) {}),
          ),
          const LabeledField(
            label: 'DURACIÓN TOTAL',
            child: ReadonlyField(texto: '1 h 45 min'),
          ),
        ],
      ),
    ),
  );

  for (final mode in [
    (name: 'light', brightness: Brightness.light),
    (name: 'dark', brightness: Brightness.dark),
  ]) {
    testWidgets('modal · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(
          brightness: mode.brightness,
          children: [
            goldenRow('ModalShell · dialog', [modal(sheet: false)]),
            goldenRow('ModalShell · sheet, with a destructive action', [
              modal(sheet: true, danger: 'Eliminar'),
            ]),
          ],
        ),
        'modal_${mode.name}',
        size: const Size(620, 900),
      );
    });

    testWidgets('feedback · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(
          brightness: mode.brightness,
          children: [
            goldenRow('ExportPanel', [
              SizedBox(
                width: 320,
                child: ExportPanel(enabled: true, onExport: (_, _, _) {}),
              ),
              SizedBox(
                width: 320,
                child: ExportPanel(enabled: false, onExport: (_, _, _) {}),
              ),
            ]),
          ],
        ),
        'feedback_${mode.name}',
        size: const Size(760, 300),
      );
    });

    for (final kind in [
      (
        name: 'success',
        kind: AppSnackKind.success,
        message: 'Copia restaurada: 42 registros',
      ),
      (
        name: 'failure',
        kind: AppSnackKind.failure,
        message: 'La copia no se pudo descifrar',
      ),
    ]) {
      testWidgets('snackbar ${kind.name} · ${mode.name}', (tester) async {
        // Driven rather than composed: the bar is built by the messenger, and
        // its private body is not something a call site can hand to a golden.
        // One bar per mount, because showing the second dismisses the first
        // and the handover is a race the image would sometimes lose.
        //
        // Size first: the bar is laid out against the window, and resizing
        // after the pump leaves it measured for the old one.
        tester.view.physicalSize = const Size(600, 220);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        late ScaffoldMessengerState messenger;
        await tester.pumpWidget(
          GoldenPage(
            brightness: mode.brightness,
            children: [
              Builder(
                builder: (context) {
                  messenger = ScaffoldMessenger.of(context);
                  return const SizedBox(height: 40);
                },
              ),
            ],
          ),
        );

        showAppSnack(messenger, message: kind.message, kind: kind.kind);
        await tester.pump();
        // Past the entrance, short of the dwell, so the bar is at rest.
        await tester.pump(const Duration(milliseconds: 800));

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('snackbar_${kind.name}_${mode.name}.png'),
        );
      });
    }
  }
}
