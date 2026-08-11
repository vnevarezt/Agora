import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'background.dart';

import '../models/week.dart';
import 'epub_parser.dart';
import 'mwb_api.dart';
import 'mwb_cache.dart';

/// Unzip + HTML parsing are tens-of-ms of pure CPU per notebook: run them off
/// the UI isolate (they hit it on editor open and during the startup sync).
Future<List<Week>> _parseEpubInBackground(Uint8List bytes, String lang) =>
    runInBackground(() => parseEpub(bytes, lang: lang));

/// Data facade: serves the mwb notebook from the on-disk cache, downloading it
/// from jw.org only the first time (then re-parsing the cached EPUB).
class MwbRepository {
  MwbRepository(this._cache, {http.Client? client}) : _client = client;

  final MwbCache _cache;

  /// Injectable for tests; forwarded to [MwbApi] so network calls can be
  /// counted / mocked.
  final http.Client? _client;

  /// Parsed notebooks, keyed by issue+lang.
  ///
  /// The unzip and parse cost ~3 ms per notebook for a minimal one and run on
  /// a fresh isolate each time, and the callers ask repeatedly: the catalog
  /// rebuild walks every cached issue, and it re-runs whenever a congregation
  /// changes. An entry can never go stale — a cached issue is never
  /// re-downloaded, so the bytes behind a key do not change.
  final _parsed = <String, List<Week>>{};

  /// Returns the weeks of notebook [issue] (YYYYMM). Reads the cached EPUB when
  /// present (no network); otherwise downloads, caches and parses it. Throws an
  /// [Exception] with a readable message if the download/parse yields no weeks.
  Future<List<Week>> weeks(String issue, {String lang = 'S'}) async {
    final memo = _parsed['$issue.$lang'];
    if (memo != null) return memo;

    final cached = await _cache.readEpub(issue, lang);
    final bytes =
        cached ?? await MwbApi.downloadEpub(issue, lang: lang, client: _client);
    final weeks = await _parseEpubInBackground(bytes, lang);
    if (weeks.isEmpty) {
      throw Exception('No se encontraron semanas en el notebook $issue.');
    }
    if (cached == null) await _cache.putEpub(issue, lang, bytes, weeks.length);
    _parsed['$issue.$lang'] = weeks;
    return weeks;
  }

  /// Ensures notebook [issue] is in the cache, downloading it if missing.
  /// Returns the number of weeks. Used by the background sync (which owns the
  /// back-off policy), kept separate from the UI-facing [weeks].
  Future<int> ensureCached(String issue, {String lang = 'S'}) async {
    final memo = _parsed['$issue.$lang'];
    if (memo != null) return memo.length;

    final cached = await _cache.readEpub(issue, lang);
    if (cached != null) {
      final weeks = await _parseEpubInBackground(cached, lang);
      _parsed['$issue.$lang'] = weeks;
      return weeks.length;
    }
    final bytes = await MwbApi.downloadEpub(issue, lang: lang, client: _client);
    final weeks = await _parseEpubInBackground(bytes, lang);
    if (weeks.isEmpty) {
      throw Exception('No se encontraron semanas en el notebook $issue.');
    }
    await _cache.putEpub(issue, lang, bytes, weeks.length);
    _parsed['$issue.$lang'] = weeks;
    return weeks.length;
  }
}
