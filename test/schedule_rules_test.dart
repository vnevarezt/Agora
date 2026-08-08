import 'package:agora/domain/schedule_rules.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/program_row.dart';
import 'package:agora/models/week.dart';
import 'package:flutter_test/flutter_test.dart';

Week _week() => Week(
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

void main() {
  final es = AppLocale.es.buildSync();
  final en = AppLocale.en.buildSync();

  group('buildSchedule – circuit overseer visit', () {
    test('por defecto el EBC es Conductor/Lector con 2 cupos', () {
      final s = buildSchedule(_week(), 18 * 60, 105);
      final cbs = s.christianLife
          .firstWhere((r) => r.title.contains('Estudio bíblico'));
      expect(cbs.slots, 2);
      expect(cbs.role, SlotRole.conductorReader);
    });

    test('con visita: el EBC se reemplaza por el discurso del orador (1 cupo)',
        () {
      final base = buildSchedule(_week(), 18 * 60, 105);
      final visit =
          buildSchedule(_week(), 18 * 60, 105, circuitOverseer: true);

      final talk = visit.christianLife
          .firstWhere((r) => r.kind == RowKind.circuitOverseerTalk);
      expect(talk.slots, 1);
      expect(talk.role, SlotRole.speaker);
      expect(
          visit.christianLife.any((r) => r.title.contains('Estudio bíblico')),
          isFalse);

      // The replacement keeps the row id, so the assignment is preserved.
      final cbsId = base.christianLife
          .firstWhere((r) => r.title.contains('Estudio bíblico'))
          .id;
      expect(talk.id, cbsId);
    });

    test('con visita: desaparecen las "Palabras de conclusión"', () {
      final base = buildSchedule(_week(), 18 * 60, 105);
      final visit =
          buildSchedule(_week(), 18 * 60, 105, circuitOverseer: true);

      expect(base.christianLife.any((r) => r.kind == RowKind.closingWords),
          isTrue);
      expect(visit.christianLife.any((r) => r.kind == RowKind.closingWords),
          isFalse);
    });
  });

  group('applyTitleOverrides', () {
    test('sin overrides devuelve el mismo schedule', () {
      final s = buildSchedule(_week(), 18 * 60, 105);
      expect(identical(applyTitleOverrides(s, const {}), s), isTrue);
    });

    test('reemplaza el título conservando el sufijo de minutos', () {
      final s = buildSchedule(_week(), 18 * 60, 105, circuitOverseer: true);
      final talkId =
          s.christianLife.firstWhere((r) => r.role == SlotRole.speaker).id;

      final out = applyTitleOverrides(s, {talkId: 'Confía en Jehová'});
      final talk = out.christianLife.firstWhere((r) => r.id == talkId);
      expect(talk.content(es), 'Confía en Jehová (30 mins.)');
    });
  });

  group('rendering follows the language it is given', () {
    // The point of RowKind/SlotRole: the schedule is computed once and rendered
    // per language, so the UI can show one language while the PDF prints
    // another. Workbook part titles stay untranslated on purpose.
    final s = buildSchedule(_week(), 18 * 60, 105);

    test('generated rows are localized', () {
      final song = s.opening.firstWhere((r) => r.kind == RowKind.song);
      expect(song.content(es), 'Canción 44');
      expect(song.content(en), 'Song 44');

      final opening =
          s.opening.firstWhere((r) => r.kind == RowKind.openingWords);
      expect(opening.content(es), 'Palabras de introducción (1 min.)');
      expect(opening.content(en), 'Opening Comments (1 min.)');
    });

    test('role prefixes are localized', () {
      expect(SlotRole.studentAssistant.label(es), 'Estudiante/Ayudante:');
      expect(SlotRole.studentAssistant.label(en), 'Student/Assistant:');
      expect(SlotRole.none.label(es), '');
    });

    test('workbook part titles are NOT translated', () {
      final part = s.treasures.firstWhere((r) => r.kind == RowKind.part);
      expect(part.content(es), part.content(en));
    });

    test('a part keeps its "(N mins.)" suffix', () {
      final cbs = s.christianLife
          .firstWhere((r) => r.title.contains('Estudio bíblico'));
      expect(cbs.content(es), endsWith(' (30 mins.)'));
    });
  });
}
