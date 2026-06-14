// Verifica que el render del PDF carga las fuentes Carlito y produce un PDF
// válido (sin red ni GUI).

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/domain/schedule_rules.dart';
import 'package:jw_program/models/program_row.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/pdf/program_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildProgramPdf genera un PDF válido', () async {
    final semana = Week(
      date: '18-24 DE MAYO',
      reading: 'ISAÍAS 62-64',
      openingSong: '44',
      parts: const [
        Part(section: Section.treasures, number: 1, title: 'El Alfarero', minutes: 10),
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
            section: Section.christianLife,
            number: 7,
            title: 'Estudio bíblico de la congregación',
            minutes: 30),
      ],
    );
    final sched = buildSchedule(semana, 18 * 60, 105);
    // Nombres por id de fila (la primera de Tesoros lleva uno de ejemplo).
    final asg = Assignments({sched.treasures.first.id: const ['Rafael G']}, {});
    final bytes = await buildProgramPdf(
      cong: 'CONSTITUCIÓN J.A CASTRO',
      semana: semana,
      sched: sched,
      asignaciones: asg,
      chairman: 'Rafael G',
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });
}
