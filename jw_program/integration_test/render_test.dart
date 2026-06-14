// Verifica EN LA APP REAL (macOS) el render con pdfium y los anchos adaptativos.
// Ejecutar: flutter test integration_test/render_test.dart -d macos
//
// Escribe PNG (nombres cortos, largos y modo Sala Auxiliar) para inspección.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/domain/schedule_rules.dart';
import 'package:jw_program/models/program_row.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/pdf/pdf_rasterizer.dart';
import 'package:jw_program/pdf/program_document.dart';
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
            seccion: Section.tesoros,
            num: 1,
            titulo: 'Disfrute al máximo de la bendición de Jehová',
            min: 10),
        Part(
            seccion: Section.tesoros,
            num: 2,
            titulo: 'Busquemos perlas escondidas',
            min: 10),
        Part(
            seccion: Section.tesoros,
            num: 3,
            titulo: 'Lectura de la Biblia',
            min: 4),
        Part(
            seccion: Section.seamos,
            num: 4,
            titulo: 'Empiece conversaciones',
            min: 3),
        Part(
            seccion: Section.seamos,
            num: 5,
            titulo: 'Empiece conversaciones',
            min: 4),
        Part(seccion: Section.seamos, num: 6, titulo: 'Discurso', min: 5),
        Part(
            seccion: Section.vida,
            num: 7,
            titulo: 'Sean siempre hospitalarios',
            min: 15),
        Part(
            seccion: Section.vida,
            num: 8,
            titulo: 'Estudio bíblico de la congregación',
            min: 30),
      ],
    );

Future<void> _dump(String nombreArchivo, List<String> nombres,
    {bool aux = false}) async {
  final s = _semana();
  final sched = buildSchedule(s, 18 * 60, 105);
  final principal = <String, List<String>>{};
  final auxiliar = <String, List<String>>{};
  var k = 0;
  for (final f in sched.filas) {
    if (f.slots == 0) continue;
    if (f.rol == 'Estudiante/Ayudante:' && f.slots == 2) {
      principal[f.id] = ['Maximiliano Vargas H', 'Concepción Navarro'];
      if (f.auxSlots == 2) auxiliar[f.id] = ['Ernesto Salas R', 'Pablo Treviño'];
      continue;
    }
    principal[f.id] = [for (var i = 0; i < f.slots; i++) nombres[k++ % nombres.length]];
    if (aux && f.auxSlots > 0) {
      auxiliar[f.id] = [
        for (var i = 0; i < f.auxSlots; i++) 'Aux ${nombres[k++ % nombres.length]}'
      ];
    }
  }
  final pdf = await buildProgramPdf(
    cong: 'CONSTITUCIÓN J.A CASTRO',
    semana: s,
    sched: sched,
    asignaciones: Assignments(principal, auxiliar),
    presidente: 'Rafael G',
    aux: aux,
  );
  final img = await rasterizarPagina(pdf, scale: 2);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);
  final out = File('${dir.path}/$nombreArchivo');
  await out.writeAsBytes(png!.buffer.asUint8List());
  // ignore: avoid_print
  print('WROTE_PNG ${out.path}');
  img.dispose();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('render corto / largo / sala auxiliar', (tester) async {
    await pdfrxFlutterInitialize();
    await _dump('jw_corto.png', ['Rafael G', 'Luis V', 'Jose M']);
    await _dump('jw_largo.png', ['Rafael González', 'Luis Vargas', 'José M']);
    await _dump('jw_aux.png', ['Rafael González', 'Luis Vargas', 'José M'],
        aux: true);
  });
}
