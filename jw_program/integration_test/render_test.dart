// Verifica EN LA APP REAL (macOS) el render con pdfium y los anchos adaptativos.
// Ejecutar: flutter test integration_test/render_test.dart -d macos
//
// Escribe dos PNG (nombres cortos y largos) para inspección visual.

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

Week _semana() => Week(
      fecha: '18-24 DE MAYO',
      lectura: 'ISAÍAS 62-64',
      cancionInicial: '44',
      cancionMedia: '115',
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

Future<void> _dump(String nombreArchivo, List<String> nombres,
    {bool aux = false}) async {
  final s = _semana();
  final sched = construirFilas(s, 18 * 60, 105);
  var k = 0;
  for (final f in [
    ...sched.apertura,
    ...sched.tesoros,
    ...sched.seamos,
    ...sched.vida,
  ]) {
    if (f.rol == 'Estudiante/Ayudante:' && f.slots == 2) {
      // Nombres realistas (≤25): juntos no caben (se apilan) pero cada uno cabe
      // en el ancho por defecto -> los títulos deben volver a su ancho default.
      f.nombres[0] = 'Maximiliano Vargas H'; // Estudiante
      f.nombres[1] = 'Concepción Navarro'; // Ayudante
      if (f.auxSlots == 2) {
        f.nombresAux[0] = 'Ernesto Salas R'; // Estudiante aux
        f.nombresAux[1] = 'Pablo Treviño'; // Ayudante aux
      }
      continue;
    }
    for (var i = 0; i < f.slots; i++) {
      f.nombres[i] = nombres[k++ % nombres.length];
    }
    for (var i = 0; i < f.auxSlots; i++) {
      f.nombresAux[i] = 'Aux ${nombres[k++ % nombres.length]}';
    }
  }
  final pdf = await buildProgramPdf(
    cong: 'CONSTITUCIÓN J.A CASTRO',
    semana: s,
    sched: sched,
    presidente: 'Rafael G',
    aux: aux,
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
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(pdfImg!.pixels, pdfImg.width, pdfImg.height,
      ui.PixelFormat.bgra8888, completer.complete);
  final uiImg = await completer.future;
  final png = await uiImg.toByteData(format: ui.ImageByteFormat.png);
  final dir = await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);
  final out = File('${dir.path}/$nombreArchivo');
  await out.writeAsBytes(png!.buffer.asUint8List());
  // ignore: avoid_print
  print('WROTE_PNG ${out.path}');
  pdfImg.dispose();
  uiImg.dispose();
  await doc.dispose();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('render con nombres cortos (default) y largos (adaptativo)',
      (tester) async {
    await pdfrxFlutterInitialize();
    // Caso corto: debe quedar idéntico al layout por defecto.
    await _dump('jw_corto.png', ['Rafael G', 'Luis V', 'Jose M']);
    // Caso largo: solo las parejas Estudiante/Ayudante son largas (se apilan);
    // el resto es corto, así los títulos deben quedar a ancho ~default.
    await _dump('jw_largo.png', ['Rafael González', 'Luis Vargas', 'José M']);
    // Caso Sala Auxiliar: 4 columnas, encabezado de salas, nombres en ambas.
    await _dump('jw_aux.png', ['Rafael González', 'Luis Vargas', 'José M'],
        aux: true);
  });
}
