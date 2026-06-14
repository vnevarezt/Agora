import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/domain/mwb_calendar.dart';

void main() {
  group('issueForDate', () {
    test('maps any month to its odd starting month', () {
      expect(issueForDate(DateTime(2026, 6, 14)), '202605');
      expect(issueForDate(DateTime(2026, 1, 1)), '202601');
      expect(issueForDate(DateTime(2026, 2, 28)), '202601');
      expect(issueForDate(DateTime(2026, 12, 31)), '202611');
    });
  });

  test('nextIssue / prevIssue roll the year over', () {
    expect(nextIssue('202605'), '202607');
    expect(nextIssue('202611'), '202701');
    expect(prevIssue('202701'), '202611');
    expect(prevIssue('202601'), '202511');
  });

  test('issueStart / issueEnd bound the two-month period', () {
    expect(issueStart('202605'), DateTime(2026, 5, 1));
    expect(issueEnd('202605'), DateTime(2026, 7, 1));
    expect(issueEnd('202611'), DateTime(2027, 1, 1));
  });

  group('requiredIssues', () {
    test('two months ahead keeps the current + next issue', () {
      expect(requiredIssues(DateTime(2026, 6, 14), monthsAhead: 2),
          ['202605', '202607']);
    });

    test('a single issue suffices when looking no months ahead', () {
      expect(requiredIssues(DateTime(2026, 5, 2), monthsAhead: 0), ['202605']);
    });

    test('rolls the year over at the end of December', () {
      expect(requiredIssues(DateTime(2026, 12, 20), monthsAhead: 2),
          ['202611', '202701']);
    });

    // El anclaje es SIEMPRE la fecha actual: si desde hoy el cuaderno en caché
    // solo cubre ~1 mes (o menos), el siguiente ya entra como "necesario".
    test('cuando desde hoy solo queda ~1 mes, exige el siguiente cuaderno', () {
      // 1 de junio: 202605 termina el 1 de julio (1 mes por delante) -> baja el siguiente.
      expect(requiredIssues(DateTime(2026, 6, 1), monthsAhead: 2),
          ['202605', '202607']);
      // Últimos días del periodo: queda < 1 mes -> también exige el siguiente.
      expect(requiredIssues(DateTime(2026, 6, 28), monthsAhead: 2),
          ['202605', '202607']);
    });

    // Un cuaderno cacheado totalmente en el pasado no cuenta como cobertura:
    // requiredIssues mira desde hoy, así que pedirá el actual + el siguiente.
    test('ignora cobertura pasada y pide desde la fecha actual', () {
      expect(requiredIssues(DateTime(2026, 7, 1), monthsAhead: 2),
          ['202607', '202609']);
    });
  });

  test('labelForIssue is human readable', () {
    expect(labelForIssue('202605'), 'Mayo–Junio 2026');
    expect(labelForIssue('202611'), 'Noviembre–Diciembre 2026');
    expect(labelForIssue('202701'), 'Enero–Febrero 2027');
  });
}
