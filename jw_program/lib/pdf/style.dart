import 'package:pdf/pdf.dart';

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
  static const double titulo = 16.5; // título de cabecera
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
  /// de rol (Estudiante/Ayudante) = fin de la columna de contenido + hueco +
  /// columna de rol.
  static const double anchoBanda = anchoContenido + colGap + anchoRol;

  // ---- Colores oficiales (tex:31-35) ----
  static final PdfColor tesoros = PdfColor.fromHex('575A5D'); // gris
  static final PdfColor maestros = PdfColor.fromHex('BE8900'); // dorado
  static final PdfColor vida = PdfColor.fromHex('7E0024'); // granate
  static final PdfColor rotulo = PdfColor.fromHex('575A5D'); // gris (rótulos)
  static final PdfColor linea = PdfColor.fromHex('A6A6A6'); // gris claro
  static final PdfColor blanco = PdfColor.fromHex('FFFFFF');
}
