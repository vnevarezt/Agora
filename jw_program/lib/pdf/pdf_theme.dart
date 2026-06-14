import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Constantes de maquetación tomadas EXACTAMENTE de programa-vmc.tex.
/// (Formato oficial S-140-S.) 1 cm = 28.3465 pt; 1 in = 72 pt.
class S140 {
  S140._();

  // ---- Página: Carta, márgenes del Word original (tex:13) ----
  static const double pageWidth = 612; // 8.5 in
  static const double pageHeight = 792; // 11 in
  static const double marginTop = 0.7 * 72; // 50.4
  static const double marginBottom = 0.5 * 72; // 36
  static const double marginLeft = 0.8 * 72; // 57.6
  static const double marginRight = 0.8 * 72; // 57.6

  /// Ancho útil = \textwidth.
  static const double contentWidth = pageWidth - marginLeft - marginRight; // 496.8

  // ---- Tamaños de fuente (clase article 10pt) ----
  static const double base = 10;
  static const double small = 9; // \small
  static const double footnote = 8; // \footnotesize
  static const double large = 12; // \large
  static const double title = 16.5; // título de cabecera
  static const double semana = 12; // línea de semana / lectura

  // ---- Anchos de columna (tex:57-61) ----
  static const double cm = 28.3465;
  static const double anchoHora = 1.3 * cm; // 36.85
  static const double anchoRol = 2.6 * cm; // 73.70
  static const double anchoNomPrin = 5.0 * cm; // 141.73
  static const double tabcolsep = 3;

  /// Hueco entre columnas en tabularx (= 2·tabcolsep, ver array/@{}).
  static const double colGap = 2 * tabcolsep; // 6
  static const double filaSep = 10; // \filasep (tex:61)
  static const double fboxsep = 3; // padding por defecto de \colorbox

  /// Ancho de la columna de contenido (celda X = hora + título).
  static const double anchoContenido =
      contentWidth - 2 * colGap - anchoRol - anchoNomPrin;

  /// Ancho de la banda de color: llega hasta el BORDE DERECHO de las etiquetas
  /// de rol (Estudiante/Ayudante).
  static const double anchoBanda = anchoContenido + colGap + anchoRol;

  /// Piso del título when la columna de nombres crece de forma adaptativa.
  static const double minContenido = 0.40 * contentWidth;

  /// Piso del título en modo Sala Auxiliar (4 columnas).
  static const double minContenidoAux = 0.34 * contentWidth;

  /// Ancho mínimo de cada columna de nombres en modo Sala Auxiliar.
  static const double minColAux = 60;

  /// Holgura que se suma al ancho medido del nombre más largo.
  static const double nomPad = 6;

  // ---- Colores oficiales (tex:31-35) ----
  static final PdfColor treasures = PdfColor.fromHex('575A5D'); // gris
  static final PdfColor maestros = PdfColor.fromHex('BE8900'); // dorado
  static final PdfColor christianLife = PdfColor.fromHex('7E0024'); // granate
  static final PdfColor rotulo = PdfColor.fromHex('575A5D'); // gris (rótulos)
  static final PdfColor linea = PdfColor.fromHex('A6A6A6'); // gris claro
  static final PdfColor blanco = PdfColor.fromHex('FFFFFF');
}

/// Tema + fuentes Carlito del documento. `regular` se usa además para MEDIR el
/// ancho de los nombres (anchos adaptativos).
typedef Carlito = ({pw.ThemeData theme, pw.Font regular, pw.Font bold});

Carlito? _cache;

/// Carga (una sola vez) Carlito — clon libre de Calibri (tex:17-22). Cachear es
/// imprescindible: recargar ~2.7 MB en cada pulsación rompería el live preview.
Future<Carlito> carlitoFonts() async {
  if (_cache != null) return _cache!;
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
  return _cache = (theme: theme, regular: regular, bold: bold);
}
