import 'package:pdf/pdf.dart';

import '../models/program_row.dart';
import 'pdf_theme.dart';

/// Anchos de columna calculados por documento. La celda de contenido (X) es
/// implícita (Expanded), así que solo guardamos role, auxRoom, name y banda.
class ColumnWidths {
  final double role;
  final double nomPrin;
  final double auxRoom; // 0 when el modo Sala Auxiliar está apagado
  final double banda;
  const ColumnWidths({
    required this.role,
    required this.nomPrin,
    required this.auxRoom,
    required this.banda,
  });
}

/// Ancho que necesita la columna de nombres de una fila. Para Estudiante/Ayudante
/// se usa el name individual más largo (se apila), para el resto el texto unido.
double anchoNombres(
    String role, List<String> nombres, double Function(String) medir) {
  if (nombres.isEmpty) return 0;
  if (role == 'Estudiante/Ayudante:' && nombres.length == 2) {
    final a = medir(nombres[0]);
    final b = medir(nombres[1]);
    return a > b ? a : b;
  }
  return medir(joinedNames(nombres));
}

/// Calcula los anchos de forma adaptativa: si los nombres traen mucho texto,
/// ensancha la(s) columna(s) de nombres tomando espacio del título (con un piso).
/// En modo auxRoom reparte entre dos columnas de nombres. Mide con Carlito.
ColumnWidths calcularColumnas(
  ProgramSchedule sched,
  Assignments asg,
  PdfFont regular,
  bool auxRoom,
) {
  double medir(String s) => regular.stringMetrics(s).advanceWidth * S140.base;
  double maxPrin = 0, maxAux = 0;
  for (final f in sched.rows) {
    final wp = anchoNombres(f.role, asg.main(f), medir);
    if (wp > maxPrin) maxPrin = wp;
    if (auxRoom) {
      final wa = anchoNombres(f.role, asg.auxiliary(f), medir);
      if (wa > maxAux) maxAux = wa;
    }
  }
  const role = S140.anchoRol; // fijo (etiquetas de role, no entrada del user)

  if (!auxRoom) {
    final maxNomOK =
        S140.contentWidth - 2 * S140.colGap - role - S140.minContenido;
    final nomPrin =
        (maxPrin + S140.nomPad).clamp(S140.anchoNomPrin, maxNomOK).toDouble();
    final contenido = S140.contentWidth - 2 * S140.colGap - role - nomPrin;
    return ColumnWidths(
        role: role, nomPrin: nomPrin, auxRoom: 0, banda: contenido + S140.colGap + role);
  }

  // --- Modo Sala Auxiliar: 4 columnas (X R A P), 3 huecos ---
  final dispo =
      S140.contentWidth - 3 * S140.colGap - role - S140.minContenidoAux;
  var nomPrin = maxPrin + S140.nomPad;
  var nomAux = maxAux + S140.nomPad;
  if (nomPrin < S140.minColAux) nomPrin = S140.minColAux;
  if (nomAux < S140.minColAux) nomAux = S140.minColAux;
  if (nomPrin + nomAux > dispo) {
    final factor = dispo / (nomPrin + nomAux);
    nomPrin = (nomPrin * factor).clamp(S140.minColAux, dispo).toDouble();
    nomAux = (nomAux * factor).clamp(S140.minColAux, dispo).toDouble();
  }
  final contenido =
      S140.contentWidth - 3 * S140.colGap - role - nomPrin - nomAux;
  return ColumnWidths(
      role: role,
      nomPrin: nomPrin,
      auxRoom: nomAux,
      banda: contenido + S140.colGap + role);
}
