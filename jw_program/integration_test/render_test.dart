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
      date: '18-24 DE MAYO',
      reading: 'ISAÍAS 62-64',
      openingSong: '44',
      middleSong: '115',
      closingSong: '151',
      parts: const [
        Part(
            section: Section.treasures,
            number: 1,
            title: 'Disfrute al máximo de la bendición de Jehová',
            minutes: 10),
        Part(
            section: Section.treasures,
            number: 2,
            title: 'Busquemos perlas escondidas',
            minutes: 10),
        Part(
            section: Section.treasures,
            number: 3,
            title: 'Lectura de la Biblia',
            minutes: 4),
        Part(
            section: Section.ministry,
            number: 4,
            title: 'Empiece conversaciones',
            minutes: 3),
        Part(
            section: Section.ministry,
            number: 5,
            title: 'Empiece conversaciones',
            minutes: 4),
        Part(section: Section.ministry, number: 6, title: 'Discurso', minutes: 5),
        Part(
            section: Section.christianLife,
            number: 7,
            title: 'Sean siempre hospitalarios',
            minutes: 15),
        Part(
            section: Section.christianLife,
            number: 8,
            title: 'Estudio bíblico de la congregación',
            minutes: 30),
      ],
    );

Future<void> _dump(String nombreArchivo, List<String> nombres,
    {bool aux = false}) async {
  final s = _semana();
  final sched = buildSchedule(s, 18 * 60, 105);
  final principal = <String, List<String>>{};
  final auxiliar = <String, List<String>>{};
  var k = 0;
  for (final f in sched.rows) {
    if (f.slots == 0) continue;
    if (f.role == 'Estudiante/Ayudante:' && f.slots == 2) {
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
    chairman: 'Rafael G',
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
