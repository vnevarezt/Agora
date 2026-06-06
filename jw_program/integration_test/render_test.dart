// Verifica EN LA APP REAL (macOS) que pdfrx rasteriza la página del programa.
// Ejecutar: flutter test integration_test/render_test.dart -d macos
//
// Escribe el PNG en la carpeta temporal para inspección visual.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/pdf/program_pdf.dart';
import 'package:jw_program/schedule/rules.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rasteriza el programa con pdfium', (tester) async {
    await pdfrxFlutterInitialize();

    final s = Week(
      fecha: '18-24 DE MAYO',
      lectura: 'ISAÍAS 62-64',
      cancionInicial: '44',
      cancionMedia: '115',
      cancionFinal: '151',
      partes: const [
        Part(seccion: Seccion.tesoros, num: 1, titulo: 'El Alfarero', min: 10),
        Part(seccion: Seccion.tesoros, num: 3, titulo: 'Lectura de la Biblia', min: 4),
        Part(seccion: Seccion.seamos, num: 4, titulo: 'Empiece conversaciones', min: 3),
        Part(seccion: Seccion.vida, num: 7, titulo: 'Estudio bíblico de la congregación', min: 30),
      ],
    );
    final sched = construirFilas(s, 18 * 60, 105);
    var k = 0;
    for (final f in [...sched.apertura, ...sched.tesoros, ...sched.seamos, ...sched.vida]) {
      for (var i = 0; i < f.slots; i++) {
        f.nombres[i] = 'Nombre ${++k}';
      }
    }
    final pdf = await buildProgramPdf(
      cong: 'CONSTITUCIÓN J.A CASTRO',
      semana: s,
      sched: sched,
      presidente: 'Rafael G',
    );

    final doc = await PdfDocument.openData(pdf);
    final page = doc.pages.first;
    final w = (page.width * 2).round();
    final h = (page.height * 2).round();
    final pdfImg = await page.render(
      width: w,
      height: h,
      fullWidth: w.toDouble(),
      fullHeight: h.toDouble(),
      backgroundColor: 0xFFFFFFFF,
    );
    expect(pdfImg, isNotNull);

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        pdfImg!.pixels, pdfImg.width, pdfImg.height, ui.PixelFormat.bgra8888,
        completer.complete);
    final uiImg = await completer.future;
    final png = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final out = File('${dir.path}/jw_render_check.png');
    await out.writeAsBytes(png!.buffer.asUint8List());
    // ignore: avoid_print
    print('WROTE_PNG ${out.path}');

    // Verifica que el EXPORT a Downloads funciona (entitlement del sandbox).
    final dl = await getDownloadsDirectory();
    expect(dl, isNotNull);
    final exported = File('${dl!.path}/jw_export_check.pdf');
    await exported.writeAsBytes(pdf);
    expect(await exported.exists(), isTrue);
    await exported.delete();
    // ignore: avoid_print
    print('EXPORT_OK ${dl.path}');

    pdfImg.dispose();
    uiImg.dispose();
    await doc.dispose();
  });
}
