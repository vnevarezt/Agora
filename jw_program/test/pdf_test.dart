// Verifica que el render del PDF carga las fuentes Carlito y produce un PDF
// válido (sin red ni GUI).

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/pdf/program_pdf.dart';
import 'package:jw_program/schedule/rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildProgramPdf genera un PDF válido', () async {
    final semana = Week(
      fecha: '18-24 DE MAYO',
      lectura: 'ISAÍAS 62-64',
      cancionInicial: '44',
      cancionMedia: '115',
      cancionFinal: '151',
      partes: const [
        Part(seccion: Seccion.tesoros, num: 1, titulo: 'El Alfarero', min: 10),
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
            seccion: Seccion.vida,
            num: 7,
            titulo: 'Estudio bíblico de la congregación',
            min: 30),
      ],
    );
    final sched = construirFilas(semana, 18 * 60, 105);
    final bytes = await buildProgramPdf(
      cong: 'CONSTITUCIÓN J.A CASTRO',
      semana: semana,
      sched: sched,
    );

    expect(bytes.length, greaterThan(1000));
    // Cabecera de un PDF: "%PDF".
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });
}
