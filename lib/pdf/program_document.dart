import 'dart:isolate';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/program_row.dart';
import '../models/week.dart';
import 'column_layout.dart';
import 'pdf_theme.dart';

/// Generates the program PDF reproducing programa-vmc.tex (S-140-S format).
/// Names are read from [assignments] (kept apart from the structure).
///
/// Layout, font subsetting and compression are ~100–300 ms of pure CPU on a
/// phone, so the document is built in a background isolate: only the font
/// bytes are loaded here (rootBundle needs the main isolate) and the models
/// are plain data, safe to send across.
Future<Uint8List> buildProgramPdf({
  required String congregation,
  required Week week,
  required ProgramSchedule schedule,
  Assignments assignments = Assignments.empty,
  String chairman = '',
  bool auxRoom = false,
}) async {
  final fontBytes = await carlitoFontBytes();
  return Isolate.run(() => _buildPdf(
        fontBytes: fontBytes,
        congregation: congregation,
        week: week,
        schedule: schedule,
        assignments: assignments,
        chairman: chairman,
        auxRoom: auxRoom,
      ));
}

Future<Uint8List> _buildPdf({
  required CarlitoBytes fontBytes,
  required String congregation,
  required Week week,
  required ProgramSchedule schedule,
  required Assignments assignments,
  required String chairman,
  required bool auxRoom,
}) async {
  final carlito = carlitoFromBytes(fontBytes);
  final doc = pw.Document();
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
        alignment: pw.Alignment.centerLeft,
        child: pw.Text('S-140-S    11/23',
            style: pw.TextStyle(fontSize: S140.footnote)),
      ),
      build: (ctx) {
        // Adaptive widths based on the real content (getFont needs the ctx).
        final regularFont = carlito.regular.getFont(ctx);
        final cols = computeColumns(schedule, assignments, regularFont, auxRoom);
        double measure(String s) =>
            regularFont.stringMetrics(s).advanceWidth * S140.base;
        return [
          _header(congregation),
          pw.SizedBox(height: 4),
          _thinThickRule(),
          pw.SizedBox(height: 3), // \par\smallskip
          _weekLine(week, chairman),
          pw.SizedBox(height: 8), // \addvspace{8pt}
          if (auxRoom) ...[_roomsHeader(cols), pw.SizedBox(height: 2)],
          _table(schedule.opening, assignments, cols, measure, auxRoom),
          _band(S140.treasures, 'TESOROS DE LA BIBLIA', 'Auditorio principal',
              cols, auxRoom),
          _table(schedule.treasures, assignments, cols, measure, auxRoom),
          _band(S140.ministryColor, 'SEAMOS MEJORES MAESTROS', 'Auditorio principal',
              cols, auxRoom),
          _table(schedule.ministry, assignments, cols, measure, auxRoom),
          _band(S140.christianLife, 'NUESTRA VIDA CRISTIANA', '', cols, auxRoom),
          _table(schedule.christianLife, assignments, cols, measure, auxRoom),
          pw.SizedBox(height: 4), // \addvspace{4pt}
          _thinThickRule(),
        ];
      },
    ),
  );
  return doc.save();
}

// ---- Header: congregation (left) and title (right) (tex:171-178) ----
pw.Widget _header(String congregation) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end, // minipages [b]
    children: [
      pw.SizedBox(
        width: 0.34 * S140.contentWidth,
        child: pw.Text(congregation,
            style: pw.TextStyle(
                fontSize: S140.large, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Spacer(), // \hfill
      pw.SizedBox(
        width: 0.64 * S140.contentWidth,
        child: pw.Text(
          'Programa para la reunión de entre semana',
          textAlign: pw.TextAlign.right,
          style:
              pw.TextStyle(fontSize: S140.title, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

// ---- Thin + thick rule (tex:161-163) ----
pw.Widget _thinThickRule() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(width: S140.contentWidth, height: 0.4, color: S140.lineColor),
      pw.SizedBox(height: 1.2),
      pw.Container(width: S140.contentWidth, height: 1.6, color: S140.lineColor),
    ],
  );
}

// ---- Week line + chairman + reading (tex:183-187) ----
pw.Widget _weekLine(Week week, String chairman) {
  final weekStyle =
      pw.TextStyle(fontSize: S140.week, fontWeight: pw.FontWeight.bold);
  final roleStyle = pw.TextStyle(
      fontSize: S140.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.labelColor);
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
          pw.Text('Presidente: ', style: roleStyle),
          pw.Text(chairman, style: pw.TextStyle(fontSize: S140.week)),
        ],
      ),
      pw.Text(week.reading, style: weekStyle),
    ],
  );
}

// ---- Single rooms header (tex:150-155, auxRoom mode only) ----
pw.Widget _roomsHeader(ColumnWidths cols) {
  final st = pw.TextStyle(
      fontSize: S140.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.labelColor);
  return pw.Row(
    children: [
      pw.Expanded(child: pw.SizedBox()), // title + role area
      pw.SizedBox(width: S140.colGap),
      pw.SizedBox(width: cols.auxRoom, child: pw.Text('Sala Auxiliar', style: st)),
      pw.SizedBox(width: S140.colGap),
      pw.SizedBox(
          width: cols.mainNames, child: pw.Text('Auditorio principal', style: st)),
    ],
  );
}

// ---- Section band (tex:135-145) ----
pw.Widget _band(PdfColor color, String title, String labelText,
    ColumnWidths cols, bool auxRoom) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 6), // \addvspace{6pt}
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            // Reaches the right edge of the role labels.
            width: cols.band,
            color: color,
            padding: const pw.EdgeInsets.all(S140.fboxsep),
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: S140.base,
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
                      fontSize: S140.footnote,
                      fontWeight: pw.FontWeight.bold,
                      color: S140.labelColor)),
            ),
        ],
      ),
      pw.SizedBox(height: 5), // \addvspace{5pt}
    ],
  );
}

// ---- Rows table (tabularx @{}X R P@{} or @{}X R A P@{} in auxRoom) ----
pw.Widget _table(List<ProgramRow> rows, Assignments assignments, ColumnWidths cols,
    double Function(String) measure, bool auxRoom) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [for (final f in rows) _row(f, assignments, cols, measure, auxRoom)],
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

pw.Widget _row(ProgramRow r, Assignments assignments, ColumnWidths cols,
    double Function(String) measure, bool auxRoom) {
  final timeStyle = pw.TextStyle(
      fontSize: S140.small,
      fontWeight: pw.FontWeight.bold,
      color: S140.labelColor);
  final roleStyle = pw.TextStyle(
      fontSize: S140.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.labelColor);
  final nameStyle = pw.TextStyle(fontSize: S140.base);

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
        width: S140.hourWidth,
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
                                fontSize: S140.small, color: S140.labelColor)),
                      ),
                    ),
                  ),
                ],
              )
            : pw.Text(r.time, style: timeStyle),
      ),
      pw.Expanded(
        child: pw.Text(r.content, style: pw.TextStyle(fontSize: S140.base)),
      ),
    ],
  );

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: S140.rowSep),
    child: pw.Row(
      // If the participant wrapped to two lines, the title (and role) center
      // vertically against the names block; otherwise they align to the top.
      crossAxisAlignment:
          stacked ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: xCell),
        pw.SizedBox(width: S140.colGap),
        pw.SizedBox(
          width: cols.role,
          child: pw.Text(r.role, textAlign: pw.TextAlign.right, style: roleStyle),
        ),
        if (auxRoom) ...[
          pw.SizedBox(width: S140.colGap),
          pw.SizedBox(width: cols.auxRoom, child: auxCell!.widget),
        ],
        pw.SizedBox(width: S140.colGap),
        pw.SizedBox(width: cols.mainNames, child: main.widget),
      ],
    ),
  );
}
