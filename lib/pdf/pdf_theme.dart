import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Layout constants taken EXACTLY from programa-vmc.tex.
/// (Official S-140-S format.) 1 cm = 28.3465 pt; 1 in = 72 pt.
class S140 {
  S140._();

  // ---- Page: Letter, margins from the original Word doc (tex:13) ----
  static const double pageWidth = 612; // 8.5 in
  static const double pageHeight = 792; // 11 in
  static const double marginTop = 0.7 * 72; // 50.4
  static const double marginBottom = 0.5 * 72; // 36
  static const double marginLeft = 0.8 * 72; // 57.6
  static const double marginRight = 0.8 * 72; // 57.6

  /// Usable width = \textwidth.
  static const double contentWidth = pageWidth - marginLeft - marginRight; // 496.8

  // ---- Font sizes (article class 10pt) ----
  static const double base = 10;
  static const double small = 9; // \small
  static const double footnote = 8; // \footnotesize
  static const double large = 12; // \large
  static const double title = 16.5; // header title
  static const double week = 12; // week line / reading

  // ---- Column widths (tex:57-61) ----
  static const double cm = 28.3465;
  static const double hourWidth = 1.3 * cm; // 36.85
  static const double roleWidth = 2.6 * cm; // 73.70
  static const double mainNameWidth = 5.0 * cm; // 141.73
  static const double tabcolsep = 3;

  /// Gap between columns in tabularx (= 2·tabcolsep, see array/@{}).
  static const double colGap = 2 * tabcolsep; // 6
  static const double rowSep = 10; // \filasep (tex:61)
  static const double fboxsep = 3; // default \colorbox padding

  /// Width of the content column (X cell = time + title).
  static const double contentColWidth =
      contentWidth - 2 * colGap - roleWidth - mainNameWidth;

  /// Width of the color band: reaches the RIGHT EDGE of the role labels
  /// (Estudiante/Ayudante).
  static const double bandWidth = contentColWidth + colGap + roleWidth;

  /// Title floor when the names column grows adaptively.
  static const double minContent = 0.40 * contentWidth;

  /// Title floor in Auxiliary Room mode (4 columns).
  static const double minContentAux = 0.34 * contentWidth;

  /// Minimum width of each names column in Auxiliary Room mode.
  static const double minAuxCol = 60;

  /// Slack added to the measured width of the longest name.
  static const double namePad = 6;

  // ---- Official colors (tex:31-35) ----
  static final PdfColor treasures = PdfColor.fromHex('575A5D'); // gray
  static final PdfColor ministryColor = PdfColor.fromHex('BE8900'); // gold
  static final PdfColor christianLife = PdfColor.fromHex('7E0024'); // maroon
  static final PdfColor labelColor = PdfColor.fromHex('575A5D'); // gray (labels)
  static final PdfColor lineColor = PdfColor.fromHex('A6A6A6'); // light gray
  static final PdfColor white = PdfColor.fromHex('FFFFFF');
}

/// Document theme + Carlito fonts. `regular` is also used to MEASURE the names
/// width (adaptive column widths).
typedef Carlito = ({pw.ThemeData theme, pw.Font regular, pw.Font bold});

Carlito? _cache;

/// Loads (once) Carlito — a free Calibri clone (tex:17-22). Caching is
/// essential: reloading ~2.7 MB on each keystroke would break the live preview.
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
