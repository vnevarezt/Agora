import 'dart:isolate';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/program_row.dart';
import '../models/week.dart';
import 'column_layout.dart';
import 'pdf_theme.dart';

/// One week's worth of data for the sheet: the structure ([schedule]/[week])
/// kept apart from the participant names ([assignments]) and the chairman.
/// Plain data — safe to send to the background isolate that renders the PDF.
typedef WeekEntry = ({
  Week week,
  ProgramSchedule schedule,
  Assignments assignments,
  String chairman,
});

/// Single-week PDF (one portrait Letter page), reproducing programa-vmc.tex
/// (S-140-S format). Kept for callers that still print one week; forwards to
/// [buildProgramSheetPdf].
Future<Uint8List> buildProgramPdf({
  required String congregation,
  required Week week,
  required ProgramSchedule schedule,
  Assignments assignments = Assignments.empty,
  String chairman = '',
  bool auxRoom = false,
}) {
  return buildProgramSheetPdf(
    congregation: congregation,
    entries: [
      (
        week: week,
        schedule: schedule,
        assignments: assignments,
        chairman: chairman
      )
    ],
    auxRoom: auxRoom,
    twoPerSheet: false,
  );
}

/// Generates the program PDF for one printed sheet. [twoPerSheet] = false is
/// the official one-week page; true stacks up to two week blocks on ONE
/// portrait page under a single shared header (congregation + title printed
/// once), using the compact metrics so the content reflows tighter instead of
/// being photo-reduced.
///
/// Layout, font subsetting and compression are ~100–300 ms of pure CPU on a
/// phone, so the document is built in a background isolate: only the font
/// bytes are loaded here (rootBundle needs the main isolate) and the models
/// are plain data, safe to send across.
Future<Uint8List> buildProgramSheetPdf({
  required String congregation,
  required List<WeekEntry> entries,
  bool auxRoom = false,
  bool twoPerSheet = false,
}) async {
  final fontBytes = await carlitoFontBytes();
  return Isolate.run(() => _buildPdf(
        fontBytes: fontBytes,
        congregation: congregation,
        entries: entries,
        auxRoom: auxRoom,
        twoPerSheet: twoPerSheet,
      ));
}

Future<Uint8List> _buildPdf({
  required CarlitoBytes fontBytes,
  required String congregation,
  required List<WeekEntry> entries,
  required bool auxRoom,
  required bool twoPerSheet,
}) async {
  final carlito = carlitoFromBytes(fontBytes);
  final doc = pw.Document();
  if (twoPerSheet) {
    _addStackedPage(doc, carlito, congregation, entries, auxRoom);
  } else {
    _addSinglePage(doc, carlito, congregation, entries.first, auxRoom);
  }
  return doc.save();
}

/// Shared page header: congregation + title + the thin/thick rule. Printed
/// ONCE per sheet (also in two-per-sheet mode, per the pinned-board original).
List<pw.Widget> _headerBlock(S140Metrics m, String congregation) => [
      _header(m, congregation),
      pw.SizedBox(height: m.gapHeaderRule),
      _thinThickRule(m),
    ];

/// One week's block: week line (date/reading/chairman) + the four sections +
/// closing rule. No page header — see [_headerBlock].
List<pw.Widget> _weekBlock(pw.Context ctx, Carlito carlito, S140Metrics m,
    WeekEntry e, bool auxRoom) {
  // Adaptive widths based on the real content (getFont needs the ctx).
  final regularFont = carlito.regular.getFont(ctx);
  final cols = computeColumns(m, e.schedule, e.assignments, regularFont, auxRoom);
  double measure(String s) =>
      regularFont.stringMetrics(s).advanceWidth * m.base;
  return [
    _weekLine(m, e.week, e.chairman),
    pw.SizedBox(height: m.gapAfterWeekLine),
    if (auxRoom) ...[_roomsHeader(m, cols), pw.SizedBox(height: 2)],
    _table(m, e.schedule.opening, e.assignments, cols, measure, auxRoom),
    _band(m, S140.treasures, 'TESOROS DE LA BIBLIA', 'Auditorio principal',
        cols, auxRoom),
    _table(m, e.schedule.treasures, e.assignments, cols, measure, auxRoom),
    _band(m, S140.ministryColor, 'SEAMOS MEJORES MAESTROS',
        'Auditorio principal', cols, auxRoom),
    _table(m, e.schedule.ministry, e.assignments, cols, measure, auxRoom),
    _band(m, S140.christianLife, 'NUESTRA VIDA CRISTIANA', '', cols, auxRoom),
    _table(m, e.schedule.christianLife, e.assignments, cols, measure, auxRoom),
    pw.SizedBox(height: m.gapSectionEnd),
    _thinThickRule(m),
  ];
}

pw.Widget _footer(S140Metrics m) => pw.Text('S-140-S    11/23',
    style: pw.TextStyle(fontSize: m.footnote));

void _addSinglePage(pw.Document doc, Carlito carlito, String congregation,
    WeekEntry entry, bool auxRoom) {
  const m = S140Metrics.standard;
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        theme: carlito.theme,
        pageFormat: const PdfPageFormat(
          S140.pageWidth,
          S140.pageHeight,
          marginTop: S140.marginTop,
          marginBottom: S140.marginBottom,
          marginLeft: S140.marginLeft,
          marginRight: S140.marginRight,
        ),
      ),
      // Footer on every page: "S-140-S   11/23" (tex:40).
      footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerLeft, child: _footer(m)),
      build: (ctx) => [
        ..._headerBlock(m, congregation),
        pw.SizedBox(height: m.gapAfterRule), // \par\smallskip
        ..._weekBlock(ctx, carlito, m, entry, auxRoom),
      ],
    ),
  );
}

/// Portrait Letter with 1–2 week blocks stacked under ONE shared header, in
/// compact metrics (the pinned-board layout). The content is laid out at the
/// page's real width — titles and names reflow to use the space — and a
/// [pw.BoxFit.scaleDown] wrapper shrinks it uniformly ONLY if an unusually
/// tall program would overflow the sheet.
void _addStackedPage(pw.Document doc, Carlito carlito, String congregation,
    List<WeekEntry> entries, bool auxRoom) {
  const m = S140Metrics.compact;
  doc.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(
        theme: carlito.theme,
        pageFormat: const PdfPageFormat(
          S140.pageWidth,
          S140.pageHeight,
          marginTop: S140.stackedMarginV,
          marginBottom: S140.stackedMarginV,
          marginLeft: S140.stackedMarginH,
          marginRight: S140.stackedMarginH,
        ),
      ),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              // Centered so a scaled-down heavy week keeps symmetric margins.
              alignment: pw.Alignment.topCenter,
              child: pw.SizedBox(
                width: m.contentWidth,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    ..._headerBlock(m, congregation),
                    pw.SizedBox(height: m.gapAfterRule),
                    ..._weekBlock(ctx, carlito, m, entries[0], auxRoom),
                    if (entries.length > 1) ...[
                      pw.SizedBox(height: S140.stackedWeekGap),
                      ..._weekBlock(ctx, carlito, m, entries[1], auxRoom),
                    ],
                  ],
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 3),
          _footer(m),
        ],
      ),
    ),
  );
}

// ---- Header: congregation (left) and title (right) (tex:171-178) ----
pw.Widget _header(S140Metrics m, String congregation) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end, // minipages [b]
    children: [
      pw.SizedBox(
        width: 0.34 * m.contentWidth,
        child: pw.Text(congregation,
            style: pw.TextStyle(
                fontSize: m.large, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Spacer(), // \hfill
      pw.SizedBox(
        width: 0.64 * m.contentWidth,
        child: pw.Text(
          'Programa para la reunión de entre semana',
          textAlign: pw.TextAlign.right,
          style:
              pw.TextStyle(fontSize: m.title, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

// ---- Thin + thick rule (tex:161-163) ----
pw.Widget _thinThickRule(S140Metrics m) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(width: m.contentWidth, height: 0.4, color: S140.lineColor),
      pw.SizedBox(height: 1.2),
      pw.Container(width: m.contentWidth, height: 1.6, color: S140.lineColor),
    ],
  );
}

// ---- Week line + chairman + reading (tex:183-187) ----
pw.Widget _weekLine(S140Metrics m, Week week, String chairman) {
  final weekStyle =
      pw.TextStyle(fontSize: m.week, fontWeight: pw.FontWeight.bold);
  final roleStyle = pw.TextStyle(
      fontSize: m.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.labelColor);
  final chairmanCell = [
    pw.Text('Presidente: ', style: roleStyle),
    pw.Text(chairman, style: pw.TextStyle(fontSize: m.week)),
  ];
  if (m.inlineWeekLine) {
    // Compact sheets: date + reading merged on one line.
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Text(
              '${week.date}   |   LECTURA SEMANAL DE LA BIBLIA:  ${week.reading}',
              style: weekStyle),
        ),
        ...chairmanCell,
      ],
    );
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Text('${week.date}   |   LECTURA SEMANAL DE LA BIBLIA',
                style: weekStyle),
          ),
          ...chairmanCell,
        ],
      ),
      pw.Text(week.reading, style: weekStyle),
    ],
  );
}

// ---- Single rooms header (tex:150-155, auxRoom mode only) ----
pw.Widget _roomsHeader(S140Metrics m, ColumnWidths cols) {
  final st = pw.TextStyle(
      fontSize: m.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.labelColor);
  return pw.Row(
    children: [
      pw.Expanded(child: pw.SizedBox()), // title + role area
      pw.SizedBox(width: m.colGap),
      pw.SizedBox(width: cols.auxRoom, child: pw.Text('Sala Auxiliar', style: st)),
      pw.SizedBox(width: m.colGap),
      pw.SizedBox(
          width: cols.mainNames, child: pw.Text('Auditorio principal', style: st)),
    ],
  );
}

// ---- Section band (tex:135-145) ----
pw.Widget _band(S140Metrics m, PdfColor color, String title, String labelText,
    ColumnWidths cols, bool auxRoom) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: m.bandGapTop),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            // Reaches the right edge of the role labels.
            width: cols.band,
            color: color,
            padding: pw.EdgeInsets.all(m.fboxsep),
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: m.base,
                    fontWeight: pw.FontWeight.bold,
                    color: S140.white)),
          ),
          pw.Spacer(), // \hfill
          // In auxRoom mode the label goes once in the rooms header.
          if (!auxRoom && labelText.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2), // \raisebox{2pt}
              child: pw.Text(labelText,
                  style: pw.TextStyle(
                      fontSize: m.footnote,
                      fontWeight: pw.FontWeight.bold,
                      color: S140.labelColor)),
            ),
        ],
      ),
      pw.SizedBox(height: m.bandGapBottom),
    ],
  );
}

// ---- Rows table (tabularx @{}X R P@{} or @{}X R A P@{} in auxRoom) ----
pw.Widget _table(S140Metrics m, List<ProgramRow> rows, Assignments assignments,
    ColumnWidths cols, double Function(String) measure, bool auxRoom) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final f in rows) _row(m, f, assignments, cols, measure, auxRoom)
    ],
  );
}

// Names cell (Main Hall or Auxiliary Room). Ministry rule: if the
// Estudiante/Ayudante pair doesn't fit on one line, it ALWAYS stacks: line 1
// Assistant, line 2 Student. Returns the widget and whether it stacked.
({pw.Widget widget, bool stacked}) _namesCell(String role,
    List<String> names, double width, double Function(String) measure,
    pw.TextStyle style) {
  final joined = joinedNames(names);
  final isStudentAssistant = role == 'Estudiante/Ayudante:' && names.length == 2;
  if (isStudentAssistant && measure(joined) > width) {
    return (
      widget: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(names[1],
              textAlign: pw.TextAlign.right, style: style), // Assistant
          pw.Text(names[0],
              textAlign: pw.TextAlign.right, style: style), // Student
        ],
      ),
      stacked: true,
    );
  }
  return (
    widget: pw.Text(joined, textAlign: pw.TextAlign.right, style: style),
    stacked: false,
  );
}

pw.Widget _row(S140Metrics m, ProgramRow r, Assignments assignments,
    ColumnWidths cols, double Function(String) measure, bool auxRoom) {
  final timeStyle = pw.TextStyle(
      fontSize: m.small,
      fontWeight: pw.FontWeight.bold,
      color: S140.labelColor);
  final roleStyle = pw.TextStyle(
      fontSize: m.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.labelColor);
  final nameStyle = pw.TextStyle(fontSize: m.base);

  final main =
      _namesCell(r.role, assignments.main(r), cols.mainNames, measure, nameStyle);
  final auxCell = auxRoom
      ? _namesCell(r.role, assignments.auxiliary(r), cols.auxRoom, measure, nameStyle)
      : null;
  // The title is centered vertically if any of the columns stacked.
  final stacked = main.stacked || (auxCell?.stacked ?? false);

  // X cell: time in a fixed box + title with a hanging indent (Expanded).
  final xCell = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: m.hourWidth,
        child: r.bullet
            ? pw.Row(
                children: [
                  pw.Text(r.time, style: timeStyle),
                  pw.Expanded(
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      // \vineta = bullet + 3pt; \llap keeps the title aligned.
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 3),
                        child: pw.Text('•',
                            style: pw.TextStyle(
                                fontSize: m.small, color: S140.labelColor)),
                      ),
                    ),
                  ),
                ],
              )
            : pw.Text(r.time, style: timeStyle),
      ),
      pw.Expanded(
        child: pw.Text(r.content, style: pw.TextStyle(fontSize: m.base)),
      ),
    ],
  );

  return pw.Padding(
    padding: pw.EdgeInsets.only(bottom: m.rowSep),
    child: pw.Row(
      // If the participant wrapped to two lines, the title (and role) center
      // vertically against the names block; otherwise they align to the top.
      crossAxisAlignment:
          stacked ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: xCell),
        pw.SizedBox(width: m.colGap),
        pw.SizedBox(
          width: cols.role,
          child: pw.Text(r.role, textAlign: pw.TextAlign.right, style: roleStyle),
        ),
        if (auxRoom) ...[
          pw.SizedBox(width: m.colGap),
          pw.SizedBox(width: cols.auxRoom, child: auxCell!.widget),
        ],
        pw.SizedBox(width: m.colGap),
        pw.SizedBox(width: cols.mainNames, child: main.widget),
      ],
    ),
  );
}
