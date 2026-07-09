import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/domain/schedule_rules.dart';
import 'package:jw_program/models/week.dart';

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
  group('buildSchedule – circuit overseer visit', () {
    test('por defecto el EBC es Conductor/Lector con 2 cupos', () {
      final s = buildSchedule(_week(), 18 * 60, 105);
      final cbs = s.christianLife
          .firstWhere((r) => r.content.contains('Estudio bíblico'));
      expect(cbs.slots, 2);
      expect(cbs.role, 'Conductor/Lector:');
    });

    test('con visita: el EBC se reemplaza por el discurso del orador (1 cupo)',
        () {
      final base = buildSchedule(_week(), 18 * 60, 105);
      final visit =
          buildSchedule(_week(), 18 * 60, 105, circuitOverseer: true);

      final talk = visit.christianLife
          .firstWhere((r) => r.content.contains(circuitOverseerTalkTitle));
      expect(talk.slots, 1);
      expect(talk.role, 'Orador:');
      expect(visit.christianLife.any((r) => r.content.contains('Estudio bíblico')),
          isFalse);

      // The replacement keeps the row id, so the assignment is preserved.
      final cbsId = base.christianLife
          .firstWhere((r) => r.content.contains('Estudio bíblico'))
          .id;
      expect(talk.id, cbsId);
    });

    test('con visita: desaparecen las "Palabras de conclusión"', () {
      final base = buildSchedule(_week(), 18 * 60, 105);
      final visit =
          buildSchedule(_week(), 18 * 60, 105, circuitOverseer: true);

      expect(
          base.christianLife.any((r) => r.content.contains('Palabras de conclusión')),
          isTrue);
      expect(
          visit.christianLife.any((r) => r.content.contains('Palabras de conclusión')),
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
          s.christianLife.firstWhere((r) => r.role == 'Orador:').id;

      final out = applyTitleOverrides(s, {talkId: 'Confía en Jehová'});
      final talk = out.christianLife.firstWhere((r) => r.id == talkId);
      expect(talk.content, 'Confía en Jehová (30 mins.)');
    });
  });
}
