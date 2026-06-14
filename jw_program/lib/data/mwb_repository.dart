import '../models/week.dart';
import 'epub_parser.dart';
import 'mwb_api.dart';

/// Data facade: downloads the mwb notebook from jw.org and parses it to weeks.
class MwbRepository {
  const MwbRepository();

  /// Returns the weeks of notebook [issue] (YYYYMM). Throws an [Exception] with
  /// a readable message if the download or parsing fails / there are no weeks.
  Future<List<Week>> weeks(String issue, {String lang = 'S'}) async {
    final bytes = await MwbApi.downloadEpub(issue, lang: lang);
    final weeks = parseEpub(bytes);
    if (weeks.isEmpty) {
      throw Exception('No se encontraron semanas en el notebook $issue.');
    }
    return weeks;
  }
}
