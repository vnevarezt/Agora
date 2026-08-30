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
  // The Word original sets 0.8 in at the sides. That is 23% of the paper spent
  // on white, and it is what caps the type: the sheet has vertical room to
  // spare, so what stops the fit from growing is the longest title and a pair
  // of names competing for the same line. At 0.5 in — the margin the foot of
  // the page already uses — the same week prints at 11.5 pt instead of 10.5.
  static const double marginLeft = 0.5 * 72; // 36
  static const double marginRight = 0.5 * 72; // 36

  /// Usable width = \textwidth.
  static const double contentWidth =
      pageWidth - marginLeft - marginRight; // 496.8

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

  /// Official width of the time column. Only a CEILING now: the times are
  /// measured (see `computeColumns`), and "18:31" in 9 pt Carlito is nowhere
  /// near 1.3 cm — the difference was blank on every row of the sheet.
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

  /// Hard floor for a names column: below this a column stops being a column,
  /// whatever the titles beside it need.
  static const double minNamesCol = 60;

  /// Slack added to the measured width of the longest name.
  static const double namePad = 6;

  /// Pairs of names the fit may stack beyond what the official size already
  /// stacks, on a sheet printing an Auxiliary Room column.
  ///
  /// Three columns of names share one page width there, and the type cannot
  /// grow a single step without stacking a pair — so holding the line strictly
  /// pins the sheet at 10 pt with a fifteenth of the page blank and the row
  /// spacing already at its ceiling. Two pairs buy a whole size (10 → 11 pt)
  /// and a full page. Nothing is bought anywhere else: without the auxiliary
  /// column the names have the room to stay on one line, and stacking them to
  /// grow the type would be undoing the point of measuring them.
  static const int auxNameTolerance = 2;

  // ---- Official colors (tex:31-35) ----
  static final PdfColor treasures = PdfColor.fromHex('575A5D'); // gray
  static final PdfColor ministryColor = PdfColor.fromHex('BE8900'); // gold
  static final PdfColor christianLife = PdfColor.fromHex('7E0024'); // maroon
  static final PdfColor labelColor = PdfColor.fromHex(
    '575A5D',
  ); // gray (labels)
  static final PdfColor lineColor = PdfColor.fromHex('A6A6A6'); // light gray
  static final PdfColor white = PdfColor.fromHex('FFFFFF');
}

/// The tunable layout metrics of one program block. [standard] mirrors the
/// official S-140-S values in [S140]; [compact] is the two-per-sheet variant:
/// tighter row/band spacing and the full width of the reduced page margins, so
/// the content REFLOWS (titles and names use the space) instead of being
/// photo-reduced.
///
/// Both are STARTING points. What a sheet actually prints at is one of these
/// run through [scaled], with the factors chosen per document so the block
/// fills its page — see `sheet_fit.dart`.
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
  final double mainNameWidth; // resting width of the names column
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
  final double weekGap; // between stacked week blocks (two-per-sheet)

  // Adaptive-width floors (see computeColumns).
  final double minContentFrac; // title floor, fraction of contentWidth
  final double minContentAuxFrac; // same, Auxiliary Room mode
  final double minNamesCol;
  final double namePad;

  /// Date + weekly reading on ONE line ("13-19 DE JULIO | LECTURA SEMANAL DE
  /// LA BIBLIA: JEREMÍAS 16, 17") instead of the official two-line form —
  /// saves a line per week on the stacked sheet.
  final bool inlineWeekLine;

  /// Bounds for the per-sheet fit (see `sheet_fit.dart`). [maxTypeScale]
  /// bounds how far the type may grow to fill the page; [maxAirScale] how far
  /// the row/band gaps may open once the type has stopped growing. Type first,
  /// air second: a fuller page should read larger, not just looser.
  final double maxTypeScale;
  final double maxAirScale;

  /// How far the type may SHRINK when the block does not fit at all. 1 means
  /// it may not: the one-week sheet flows onto a second page instead, which
  /// keeps the official size honest. A sheet that cannot flow sets this below
  /// 1 — see [minTypeScale] on [compact].
  final double minTypeScale;

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
    required this.weekGap,
    required this.minContentFrac,
    required this.minContentAuxFrac,
    required this.minNamesCol,
    required this.namePad,
    this.inlineWeekLine = false,
    required this.maxTypeScale,
    required this.maxAirScale,
    this.minTypeScale = 1,
  });

  /// The same layout with the type at [type]× and the vertical air at [air]×.
  ///
  /// Everything tied to the type scales — including the hour and role columns,
  /// which hold text, and the gaps, so the block grows as one piece instead of
  /// getting crowded. [contentWidth] is the sheet's and never scales: that is
  /// what makes growing the type a real constraint rather than a zoom, and it
  /// is why the fit has to measure instead of multiply.
  S140Metrics scaled(double type, {double air = 1}) => S140Metrics(
    contentWidth: contentWidth,
    base: base * type,
    small: small * type,
    footnote: footnote * type,
    large: large * type,
    title: title * type,
    week: week * type,
    hourWidth: hourWidth * type,
    roleWidth: roleWidth * type,
    // The official 5 cm names column and the auxiliary-room minimum are
    // floors in PAPER units, not type units: scaling them up would take
    // width from the titles for names that never asked for it.
    mainNameWidth: mainNameWidth,
    colGap: colGap * type,
    rowSep: rowSep * type * air,
    fboxsep: fboxsep * type,
    bandGapTop: bandGapTop * type * air,
    bandGapBottom: bandGapBottom * type * air,
    gapHeaderRule: gapHeaderRule * type,
    gapAfterRule: gapAfterRule * type,
    gapAfterWeekLine: gapAfterWeekLine * type * air,
    gapSectionEnd: gapSectionEnd * type * air,
    weekGap: weekGap * type * air,
    minContentFrac: minContentFrac,
    minContentAuxFrac: minContentAuxFrac,
    minNamesCol: minNamesCol,
    namePad: namePad * type,
    inlineWeekLine: inlineWeekLine,
    maxTypeScale: maxTypeScale,
    maxAirScale: maxAirScale,
    minTypeScale: minTypeScale,
  );

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
    weekGap: 0, // one week per page
    minContentFrac: 0.40,
    minContentAuxFrac: 0.34,
    minNamesCol: S140.minNamesCol,
    namePad: S140.namePad,
    // The official sheet is left at its official size: 1 means the fit cannot
    // move it at all. Growing the type and opening the rows until the block
    // reached the foot of the page did fill the paper, but it stopped looking
    // like the form — a page of 14 rows spread over 11 inches reads as a list
    // that ran out of things to say, not as a programme. The two-per-sheet
    // layout keeps the fit: there, filling the page is the entire point.
    maxTypeScale: 1.0,
    maxAirScale: 1.0,
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
    weekGap: S140.stackedWeekGap,
    minContentFrac: 0.40,
    minContentAuxFrac: 0.34,
    minNamesCol: S140.minNamesCol,
    namePad: S140.namePad,
    inlineWeekLine: true,
    // Half a page per week: less room to grow into, and the air has to stay
    // tighter or the two blocks stop reading as two blocks.
    maxTypeScale: 1.2,
    maxAirScale: 1.5,
    // This page cannot flow: it is one sheet by definition. Left to overflow
    // it gets photo-reduced by the [pw.BoxFit.scaleDown] wrapper, which takes
    // the WIDTH down with the height and hands back the right margin the
    // layout just spent its whole design claiming. Shrinking the type instead
    // keeps the full measure, so the reduction is a last resort now.
    minTypeScale: 0.85,
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
