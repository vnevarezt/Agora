import 'dart:math' as math;

import 'package:pdf/pdf.dart';

import '../i18n/strings.g.dart';
import '../models/program_row.dart';
import 'pdf_theme.dart';

/// Column widths computed per document. The content cell (X) is implicit
/// (Expanded), so we only store role, auxRoom, names and band widths.
class ColumnWidths {
  /// Time column, measured from the times actually printed.
  final double hour;
  final double role;
  final double mainNames;
  final double auxRoom; // 0 when Auxiliary Room mode is off
  final double band;

  /// Cells that spill onto a second line at these widths, counted apart
  /// because the fit treats them differently: a wrapped title is ordinary —
  /// the official form wraps them too — while a stacked pair of names is the
  /// crowding this whole layout exists to undo. Kept as two numbers so the
  /// columns can never trade one for the other and call it an improvement.
  /// See [fitSheet].
  final int titleBreaks;
  final int nameBreaks;

  const ColumnWidths({
    required this.hour,
    required this.role,
    required this.mainNames,
    required this.auxRoom,
    required this.band,
    required this.titleBreaks,
    required this.nameBreaks,
  });
}

/// What a column has to be to print its content: [want] keeps every cell on one
/// line, [floor] is the narrowest it can get before the text wraps on its own.
///
/// The two differ only for the student/assistant pair, which has a legible
/// two-line form ([nameLines]) and so can be squeezed to the longer of the two
/// names. Everything else wants and needs the same width.
typedef ColumnNeed = ({double want, double floor});

/// Width a row's names column needs, both ways round.
ColumnNeed namesNeed(
  SlotRole role,
  List<String> names,
  double Function(String) measure,
) {
  if (names.isEmpty) return (want: 0, floor: 0);
  final joined = measure(joinedNames(names));
  if (role.isStudentPair && names.length == 2) {
    final a = measure(names[0]);
    final b = measure(names[1]);
    return (want: joined, floor: a > b ? a : b);
  }
  return (want: joined, floor: joined);
}

/// How a slot's names are laid out in the names column: one line when the
/// joined form fits, otherwise one name per line.
///
/// The order is the same either way, and that is the whole point of this being
/// one function. It has to match [joinedNames] and the role label the cell sits
/// next to ("Estudiante/Ayudante:"), so the student comes first. The renderer
/// used to decide this inline with hand-written indices and had them backwards
/// in the stacked branch, so a pair read one way when it fitted on a line and
/// the other way when it did not — which two-per-sheet, with its narrow names
/// column, hit almost every time.
({List<String> lines, bool stacked}) nameLines(
  SlotRole role,
  List<String> names,
  double width,
  double Function(String) measure,
) {
  final joined = joinedNames(names);
  if (role.isStudentPair && names.length == 2 && measure(joined) > width) {
    return (lines: names, stacked: true);
  }
  return (lines: [joined], stacked: false);
}

/// What a row's title needs, and how many of the columns to its right it may
/// spread into because that row leaves them empty.
typedef _TitleNeed = ({double need, int borrow});

/// How many columns to the right of the title cell a row leaves empty, counted
/// outward and stopping at the first one that has something in it.
///
/// The title cell is an [Expanded] in a fixed-width row, so dropping an empty
/// column hands its width to the title and moves NOTHING: every column after
/// it keeps its place. Stopping at the first occupied column is what makes
/// that true — drop a column that still has a neighbour printing to its left
/// and the neighbour slides across, out of line with the rest of the sheet.
int borrowedColumns({
  required bool hasRole,
  required bool hasAux,
  required bool auxRoom,
}) {
  if (hasRole) return 0;
  if (auxRoom && hasAux) return 1;
  return auxRoom ? 2 : 1;
}

double _extra(S140Metrics m, int borrow, double role, double auxNames) =>
    switch (borrow) {
      0 => 0,
      1 => m.colGap + role,
      _ => m.colGap + role + m.colGap + auxNames,
    };

/// Computes the widths adaptively from the real content of the sheet.
///
/// The title cell is [Expanded], so it silently swallows every point no other
/// column claimed — which is why a sheet of short titles printed a blank strip
/// down its middle while the names beside it stacked onto two lines. So the
/// titles are measured too: whatever they do not need is offered to the names
/// first, and only the remainder falls through to the title cell.
///
/// The names ask for their one-line width and give ground down to their
/// wrapped width when the titles genuinely need the room; the official floors
/// ([S140Metrics.mainNameWidth], [S140Metrics.minContentFrac]) bound both ends,
/// so a contended sheet lands exactly where it always did.
ColumnWidths computeColumns(
  S140Metrics m,
  Translations tr,
  ProgramSchedule sched,
  Assignments assignments,
  PdfFont regular,
  PdfFont bold,
  bool auxRoom,
) {
  double measure(String s) => regular.stringMetrics(s).advanceWidth * m.base;
  // The times are set bold and one size down, and a bulleted row prints a
  // dot after them; [S140.hourWidth] never lets the column be narrower than
  // that needs, and no wider.
  double time(String s) => bold.stringMetrics(s).advanceWidth * m.small;
  final bullet = measure('•') * m.small / m.base;
  final hour = math.min(
    m.hourWidth,
    sched.rows.map((f) => time(f.time)).reduce(math.max) +
        bullet +
        2 * S140.fboxsep,
  );
  final role = m.roleWidth; // fixed (role labels, not user input)
  // Per row, so the widths can be chosen from the totals and then scored
  // against every individual cell.
  final titles = <_TitleNeed>[];
  final mainWants = <double>[];
  final auxWants = <double>[];
  var main = (want: 0.0, floor: 0.0);
  var aux = (want: 0.0, floor: 0.0);
  ColumnNeed widen(ColumnNeed a, ColumnNeed b) =>
      (want: math.max(a.want, b.want), floor: math.max(a.floor, b.floor));
  for (final f in sched.rows) {
    final mn = namesNeed(f.role, assignments.main(f), measure);
    mainWants.add(mn.want);
    main = widen(main, mn);
    var auxWant = 0.0;
    if (auxRoom) {
      final an = namesNeed(f.role, assignments.auxiliary(f), measure);
      auxWant = an.want;
      auxWants.add(an.want);
      aux = widen(aux, an);
    }
    titles.add((
      need: hour + measure(f.content(tr)) + m.namePad,
      borrow: borrowedColumns(
        hasRole: f.role.label(tr).isNotEmpty,
        hasAux: auxWant > 0,
        auxRoom: auxRoom,
      ),
    ));
  }
  // The title of a row that claims no role column can spread into it, so the
  // width it asks of the CONTENT column is that much less. Rows that borrow
  // the auxiliary column too are counted as borrowing only the role column
  // here: its width is still being decided below, and asking for less than
  // the row will actually have is the safe way round.
  final titleWant = titles.isEmpty
      ? 0.0
      : titles
            .map((t) => t.need - (t.borrow > 0 ? m.colGap + role : 0))
            .reduce(math.max);
  int over(List<double> needs, double width) =>
      needs.where((w) => w > width).length;
  int wrapped(double content, double auxNames) => titles
      .where((t) => t.need > content + _extra(m, t.borrow, role, auxNames))
      .length;
  // A week with nothing in the auxiliary room does not print a column for it.
  // Reserving one costs the same 60-odd points on every row of that week and
  // buys a strip of white; the sheet is a record of who does what, not a
  // diagram of the hall.
  final showsAux = auxRoom && aux.want > 0;
  final gaps = (showsAux ? 3 : 2) * m.colGap;
  final avail = m.contentWidth - gaps - role;

  if (!showsAux) {
    // The official 5 cm is where the column RESTS, not a floor: holding it
    // there while the titles beside it wrap would be honouring the form's
    // measurements over the thing they exist to keep readable.
    final floor = math.max(main.floor + m.namePad, m.minNamesCol);
    final ceiling = math.max(
      floor,
      math.min(avail - m.minContentFrac * m.contentWidth, avail - titleWant),
    );
    final want = math.max(main.want + m.namePad, m.mainNameWidth);
    final mainNames = want.clamp(floor, ceiling).toDouble();
    final content = avail - mainNames;
    return ColumnWidths(
      hour: hour,
      role: role,
      mainNames: mainNames,
      auxRoom: 0,
      band: content + m.colGap + role,
      titleBreaks: wrapped(content, 0),
      nameBreaks: over(mainWants, mainNames),
    );
  }

  // --- Auxiliary Room mode: 4 columns (X R A P), 3 gaps ---
  final mainFloor = math.max(main.floor + m.namePad, m.minNamesCol);
  final auxFloor = math.max(aux.floor + m.namePad, m.minNamesCol);
  final budget = math.max(
    mainFloor + auxFloor,
    math.min(avail - m.minContentAuxFrac * m.contentWidth, avail - titleWant),
  );
  var mainNames = main.want + m.namePad;
  var auxNames = aux.want + m.namePad;
  if (mainNames < mainFloor) mainNames = mainFloor;
  if (auxNames < auxFloor) auxNames = auxFloor;
  if (mainNames + auxNames > budget) {
    // Both columns give up the same fraction of what they asked for ABOVE
    // their floor, so the tighter one is not squeezed out of existence.
    final over = (mainNames - mainFloor) + (auxNames - auxFloor);
    final slack = budget - mainFloor - auxFloor;
    final keep = over > 0 ? (slack / over).clamp(0.0, 1.0) : 0.0;
    mainNames = mainFloor + (mainNames - mainFloor) * keep;
    auxNames = auxFloor + (auxNames - auxFloor) * keep;
  }
  final content = avail - mainNames - auxNames;
  return ColumnWidths(
    hour: hour,
    role: role,
    mainNames: mainNames,
    auxRoom: auxNames,
    band: content + m.colGap + role,
    titleBreaks: wrapped(content, auxNames),
    nameBreaks: over(mainWants, mainNames) + over(auxWants, auxNames),
  );
}
