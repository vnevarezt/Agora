import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/week.dart';
import '../schedule/rules.dart';
import 'style.dart';

// Tema con las fuentes Carlito cargado UNA sola vez (las fuentes pesan ~2.7 MB
// y recargarlas en cada pulsación rompería el live preview en tiempo real).
pw.ThemeData? _themeCache;

Future<pw.ThemeData> _carlitoTheme() async {
  if (_themeCache != null) return _themeCache!;
  // Carlito (clon de Calibri) — \setmainfont{Carlito} (tex:17-22).
  final regular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-Regular.ttf'));
  final bold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-Bold.ttf'));
  final italic =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-Italic.ttf'));
  final boldItalic =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-BoldItalic.ttf'));
  return _themeCache = pw.ThemeData.withFont(
    base: regular,
    bold: bold,
    italic: italic,
    boldItalic: boldItalic,
  );
}

/// Genera el PDF del programa reproduciendo programa-vmc.tex (formato S-140-S)
/// con la librería `pdf`. Devuelve los bytes del PDF.
Future<Uint8List> buildProgramPdf({
  required String cong,
  required Week semana,
  required ProgramSchedule sched,
  String presidente = '',
}) async {
  final theme = await _carlitoTheme();

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        theme: theme,
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
        child: pw.Text(
          'S-140-S    11/23',
          style: pw.TextStyle(fontSize: S140.footnote),
        ),
      ),
      build: (ctx) => [
        _encabezado(cong),
        pw.SizedBox(height: 4),
        _reglafg(),
        pw.SizedBox(height: 3), // \par\smallskip
        _lineaSemana(semana, presidente),
        pw.SizedBox(height: 8), // \addvspace{8pt}
        _tabla(sched.apertura),
        _banda(S140.tesoros, 'TESOROS DE LA BIBLIA', 'Auditorio principal'),
        _tabla(sched.tesoros),
        _banda(S140.maestros, 'SEAMOS MEJORES MAESTROS', 'Auditorio principal'),
        _tabla(sched.seamos),
        _banda(S140.vida, 'NUESTRA VIDA CRISTIANA', ''),
        _tabla(sched.vida),
        pw.SizedBox(height: 4), // \addvspace{4pt}
        _reglafg(),
      ],
    ),
  );
  return doc.save();
}

// ---- Encabezado: congregación (izq.) y título (der.) (tex:171-178) ----
pw.Widget _encabezado(String cong) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end, // minipages [b]
    children: [
      pw.SizedBox(
        width: 0.34 * S140.contentWidth,
        child: pw.Text(
          cong,
          style: pw.TextStyle(
            fontSize: S140.large,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.Spacer(), // \hfill
      pw.SizedBox(
        width: 0.64 * S140.contentWidth,
        child: pw.Text(
          'Programa para la reunión de entre semana',
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: S140.titulo,
            fontWeight: pw.FontWeight.bold,
          ),
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

// ---- Línea de semana + presidente + lectura (tex:183-187) ----
pw.Widget _lineaSemana(Week s, String presidente) {
  final semanaStyle = pw.TextStyle(
    fontSize: S140.semana,
    fontWeight: pw.FontWeight.bold,
  );
  final rol = pw.TextStyle(
    fontSize: S140.footnote,
    fontWeight: pw.FontWeight.bold,
    color: S140.rotulo,
  );
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Text(
              '${s.fecha}   |   LECTURA SEMANAL DE LA BIBLIA',
              style: semanaStyle,
            ),
          ),
          pw.Text('Presidente: ', style: rol),
          pw.Text(presidente, style: pw.TextStyle(fontSize: S140.semana)),
        ],
      ),
      pw.Text(s.lectura, style: semanaStyle),
    ],
  );
}

// ---- Banda de sección (tex:135-145, modo no-aux) ----
pw.Widget _banda(PdfColor color, String titulo, String rotuloTxt) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 6), // \addvspace{6pt}
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            width: 0.63 * S140.contentWidth,
            color: color,
            padding: const pw.EdgeInsets.all(S140.fboxsep),
            child: pw.Text(
              titulo,
              style: pw.TextStyle(
                fontSize: S140.base,
                fontWeight: pw.FontWeight.bold,
                color: S140.blanco,
              ),
            ),
          ),
          pw.Spacer(), // \hfill
          if (rotuloTxt.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2), // \raisebox{2pt}
              child: pw.Text(
                rotuloTxt,
                style: pw.TextStyle(
                  fontSize: S140.footnote,
                  fontWeight: pw.FontWeight.bold,
                  color: S140.rotulo,
                ),
              ),
            ),
        ],
      ),
      pw.SizedBox(height: 5), // \addvspace{5pt}
    ],
  );
}

// ---- Tabla de filas (tabularx @{}X R P@{}) ----
pw.Widget _tabla(List<ProgramRow> filas) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [for (final f in filas) _fila(f)],
  );
}

pw.Widget _fila(ProgramRow r) {
  final horaStyle = pw.TextStyle(
    fontSize: S140.small,
    fontWeight: pw.FontWeight.bold,
    color: S140.rotulo,
  );
  final rolStyle = pw.TextStyle(
    fontSize: S140.footnote,
    fontWeight: pw.FontWeight.bold,
    color: S140.rotulo,
  );
  final nombre = r.nombreTexto;

  // Celda X: hora en caja fija + título con sangría francesa (Expanded).
  final celdaX = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: S140.anchoHora,
        child: r.vineta
            ? pw.Row(
                children: [
                  pw.Text(r.hora, style: horaStyle),
                  pw.Expanded(
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      // \vineta = viñeta + \hspace{3pt}; el \llap mantiene el
                      // título alineado, la viñeta cuelga 3pt a su izquierda.
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
            : pw.Text(r.hora, style: horaStyle),
      ),
      pw.Expanded(
        child: pw.Text(
          r.contenido,
          style: pw.TextStyle(fontSize: S140.base),
        ),
      ),
    ],
  );

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: S140.filaSep),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: celdaX),
        pw.SizedBox(width: S140.colGap),
        pw.SizedBox(
          width: S140.anchoRol,
          child: pw.Text(r.rol, textAlign: pw.TextAlign.right, style: rolStyle),
        ),
        pw.SizedBox(width: S140.colGap),
        pw.SizedBox(
          width: S140.anchoNomPrin,
          child: pw.Text(
            nombre,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: S140.base),
          ),
        ),
      ],
    ),
  );
}
