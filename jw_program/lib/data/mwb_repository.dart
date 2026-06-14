import 'package:http/http.dart' as http;

import '../models/week.dart';
import 'epub_parser.dart';
import 'mwb_api.dart';
import 'mwb_cache.dart';

/// Data facade: serves the mwb notebook from the on-disk cache, downloading it
/// from jw.org only the first time (then re-parsing the cached EPUB).
class MwbRepository {
  MwbRepository(this._cache, {http.Client? client}) : _client = client;

  final MwbCache _cache;

  /// Injectable for tests; forwarded to [MwbApi] so network calls can be
  /// counted / mocked.
  final http.Client? _client;

  /// Returns the weeks of notebook [issue] (YYYYMM). Reads the cached EPUB when
  /// present (no network); otherwise downloads, caches and parses it. Throws an
  /// [Exception] with a readable message if the download/parse yields no weeks.
  Future<List<Week>> weeks(String issue, {String lang = 'S'}) async {
    final cached = await _cache.readEpub(issue, lang);
    final bytes =
        cached ?? await MwbApi.downloadEpub(issue, lang: lang, client: _client);
    final weeks = parseEpub(bytes);
    if (weeks.isEmpty) {
      throw Exception('No se encontraron semanas en el notebook $issue.');
    }
    if (cached == null) await _cache.putEpub(issue, lang, bytes, weeks.length);
    return weeks;
  }

  /// Ensures notebook [issue] is in the cache, downloading it if missing.
  /// Returns the number of weeks. Used by the background sync (which owns the
  /// back-off policy), kept separate from the UI-facing [weeks].
  Future<int> ensureCached(String issue, {String lang = 'S'}) async {
    final cached = await _cache.readEpub(issue, lang);
    if (cached != null) return parseEpub(cached).length;
    final bytes = await MwbApi.downloadEpub(issue, lang: lang, client: _client);
    final weeks = parseEpub(bytes);
    if (weeks.isEmpty) {
      throw Exception('No se encontraron semanas en el notebook $issue.');
    }
    await _cache.putEpub(issue, lang, bytes, weeks.length);
    return weeks.length;
  }
}
