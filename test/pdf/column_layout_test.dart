// How the width of a sheet is shared out between the titles and the names.
//
// The title cell is an Expanded, so before this it swallowed every point no
// other column claimed: a sheet of short titles printed a blank strip down its
// middle while the pair of names beside it stacked onto two lines for want of
// six. The titles are measured now, and what they do not need is offered to
// the names first.

import 'package:agora/domain/schedule_rules.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/program_row.dart';
import 'package:agora/models/week.dart';
import 'package:agora/pdf/column_layout.dart';
import 'package:agora/pdf/pdf_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _m = S140Metrics.standard;
final _tr = AppLocale.es.buildSync();

/// A week whose ministry demonstration carries [title] and the pair of names.
/// That row is where the two pressures meet: it prints a role label, so its
/// title cannot spread sideways, and the names it competes with are its own.
///
/// [talkTitle] goes on a Treasures part, which prints no role label — the row
/// that CAN spread.
Week _week({required String title, String talkTitle = 'El Alfarero'}) => Week(
  date: '31 DE AGOSTO A 6 DE SEPTIEMBRE',
  reading: 'JEREMÍAS 31',
  openingSong: '27',
  closingSong: '132',
  parts: [
    Part(section: Section.treasures, number: 1, title: talkTitle, minutes: 10),
    Part(
      section: Section.treasures,
      number: 2,
      title: 'Lectura de la Biblia',
      minutes: 4,
    ),
    Part(section: Section.ministry, number: 3, title: title, minutes: 3),
    Part(
      section: Section.christianLife,
      number: 4,
      title: 'Estudio bíblico de la congregación',
      minutes: 30,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfFont carlito;
  late PdfFont carlitoBold;
  late double Function(String) measure;

  setUpAll(() async {
    final doc = pw.Document();
    final ctx = pw.Context(document: doc.document);
    final bytes = await carlitoFontBytes();
    carlito = pw.Font.ttf(bytes.regular).getFont(ctx);
    carlitoBold = pw.Font.ttf(bytes.bold).getFont(ctx);
    measure = (s) => carlito.stringMetrics(s).advanceWidth * _m.base;
  });

  /// The layout of one sheet: its column widths, plus the pair that is the
  /// whole point of the exercise.
  ({ColumnWidths cols, bool pairStacks}) layout(
    String title,
    List<String> pair, {
    String talkTitle = 'El Alfarero',
    bool auxRoom = false,
    List<String> aux = const [],
  }) {
    final schedule = buildSchedule(
      _week(title: title, talkTitle: talkTitle),
      18 * 60,
      105,
    );
    final assignments = Assignments({
      schedule.ministry.first.id: pair,
    }, aux.isEmpty ? const {} : {schedule.ministry.first.id: aux});
    final cols = computeColumns(
      _m,
      _tr,
      schedule,
      assignments,
      carlito,
      carlitoBold,
      auxRoom,
    );
    final lines = nameLines(
      SlotRole.studentAssistant,
      pair,
      cols.mainNames,
      measure,
    );
    return (cols: cols, pairStacks: lines.stacked);
  }

  // 145 pt joined: wider than the official 5 cm column (142 pt) and narrower
  // than what short titles leave over. Exactly the band where the old widths
  // stacked a pair that had room to spare beside it.
  const pair = ['Vicente Nevárez', 'Luis Javier Vargas'];
  const shortTitle = 'Empiece conversaciones';
  const longTitle =
      'Empiece conversaciones cuando la gente no quiera escuchar el mensaje';

  test('a pair keeps its line when the titles leave room for it', () {
    final wide = layout(shortTitle, pair);

    expect(wide.pairStacks, isFalse);
    expect(wide.cols.mainNames, greaterThan(measure(joinedNames(pair))));
  });

  test('the names give the width back when the titles need it', () {
    final wide = layout(shortTitle, pair);
    final tight = layout(longTitle, pair);

    expect(tight.cols.mainNames, lessThan(wide.cols.mainNames));
    expect(
      tight.cols.mainNames,
      greaterThanOrEqualTo(_m.minNamesCol),
      reason: 'a column that narrow has stopped being a column',
    );
  });

  test('the titles never take the names below their own wrapped width', () {
    final tight = layout(longTitle, pair);

    // Squeezed to the point of stacking, the column still has to hold the
    // longer of the two names — stacking is a line break, not an ellipsis.
    expect(
      tight.cols.mainNames,
      greaterThanOrEqualTo(measure('Luis Javier Vargas')),
    );
  });

  test('the titles keep their official floor whatever the names ask for', () {
    final huge = layout(shortTitle, const [
      'Maximiliano de la Concepción',
      'Bartolomea Buenaventura',
    ]);
    final content = huge.cols.band - _m.colGap - huge.cols.role;

    expect(content, greaterThanOrEqualTo(_m.minContentFrac * _m.contentWidth));
  });

  test('a title with no role label beside it spreads instead of squeezing', () {
    // A Treasures talk prints no "Estudiante:" label, so the column reserved
    // for one is blank on that row and the title runs straight through it.
    // Nothing moves — the space was already white — but the names keep every
    // point they had.
    final plain = layout(shortTitle, pair);
    final wordy = layout(shortTitle, pair, talkTitle: longTitle);

    expect(wordy.cols.mainNames, plain.cols.mainNames);
    expect(wordy.pairStacks, isFalse);
    expect(
      wordy.cols.titleBreaks,
      0,
      reason: 'the row had a whole empty column to grow into',
    );
  });

  test('a week with nobody in the auxiliary room prints no column for it', () {
    // The setting is per project, the column is per week: reserving one for a
    // week with nothing in it costs the same points on every row and prints a
    // strip of white.
    final empty = layout(shortTitle, pair, auxRoom: true);
    final used = layout(
      shortTitle,
      pair,
      auxRoom: true,
      aux: const ['Ana', 'Eva'],
    );

    expect(empty.cols.auxRoom, 0);
    expect(used.cols.auxRoom, greaterThan(0));
    expect(empty.cols.mainNames, greaterThanOrEqualTo(used.cols.mainNames));
  });

  test('a stacked pair counts as a broken line, same as a wrapped title', () {
    final wide = layout(shortTitle, pair);
    final tight = layout(longTitle, pair);

    expect(wide.cols.titleBreaks + wide.cols.nameBreaks, 0);
    expect(
      tight.cols.nameBreaks,
      greaterThan(0),
      reason:
          'the fit has to see the stacked pair, or it will happily '
          'trade a wrapped title for one and call the sheet improved',
    );
  });
}
