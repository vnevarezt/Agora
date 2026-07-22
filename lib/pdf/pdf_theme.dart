import 'dart:typed_data';

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

  // ---- Two-per-sheet: portrait Letter, two week blocks stacked, tighter
  // margins so the compact layout gets the full width ----
  static const double stackedMarginV = 0.3 * 72; // 21.6
  static const double stackedMarginH = 0.4 * 72; // 28.8
  static const double stackedContentWidth =
      pageWidth - 2 * stackedMarginH; // 554.4
  /// Vertical gap between the two week blocks.
  static const double stackedWeekGap = 10;

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

/// The tunable layout metrics of one program block. [standard] mirrors the
/// official S-140-S values in [S140]; [compact] is the two-per-sheet variant:
/// slightly smaller type, tighter row/band spacing and the full width of the
/// reduced page margins, so the content REFLOWS (titles and names use the
/// space) instead of being photo-reduced.
class S140Metrics {
  final double contentWidth;

  // Fonts.
  final double base;
  final double small; // times
  final double footnote; // role labels / footer
  final double large; // congregation
  final double title; // header title
  final double week; // week line / reading

  // Columns.
  final double hourWidth;
  final double roleWidth;
  final double mainNameWidth; // floor of the names column
  final double colGap;

  // Spacing.
  final double rowSep;
  final double fboxsep; // band padding
  final double bandGapTop; // \addvspace{6pt}
  final double bandGapBottom; // \addvspace{5pt}
  final double gapHeaderRule; // header → rule
  final double gapAfterRule; // rule → week line (\smallskip)
  final double gapAfterWeekLine; // week line → rows (\addvspace{8pt})
  final double gapSectionEnd; // last row → closing rule

  // Adaptive-width floors (see computeColumns).
  final double minContentFrac; // title floor, fraction of contentWidth
  final double minContentAuxFrac; // same, Auxiliary Room mode
  final double minAuxCol;
  final double namePad;

  /// Date + weekly reading on ONE line ("13-19 DE JULIO | LECTURA SEMANAL DE
  /// LA BIBLIA: JEREMÍAS 16, 17") instead of the official two-line form —
  /// saves a line per week on the stacked sheet.
  final bool inlineWeekLine;

  const S140Metrics({
    required this.contentWidth,
    required this.base,
    required this.small,
    required this.footnote,
    required this.large,
    required this.title,
    required this.week,
    required this.hourWidth,
    required this.roleWidth,
    required this.mainNameWidth,
    required this.colGap,
    required this.rowSep,
    required this.fboxsep,
    required this.bandGapTop,
    required this.bandGapBottom,
    required this.gapHeaderRule,
    required this.gapAfterRule,
    required this.gapAfterWeekLine,
    required this.gapSectionEnd,
    required this.minContentFrac,
    required this.minContentAuxFrac,
    required this.minAuxCol,
    required this.namePad,
    this.inlineWeekLine = false,
  });

  /// Official S-140-S metrics (values in [S140], one week per page).
  static const standard = S140Metrics(
    contentWidth: S140.contentWidth,
    base: S140.base,
    small: S140.small,
    footnote: S140.footnote,
    large: S140.large,
    title: S140.title,
    week: S140.week,
    hourWidth: S140.hourWidth,
    roleWidth: S140.roleWidth,
    mainNameWidth: S140.mainNameWidth,
    colGap: S140.colGap,
    rowSep: S140.rowSep,
    fboxsep: S140.fboxsep,
    bandGapTop: 6,
    bandGapBottom: 5,
    gapHeaderRule: 4,
    gapAfterRule: 3,
    gapAfterWeekLine: 8,
    gapSectionEnd: 4,
    minContentFrac: 0.40,
    minContentAuxFrac: 0.34,
    minAuxCol: S140.minAuxCol,
    namePad: S140.namePad,
  );

  /// Two-per-sheet metrics: body type slightly LARGER than the official
  /// format (the compression comes from the row/band air and the page
  /// margins, not the type). The hour/role columns scale with their font so
  /// "Estudiante/Ayudante:" keeps to one line. If a heavy week overflows, the
  /// page-level scaleDown finds the largest size that fits.
  static const compact = S140Metrics(
    contentWidth: S140.stackedContentWidth,
    base: 10.5,
    small: 10,
    footnote: 8.5,
    large: 12.5,
    title: 15.5,
    week: 11.5,
    hourWidth: 40,
    roleWidth: 2.8 * S140.cm, // 79.4
    mainNameWidth: 4.8 * S140.cm, // 136.1
    colGap: S140.colGap,
    rowSep: 4.5,
    fboxsep: 2.5,
    bandGapTop: 3,
    bandGapBottom: 3,
    gapHeaderRule: 3,
    gapAfterRule: 2,
    gapAfterWeekLine: 5,
    gapSectionEnd: 3,
    minContentFrac: 0.40,
    minContentAuxFrac: 0.34,
    minAuxCol: S140.minAuxCol,
    namePad: S140.namePad,
    inlineWeekLine: true,
  );
}

/// Document theme + Carlito fonts. `regular` is also used to MEASURE the names
/// width (adaptive column widths).
typedef Carlito = ({pw.ThemeData theme, pw.Font regular, pw.Font bold});

/// Raw TTF bytes, loadable only on the main isolate (rootBundle uses platform
/// channels) but freely sendable to the background isolate that builds the PDF.
typedef CarlitoBytes = ({
  ByteData regular,
  ByteData bold,
  ByteData italic,
  ByteData boldItalic,
});

CarlitoBytes? _bytesCache;

/// Loads (once) the Carlito TTFs — a free Calibri clone (tex:17-22). Caching
/// is essential: reloading ~2.7 MB on each keystroke would break the live
/// preview.
Future<CarlitoBytes> carlitoFontBytes() async {
  return _bytesCache ??= (
    regular: await rootBundle.load('assets/fonts/Carlito-Regular.ttf'),
    bold: await rootBundle.load('assets/fonts/Carlito-Bold.ttf'),
    italic: await rootBundle.load('assets/fonts/Carlito-Italic.ttf'),
    boldItalic: await rootBundle.load('assets/fonts/Carlito-BoldItalic.ttf'),
  );
}

/// Parses the fonts and builds the theme. Pure Dart: safe inside the
/// background isolate that renders the PDF.
Carlito carlitoFromBytes(CarlitoBytes bytes) {
  final regular = pw.Font.ttf(bytes.regular);
  final bold = pw.Font.ttf(bytes.bold);
  final theme = pw.ThemeData.withFont(
    base: regular,
    bold: bold,
    italic: pw.Font.ttf(bytes.italic),
    boldItalic: pw.Font.ttf(bytes.boldItalic),
  );
  return (theme: theme, regular: regular, bold: bold);
}
