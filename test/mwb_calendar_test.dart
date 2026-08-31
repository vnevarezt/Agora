import 'package:flutter_test/flutter_test.dart';
import 'package:agora/domain/mwb_calendar.dart';

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
      expect(requiredIssues(DateTime(2026, 6, 14), monthsAhead: 2), [
        '202605',
        '202607',
      ]);
    });

    test('a single issue suffices when looking no months ahead', () {
      expect(requiredIssues(DateTime(2026, 5, 2), monthsAhead: 0), ['202605']);
    });

    test('rolls the year over at the end of December', () {
      expect(requiredIssues(DateTime(2026, 12, 20), monthsAhead: 2), [
        '202611',
        '202701',
      ]);
    });

    // El anclaje es SIEMPRE la fecha actual: si desde hoy el cuaderno en caché
    // solo cubre ~1 mes (o menos), el siguiente ya entra como "necesario".
    test('cuando desde hoy solo queda ~1 mes, exige el siguiente cuaderno', () {
      // 1 de junio: 202605 termina el 1 de julio (1 mes por delante) -> baja el siguiente.
      expect(requiredIssues(DateTime(2026, 6, 1), monthsAhead: 2), [
        '202605',
        '202607',
      ]);
      // Últimos días del periodo: queda < 1 mes -> también exige el siguiente.
      expect(requiredIssues(DateTime(2026, 6, 28), monthsAhead: 2), [
        '202605',
        '202607',
      ]);
    });

    // Un cuaderno cacheado totalmente en el pasado no cuenta como cobertura:
    // requiredIssues mira desde hoy, así que pedirá el actual + el siguiente.
    test('ignora cobertura pasada y pide desde la fecha actual', () {
      expect(requiredIssues(DateTime(2026, 7, 1), monthsAhead: 2), [
        '202607',
        '202609',
      ]);
    });
  });

  group('labelForIssue', () {
    const es = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', //
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June', //
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    test('is human readable', () {
      expect(labelForIssue('202605', es), 'Mayo–Junio 2026');
      expect(labelForIssue('202611', es), 'Noviembre–Diciembre 2026');
      expect(labelForIssue('202701', es), 'Enero–Febrero 2027');
    });

    test('follows the month names it is given', () {
      expect(labelForIssue('202605', en), 'May–June 2026');
      expect(labelForIssue('202611', en), 'November–December 2026');
      expect(labelForIssue('202701', en), 'January–February 2027');
    });
  });

  test('issueMonth / issueYear expose the period', () {
    expect(issueMonth('202605'), 5);
    expect(issueYear('202605'), 2026);
    expect(issueMonth('202701'), 1);
    expect(issueYear('202701'), 2027);
  });

  group('weekStartFor', () {
    test('both languages of one week resolve to the same Monday', () {
      // The fixtures: 'JULY 6-12' and '6-12 DE JULIO'. Different words, same
      // leading digit — which is the whole point.
      expect(weekStartFor('202607', 6), '2026-07-06');
    });

    test('a week spanning two months lands on its own Monday', () {
      // '29 DE JUNIO A 5 DE JULIO' / 'JUNE 29-JULY 5'.
      expect(weekStartFor('202605', 29), '2026-06-29');
    });

    test('a workbook may open before its own period', () {
      // 202605 covers May-June, but its first week starts 27 April.
      expect(weekStartFor('202605', 27), '2026-04-27');
    });

    test('the period wins over the margin when both hold a candidate', () {
      // February 2026 has 28 days, so 2 February and 2 March are BOTH Mondays
      // and both fall inside a Jan-Feb issue widened by a week. Only the
      // period tells them apart, which is why it is searched first.
      expect(weekStartFor('202601', 2), '2026-02-02');
      // And the March one is the Mar-Apr issue's, resolved from its own period.
      expect(weekStartFor('202603', 2), '2026-03-02');
    });

    test('crosses the year boundary', () {
      expect(weekStartFor('202511', 29), '2025-12-29');
      expect(weekStartFor('202601', 5), '2026-01-05');
    });

    test('a previous week turns the search into an equality check', () {
      expect(weekStartFor('202607', 13, previous: '2026-07-06'), '2026-07-13');
      expect(weekStartFor('202607', 20, previous: '2026-07-13'), '2026-07-20');
    });

    test('a heading that does not fit is rejected, never guessed', () {
      // Day 7 of a week following 2026-07-06 would have to be 2026-07-13.
      expect(weekStartFor('202607', 7, previous: '2026-07-06'), isNull);
      // No Monday in or around Jul-Aug 2026 falls on a 9th.
      expect(weekStartFor('202607', 9), isNull);
    });
  });

  group('issuesForWeekStart', () {
    test('offers the week\'s own issue first', () {
      expect(issuesForWeekStart('2026-07-06').first, '202607');
    });

    test('offers the next issue too, for a workbook opening early', () {
      // 2026-04-27 reads as 202603 by date, but it opens the 202605 workbook.
      expect(issuesForWeekStart('2026-04-27'), ['202603', '202605']);
    });

    test('malformed input yields nothing rather than a wrong issue', () {
      expect(issuesForWeekStart('7-13 DE JULIO'), isEmpty);
    });
  });
}
