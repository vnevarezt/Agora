import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/program_row.dart';
import '../models/week.dart';
import 'column_layout.dart';
import 'pdf_theme.dart';

/// Genera el PDF del programa reproduciendo programa-vmc.tex (formato S-140-S).
/// Los nombres se leen de [assignments] (separados de la estructura).
Future<Uint8List> buildProgramPdf({
  required String congregation,
  required Week week,
  required ProgramSchedule schedule,
  Assignments assignments = Assignments.empty,
  String chairman = '',
  bool auxRoom = false,
}) async {
  final carlito = await carlitoFonts();
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
      // Pie de página en todas las páginas: "S-140-S   11/23" (tex:40).
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerLeft,
        child: pw.Text('S-140-S    11/23',
            style: pw.TextStyle(fontSize: S140.footnote)),
      ),
      build: (ctx) {
        // Anchos adaptativos según el contenido real (getFont necesita el ctx).
        final reg = carlito.regular.getFont(ctx);
        final cols = calcularColumnas(schedule, assignments, reg, auxRoom);
        double medir(String s) => reg.stringMetrics(s).advanceWidth * S140.base;
        return [
          _encabezado(congregation),
          pw.SizedBox(height: 4),
          _reglafg(),
          pw.SizedBox(height: 3), // \par\smallskip
          _weekLine(week, chairman),
          pw.SizedBox(height: 8), // \addvspace{8pt}
          if (auxRoom) ...[_encabezadoSalas(cols), pw.SizedBox(height: 2)],
          _table(schedule.opening, assignments, cols, medir, auxRoom),
          _band(S140.treasures, 'TESOROS DE LA BIBLIA', 'Auditorio principal',
              cols, auxRoom),
          _table(schedule.treasures, assignments, cols, medir, auxRoom),
          _band(S140.maestros, 'SEAMOS MEJORES MAESTROS', 'Auditorio principal',
              cols, auxRoom),
          _table(schedule.ministry, assignments, cols, medir, auxRoom),
          _band(S140.christianLife, 'NUESTRA VIDA CRISTIANA', '', cols, auxRoom),
          _table(schedule.christianLife, assignments, cols, medir, auxRoom),
          pw.SizedBox(height: 4), // \addvspace{4pt}
          _reglafg(),
        ];
      },
    ),
  );
  return doc.save();
}

// ---- Encabezado: congregación (izq.) y título (der.) (tex:171-178) ----
pw.Widget _encabezado(String congregation) {
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

// ---- Regla fina + gruesa (tex:161-163) ----
pw.Widget _reglafg() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(width: S140.contentWidth, height: 0.4, color: S140.linea),
      pw.SizedBox(height: 1.2),
      pw.Container(width: S140.contentWidth, height: 1.6, color: S140.linea),
    ],
  );
}

// ---- Línea de week + chairman + lectura (tex:183-187) ----
pw.Widget _weekLine(Week s, String chairman) {
  final semanaStyle =
      pw.TextStyle(fontSize: S140.week, fontWeight: pw.FontWeight.bold);
  final rol = pw.TextStyle(
      fontSize: S140.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.rotulo);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Text('${s.date}   |   LECTURA SEMANAL DE LA BIBLIA',
                style: semanaStyle),
          ),
          pw.Text('Presidente: ', style: rol),
          pw.Text(chairman, style: pw.TextStyle(fontSize: S140.week)),
        ],
      ),
      pw.Text(s.reading, style: semanaStyle),
    ],
  );
}

// ---- Encabezado único de salas (tex:150-155, solo modo auxRoom) ----
pw.Widget _encabezadoSalas(ColumnWidths cols) {
  final st = pw.TextStyle(
      fontSize: S140.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.rotulo);
  return pw.Row(
    children: [
      pw.Expanded(child: pw.SizedBox()), // zona título + rol
      pw.SizedBox(width: S140.colGap),
      pw.SizedBox(width: cols.auxRoom, child: pw.Text('Sala Auxiliar', style: st)),
      pw.SizedBox(width: S140.colGap),
      pw.SizedBox(
          width: cols.nomPrin, child: pw.Text('Auditorio principal', style: st)),
    ],
  );
}

// ---- Banda de sección (tex:135-145) ----
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
            // Llega hasta el borde derecho de las etiquetas de rol.
            width: cols.banda,
            color: color,
            padding: const pw.EdgeInsets.all(S140.fboxsep),
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: S140.base,
                    fontWeight: pw.FontWeight.bold,
                    color: S140.blanco)),
          ),
          pw.Spacer(), // \hfill
          // En modo auxRoom el rótulo va una sola vez en el header de salas.
          if (!auxRoom && labelText.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2), // \raisebox{2pt}
              child: pw.Text(labelText,
                  style: pw.TextStyle(
                      fontSize: S140.footnote,
                      fontWeight: pw.FontWeight.bold,
                      color: S140.rotulo)),
            ),
        ],
      ),
      pw.SizedBox(height: 5), // \addvspace{5pt}
    ],
  );
}

// ---- Tabla de rows (tabularx @{}X R P@{} o @{}X R A P@{} en auxRoom) ----
pw.Widget _table(List<ProgramRow> rows, Assignments asg, ColumnWidths cols,
    double Function(String) medir, bool auxRoom) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [for (final f in rows) _row(f, asg, cols, medir, auxRoom)],
  );
}

// Celda de nombres (Principal o Sala Auxiliar). Regla Seamos: si la pareja
// Estudiante/Ayudante no cabe en una línea, se apila SIEMPRE: línea 1 Ayudante,
// línea 2 Estudiante. Devuelve el widget y si quedó apilada (2 líneas).
({pw.Widget widget, bool apilado}) _celdaNombres(String rol,
    List<String> nombres, double ancho, double Function(String) medir,
    pw.TextStyle style) {
  final joined = joinedNames(nombres);
  final esEstAyud = rol == 'Estudiante/Ayudante:' && nombres.length == 2;
  if (esEstAyud && medir(joined) > ancho) {
    return (
      widget: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(nombres[1],
              textAlign: pw.TextAlign.right, style: style), // Ayudante
          pw.Text(nombres[0],
              textAlign: pw.TextAlign.right, style: style), // Estudiante
        ],
      ),
      apilado: true,
    );
  }
  return (
    widget: pw.Text(joined, textAlign: pw.TextAlign.right, style: style),
    apilado: false,
  );
}

pw.Widget _row(ProgramRow r, Assignments asg, ColumnWidths cols,
    double Function(String) medir, bool auxRoom) {
  final horaStyle = pw.TextStyle(
      fontSize: S140.small,
      fontWeight: pw.FontWeight.bold,
      color: S140.rotulo);
  final rolStyle = pw.TextStyle(
      fontSize: S140.footnote,
      fontWeight: pw.FontWeight.bold,
      color: S140.rotulo);
  final nombreStyle = pw.TextStyle(fontSize: S140.base);

  final prin =
      _celdaNombres(r.role, asg.main(r), cols.nomPrin, medir, nombreStyle);
  final auxCell = auxRoom
      ? _celdaNombres(r.role, asg.auxiliary(r), cols.auxRoom, medir, nombreStyle)
      : null;
  // El título se centra verticalmente si cualquiera de las columnas se apila.
  final apilado = prin.apilado || (auxCell?.apilado ?? false);

  // Celda X: hora en caja fija + título con sangría francesa (Expanded).
  final celdaX = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: S140.anchoHora,
        child: r.bullet
            ? pw.Row(
                children: [
                  pw.Text(r.time, style: horaStyle),
                  pw.Expanded(
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      // \vineta = viñeta + 3pt; \llap mantiene el título alineado.
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 3),
                        child: pw.Text('•',
                            style: pw.TextStyle(
                                fontSize: S140.small, color: S140.rotulo)),
                      ),
                    ),
                  ),
                ],
              )
            : pw.Text(r.time, style: horaStyle),
      ),
      pw.Expanded(
        child: pw.Text(r.content, style: pw.TextStyle(fontSize: S140.base)),
      ),
    ],
  );

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: S140.filaSep),
    child: pw.Row(
      // Si el participante quedó en dos líneas, el título (y el rol) se centran
      // verticalmente respecto al bloque de nombres; si no, alineados arriba.
      crossAxisAlignment:
          apilado ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: celdaX),
        pw.SizedBox(width: S140.colGap),
        pw.SizedBox(
          width: cols.role,
          child: pw.Text(r.role, textAlign: pw.TextAlign.right, style: rolStyle),
        ),
        if (auxRoom) ...[
          pw.SizedBox(width: S140.colGap),
          pw.SizedBox(width: cols.auxRoom, child: auxCell!.widget),
        ],
        pw.SizedBox(width: S140.colGap),
        pw.SizedBox(width: cols.nomPrin, child: prin.widget),
      ],
    ),
  );
}
