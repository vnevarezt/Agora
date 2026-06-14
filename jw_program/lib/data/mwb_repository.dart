import '../models/week.dart';
import 'epub_parser.dart';
import 'mwb_api.dart';

/// Fachada de datos: descarga el notebook mwb de jw.org y lo parsea a semanas.
class MwbRepository {
  const MwbRepository();

  /// Devuelve las semanas del notebook [issue] (YYYYMM). Lanza [Exception] con
  /// mensaje legible si la descarga o el parseo fallan / no hay semanas.
  Future<List<Week>> weeks(String issue, {String lang = 'S'}) async {
    final bytes = await MwbApi.downloadEpub(issue, lang: lang);
    final weeks = parseEpub(bytes);
    if (weeks.isEmpty) {
      throw Exception('No se encontraron semanas en el notebook $issue.');
    }
    return weeks;
  }
}
