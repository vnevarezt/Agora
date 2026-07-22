import 'package:pdf/pdf.dart';

import '../models/program_row.dart';
import 'pdf_theme.dart';

/// Column widths computed per document. The content cell (X) is implicit
/// (Expanded), so we only store role, auxRoom, names and band widths.
class ColumnWidths {
  final double role;
  final double mainNames;
  final double auxRoom; // 0 when Auxiliary Room mode is off
  final double band;
  const ColumnWidths({
    required this.role,
    required this.mainNames,
    required this.auxRoom,
    required this.band,
  });
}

/// Width a row's names column needs. For Estudiante/Ayudante it uses the
/// longest individual name (they stack); for the rest, the joined text.
double namesWidth(
    String role, List<String> names, double Function(String) measure) {
  if (names.isEmpty) return 0;
  if (role == 'Estudiante/Ayudante:' && names.length == 2) {
    final a = measure(names[0]);
    final b = measure(names[1]);
    return a > b ? a : b;
  }
  return measure(joinedNames(names));
}

/// Computes the widths adaptively: if the names carry a lot of text, it widens
/// the names column(s) taking space from the title (with a floor). In auxRoom
/// mode it splits between two names columns. Measured with Carlito at the
/// layout's [S140Metrics.base] size.
ColumnWidths computeColumns(
  S140Metrics m,
  ProgramSchedule sched,
  Assignments assignments,
  PdfFont regular,
  bool auxRoom,
) {
  double measure(String s) => regular.stringMetrics(s).advanceWidth * m.base;
  double maxMain = 0, maxAuxWidth = 0;
  for (final f in sched.rows) {
    final wp = namesWidth(f.role, assignments.main(f), measure);
    if (wp > maxMain) maxMain = wp;
    if (auxRoom) {
      final wa = namesWidth(f.role, assignments.auxiliary(f), measure);
      if (wa > maxAuxWidth) maxAuxWidth = wa;
    }
  }
  final role = m.roleWidth; // fixed (role labels, not user input)

  if (!auxRoom) {
    final maxNamesOk =
        m.contentWidth - 2 * m.colGap - role - m.minContentFrac * m.contentWidth;
    final mainNames =
        (maxMain + m.namePad).clamp(m.mainNameWidth, maxNamesOk).toDouble();
    final content = m.contentWidth - 2 * m.colGap - role - mainNames;
    return ColumnWidths(
        role: role,
        mainNames: mainNames,
        auxRoom: 0,
        band: content + m.colGap + role);
  }

  // --- Auxiliary Room mode: 4 columns (X R A P), 3 gaps ---
  final available = m.contentWidth -
      3 * m.colGap -
      role -
      m.minContentAuxFrac * m.contentWidth;
  var mainNames = maxMain + m.namePad;
  var auxNames = maxAuxWidth + m.namePad;
  if (mainNames < m.minAuxCol) mainNames = m.minAuxCol;
  if (auxNames < m.minAuxCol) auxNames = m.minAuxCol;
  if (mainNames + auxNames > available) {
    final factor = available / (mainNames + auxNames);
    mainNames = (mainNames * factor).clamp(m.minAuxCol, available).toDouble();
    auxNames = (auxNames * factor).clamp(m.minAuxCol, available).toDouble();
  }
  final content =
      m.contentWidth - 3 * m.colGap - role - mainNames - auxNames;
  return ColumnWidths(
      role: role,
      mainNames: mainNames,
      auxRoom: auxNames,
      band: content + m.colGap + role);
}
