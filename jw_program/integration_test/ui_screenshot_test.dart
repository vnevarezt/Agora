// Captura screenshots reales de la UI rediseñada (escritorio, tablet y
// móvil; claro/oscuro; picker abierto) para compararlos con el mock.
// Ejecutar: flutter test integration_test/ui_screenshot_test.dart -d macos

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jw_program/app.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/state/program_form.dart';
import 'package:jw_program/state/weeks_provider.dart';
import 'package:jw_program/ui/shell/program_shell.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

final _shotKey = GlobalKey();

Week _semana() => Week(
      fecha: '4-10 DE MAYO',
      lectura: 'ISAÍAS 58, 59',
      cancionInicial: '21',
      cancionMedia: '100',
      cancionFinal: '151',
      partes: const [
        Part(
            seccion: Seccion.tesoros,
            num: 1,
            titulo: 'Disfrute al máximo de la bendición de Jehová',
            min: 10),
        Part(
            seccion: Seccion.tesoros,
            num: 2,
            titulo: 'Busquemos perlas escondidas',
            min: 10),
        Part(
            seccion: Seccion.tesoros,
            num: 3,
            titulo: 'Lectura de la Biblia',
            min: 4),
        Part(
            seccion: Seccion.seamos,
            num: 4,
            titulo: 'Empiece conversaciones',
            min: 3),
        Part(
            seccion: Seccion.seamos,
            num: 5,
            titulo: 'Empiece conversaciones',
            min: 4),
        Part(seccion: Seccion.seamos, num: 6, titulo: 'Discurso', min: 5),
        Part(
            seccion: Seccion.vida,
            num: 7,
            titulo: 'Sean siempre hospitalarios',
            min: 15),
        Part(
            seccion: Seccion.vida,
            num: 8,
            titulo: 'Estudio bíblico de la congregación',
            min: 30),
      ],
    );

class _FakeWeeksController extends WeeksController {
  @override
  Future<List<Week>> build() async => [_semana()];
}

Future<void> _esperar(WidgetTester tester, [int ms = 500]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump();
}

Future<void> _shot(WidgetTester tester, String nombre) async {
  await tester.pump();
  final boundary = _shotKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  final png = await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return bytes!;
  });
  final dir = await tester.runAsync(getApplicationDocumentsDirectory);
  final out = File('${dir!.path}/$nombre');
  await tester.runAsync(() => out.writeAsBytes(png!.buffer.asUint8List()));
  // ignore: avoid_print
  print('WROTE_PNG ${out.path}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshots de la UI en todos los tamaños', (tester) async {
    await tester.runAsync(() async => pdfrxFlutterInitialize());

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 880);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        key: _shotKey,
        child: ProviderScope(
          overrides: [
            weeksProvider.overrideWith(_FakeWeeksController.new),
          ],
          child: const JwProgramApp(),
        ),
      ),
    );
    await _esperar(tester, 1000);

    // Asignaciones de demo (espejo del mock).
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ProgramShell)),
        listen: false);
    final form = container.read(formProvider.notifier);
    form.setPresidente('Andrés Beltrán');
    form.setNombresPrincipal('ap0', ['Raúl Espinoza']);
    form.setNombresPrincipal('te0', ['Daniel Ortega']);
    form.setNombresPrincipal('te2', ['Joel Paredes']);
    form.setNombresPrincipal('se0', ['Esteban Ríos', 'Felipe Cordero']);
    form.setNombresPrincipal('vi2', ['Saúl Bravo', '']);
    await _esperar(tester, 1200); // raster del PDF con nombres
    await _shot(tester, 'ui_desktop_claro.png');

    // Panel de configuración expandido.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await _esperar(tester, 400);
    await _shot(tester, 'ui_desktop_config.png');
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await _esperar(tester, 400);

    // Picker popover (slot del presidente).
    await tester.tap(find.text('Andrés Beltrán').first);
    await _esperar(tester, 400);
    await _shot(tester, 'ui_desktop_picker.png');
    await tester.tapAt(const Offset(20, 860)); // scrim
    await _esperar(tester, 300);

    // Modo oscuro.
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await _esperar(tester, 500);
    await _shot(tester, 'ui_desktop_oscuro.png');
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await _esperar(tester, 400);

    // Tablet.
    tester.view.physicalSize = const Size(834, 1112);
    await _esperar(tester, 600);
    await _shot(tester, 'ui_tablet.png');

    // Móvil: pestaña Asignar.
    tester.view.physicalSize = const Size(390, 844);
    await _esperar(tester, 600);
    await _shot(tester, 'ui_movil_asignar.png');

    // Móvil: picker como bottom sheet.
    await tester.tap(find.text('Andrés Beltrán').first);
    await _esperar(tester, 500);
    await _shot(tester, 'ui_movil_picker.png');
    await tester.tapAt(const Offset(195, 80)); // scrim superior
    await _esperar(tester, 400);

    // Móvil: pestaña Vista previa.
    await tester.tap(find.text('Vista previa').last);
    await _esperar(tester, 900);
    await _shot(tester, 'ui_movil_vista.png');
  });
}
