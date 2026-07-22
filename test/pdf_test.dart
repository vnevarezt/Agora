// Verifica que el render del PDF carga las fuentes Carlito y produce un PDF
// válido (sin red ni GUI).

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/domain/schedule_rules.dart';
import 'package:jw_program/models/program_row.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/pdf/program_document.dart';

Week _sampleWeek(String date) => Week(
      date: date,
      reading: 'ISAÍAS 62-64',
      openingSong: '44',
      parts: const [
        Part(
            section: Section.treasures,
            number: 1,
            title: 'El Alfarero',
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
            section: Section.christianLife,
            number: 7,
            title: 'Estudio bíblico de la congregación',
            minutes: 30),
      ],
    );

WeekEntry _entry(Week week) {
  final schedule = buildSchedule(week, 18 * 60, 105);
  return (
    week: week,
    schedule: schedule,
    // Nombres por id de fila (la primera de Tesoros lleva uno de ejemplo).
    assignments:
        Assignments({schedule.treasures.first.id: const ['Rafael G']}, {}),
    chairman: 'Rafael G',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildProgramPdf genera un PDF válido', () async {
    final week = _sampleWeek('18-24 DE MAYO');
    final schedule = buildSchedule(week, 18 * 60, 105);
    final asg =
        Assignments({schedule.treasures.first.id: const ['Rafael G']}, {});
    final bytes = await buildProgramPdf(
      congregation: 'CONSTITUCIÓN J.A CASTRO',
      week: week,
      schedule: schedule,
      assignments: asg,
      chairman: 'Rafael G',
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });

  test('buildProgramSheetPdf con dos semanas (2-up) genera un PDF válido',
      () async {
    final bytes = await buildProgramSheetPdf(
      congregation: 'CONSTITUCIÓN J.A CASTRO',
      entries: [
        _entry(_sampleWeek('18-24 DE MAYO')),
        _entry(_sampleWeek('25-31 DE MAYO')),
      ],
      twoPerSheet: true,
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });

  test('2-up con una sola entrada (última hoja impar) sigue siendo válido',
      () async {
    final bytes = await buildProgramSheetPdf(
      congregation: 'CONSTITUCIÓN J.A CASTRO',
      entries: [_entry(_sampleWeek('1-7 DE JUNIO'))],
      twoPerSheet: true,
    );

    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });
}
