import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/week.dart';
import '../schedule/rules.dart';
import 'style.dart';

// Tema + fuentes Carlito cargados UNA sola vez (las fuentes pesan ~2.7 MB y
// recargarlas en cada pulsación rompería el live preview en tiempo real).
// Se guarda también `regular` para poder MEDIR el ancho de los nombres.
typedef _Carlito = ({pw.ThemeData theme, pw.Font regular, pw.Font bold});
_Carlito? _carlitoCache;

Future<_Carlito> _carlito() async {
  if (_carlitoCache != null) return _carlitoCache!;
  // Carlito (clon de Calibri) — \setmainfont{Carlito} (tex:17-22).
  final regular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-Regular.ttf'));
  final bold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-Bold.ttf'));
  final italic =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-Italic.ttf'));
  final boldItalic =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-BoldItalic.ttf'));
  final theme = pw.ThemeData.withFont(
    base: regular,
    bold: bold,
    italic: italic,
    boldItalic: boldItalic,
  );
  return _carlitoCache = (theme: theme, regular: regular, bold: bold);
}

/// Anchos de columna calculados por documento (la celda X/contenido es implícita
/// vía Expanded, así que solo necesitamos rol, nombre y banda).
class _Cols {
  final double rol;
  final double nomPrin;
  final double banda;
  const _Cols({required this.rol, required this.nomPrin, required this.banda});
}

/// Calcula los anchos de columna de forma adaptativa: si los nombres traen mucho
/// texto, ensancha la columna de nombres tomando espacio de la de título (con un
/// piso mínimo). Mide con la métrica real de Carlito. Si los nombres son cortos,
/// devuelve exactamente los anchos por defecto (layout idéntico al de siempre).
_Cols _calcularColumnas(ProgramSchedule sched, PdfFont regular) {
  double medir(String s) => regular.stringMetrics(s).advanceWidth * S140.base;
  double maxNom = 0;
  for (final f in [
    ...sched.apertura,
    ...sched.tesoros,
    ...sched.seamos,
    ...sched.vida,
  ]) {
    double w;
    if (f.rol == 'Estudiante/Ayudante:' && f.nombres.length == 2) {
      // Estos se APILAN si no caben, así que el ancho que importa es el del
      // nombre individual más largo (no la pareja unida). Así no comprimen los
      // títulos de más: si solo hay parejas largas, se apilan y los títulos
      // vuelven a su ancho por defecto.
      final a = medir(f.nombres[0]);
      final b = medir(f.nombres[1]);
      w = a > b ? a : b;
    } else {
      final t = f.nombreTexto;
      if (t.isEmpty) continue;
      w = medir(t);
    }
    if (w > maxNom) maxNom = w;
  }
  const rol = S140.anchoRol; // fijo (etiquetas de rol, no entrada del usuario)
  final maxNomOK = S140.contentWidth - 2 * S140.colGap - rol - S140.minContenido;
  final nomPrin =
      (maxNom + S140.nomPad).clamp(S140.anchoNomPrin, maxNomOK).toDouble();
  final contenido = S140.contentWidth - 2 * S140.colGap - rol - nomPrin;
  return _Cols(rol: rol, nomPrin: nomPrin, banda: contenido + S140.colGap + rol);
}

/// Genera el PDF del programa reproduciendo programa-vmc.tex (formato S-140-S)
/// con la librería `pdf`. Devuelve los bytes del PDF.
Future<Uint8List> buildProgramPdf({
  required String cong,
  required Week semana,
  required ProgramSchedule sched,
  String presidente = '',
}) async {
  final carlito = await _carlito();

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
        child: pw.Text(
          'S-140-S    11/23',
          style: pw.TextStyle(fontSize: S140.footnote),
        ),
      ),
      build: (ctx) {
        // Anchos adaptativos según el contenido real de los nombres (mide con
        // la métrica de Carlito; getFont necesita el Context del build).
        final reg = carlito.regular.getFont(ctx);
        final cols = _calcularColumnas(sched, reg);
        // Ancho de un texto a tamaño base, para decidir saltos de línea.
        double medir(String s) => reg.stringMetrics(s).advanceWidth * S140.base;
        return [
          _encabezado(cong),
          pw.SizedBox(height: 4),
          _reglafg(),
          pw.SizedBox(height: 3), // \par\smallskip
          _lineaSemana(semana, presidente),
          pw.SizedBox(height: 8), // \addvspace{8pt}
          _tabla(sched.apertura, cols, medir),
          _banda(S140.tesoros, 'TESOROS DE LA BIBLIA', 'Auditorio principal', cols),
          _tabla(sched.tesoros, cols, medir),
          _banda(S140.maestros, 'SEAMOS MEJORES MAESTROS', 'Auditorio principal',
              cols),
          _tabla(sched.seamos, cols, medir),
          _banda(S140.vida, 'NUESTRA VIDA CRISTIANA', '', cols),
          _tabla(sched.vida, cols, medir),
          pw.SizedBox(height: 4), // \addvspace{4pt}
          _reglafg(),
        ];
      },
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
pw.Widget _banda(PdfColor color, String titulo, String rotuloTxt, _Cols cols) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 6), // \addvspace{6pt}
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            // Llega hasta el borde derecho de las etiquetas de rol
            // (Estudiante/Ayudante), en las tres secciones (ancho adaptativo).
            width: cols.banda,
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
pw.Widget _tabla(
    List<ProgramRow> filas, _Cols cols, double Function(String) medir) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [for (final f in filas) _fila(f, cols, medir)],
  );
}

pw.Widget _fila(ProgramRow r, _Cols cols, double Function(String) medir) {
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
  final nombreStyle = pw.TextStyle(fontSize: S140.base);

  // Regla Seamos: Estudiante/Ayudante se apila (línea 1 Ayudante, línea 2
  // Estudiante) solo si no cabe en una línea.
  final esEstAyud = r.rol == 'Estudiante/Ayudante:' && r.nombres.length == 2;
  final apilado = esEstAyud && medir(r.nombreTexto) > cols.nomPrin;

  final pw.Widget nombreWidget = apilado
      ? pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(r.nombres[1],
                textAlign: pw.TextAlign.right, style: nombreStyle), // Ayudante
            pw.Text(r.nombres[0],
                textAlign: pw.TextAlign.right, style: nombreStyle), // Estudiante
          ],
        )
      : pw.Text(r.nombreTexto,
          textAlign: pw.TextAlign.right, style: nombreStyle);

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
      // Si el participante quedó en dos líneas, el título (y el rol) se centran
      // verticalmente respecto al bloque de nombres; si no, alineados arriba.
      crossAxisAlignment:
          apilado ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: celdaX),
        pw.SizedBox(width: S140.colGap),
        pw.SizedBox(
          width: cols.rol,
          child: pw.Text(r.rol, textAlign: pw.TextAlign.right, style: rolStyle),
        ),
        pw.SizedBox(width: S140.colGap),
        pw.SizedBox(width: cols.nomPrin, child: nombreWidget),
      ],
    ),
  );
}
