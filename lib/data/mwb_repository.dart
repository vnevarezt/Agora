import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'background.dart';

import '../models/week.dart';
import 'epub_parser.dart';
import 'mwb_api.dart';
import 'mwb_cache.dart';

/// Unzip + HTML parsing are tens-of-ms of pure CPU per notebook: run them off
/// the UI isolate (they hit it on editor open and during the startup sync).
Future<List<Week>> _parseEpubInBackground(
        Uint8List bytes, String lang, String issue) =>
    runInBackground(() => parseEpub(bytes, lang: lang, issue: issue));

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

  /// Loads still running, keyed the same way.
  ///
  /// [_parsed] holds finished results only, so it cannot collapse callers that
  /// start together: two sync passes racing on the same issue both miss it and
  /// both go to the network for the same file. This is what makes the second
  /// one wait on the first instead.
  final _inFlight = <String, Future<List<Week>>>{};

  /// Returns the weeks of notebook [issue] (YYYYMM). Reads the cached EPUB when
  /// present (no network); otherwise downloads, caches and parses it. Throws an
  /// [Exception] with a readable message if the download/parse yields no weeks.
  Future<List<Week>> weeks(String issue, {String lang = 'S'}) async {
    final weeks = await _load(issue, lang);
    if (weeks.isEmpty) {
      throw Exception('No se encontraron semanas en el notebook $issue.');
    }
    return weeks;
  }

  /// Ensures notebook [issue] is in the cache, downloading it if missing.
  /// Returns the number of weeks. Used by the background sync (which owns the
  /// back-off policy), kept separate from the UI-facing [weeks].
  Future<int> ensureCached(String issue, {String lang = 'S'}) async =>
      (await _load(issue, lang)).length;

  /// The one path to a notebook's weeks: memo, then in-flight load, then disk,
  /// then the network. A failure drops the in-flight entry so the next caller
  /// retries rather than awaiting a dead future.
  Future<List<Week>> _load(String issue, String lang) {
    final key = '$issue.$lang';
    final memo = _parsed[key];
    if (memo != null) return Future.value(memo);
    // The callback body is a block on purpose: `Map.remove` hands back the
    // future being removed, and an arrow body would return it — `whenComplete`
    // waits on a returned future, so it would wait on itself and never settle.
    return _inFlight[key] ??= _read(issue, lang).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<List<Week>> _read(String issue, String lang) async {
    final cached = await _cache.readEpub(issue, lang);
    final bytes =
        cached ?? await MwbApi.downloadEpub(issue, lang: lang, client: _client);
    final weeks = await _parseEpubInBackground(bytes, lang, issue);
    // A freshly downloaded notebook with no weeks is a failed download, not an
    // empty notebook: it must not be cached, and the sync has to see it fail so
    // its back-off kicks in. A cached one that parses empty is left to the
    // caller — the catalog lists it with no weeks rather than breaking a pass.
    if (cached == null) {
      if (weeks.isEmpty) {
        throw Exception('No se encontraron semanas en el notebook $issue.');
      }
      await _cache.putEpub(issue, lang, bytes, weeks.length);
    }
    _parsed['$issue.$lang'] = weeks;
    return weeks;
  }
}
