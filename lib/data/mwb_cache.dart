import 'dart:convert';
import 'dart:typed_data';

import 'mwb_store.dart';
import 'mwb_store_platform.dart';

/// One cached notebook EPUB.
class CacheEntry {
  final String issue;
  final String lang;
  final String fileName;
  final DateTime downloadedAt;
  final int weekCount;

  const CacheEntry({
    required this.issue,
    required this.lang,
    required this.fileName,
    required this.downloadedAt,
    required this.weekCount,
  });

  Map<String, dynamic> toJson() => {
        'issue': issue,
        'lang': lang,
        'fileName': fileName,
        'downloadedAt': downloadedAt.toIso8601String(),
        'weekCount': weekCount,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> j) => CacheEntry(
        issue: j['issue'] as String,
        lang: j['lang'] as String,
        fileName: j['fileName'] as String,
        downloadedAt: DateTime.parse(j['downloadedAt'] as String),
        weekCount: (j['weekCount'] as num).toInt(),
      );
}

/// A failed download attempt (e.g. a future issue not published yet). Used to
/// back off and avoid retrying on every launch.
class FailedAttempt {
  final String issue;
  final String lang;
  final DateTime lastAttempt;
  final String? message;

  const FailedAttempt({
    required this.issue,
    required this.lang,
    required this.lastAttempt,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'issue': issue,
        'lang': lang,
        'lastAttempt': lastAttempt.toIso8601String(),
        'message': message,
      };

  factory FailedAttempt.fromJson(Map<String, dynamic> j) => FailedAttempt(
        issue: j['issue'] as String,
        lang: j['lang'] as String,
        lastAttempt: DateTime.parse(j['lastAttempt'] as String),
        message: j['message'] as String?,
      );
}

/// On-disk cache index (app-owned metadata, hence JSON).
class CacheManifest {
  final List<CacheEntry> entries;
  final List<FailedAttempt> failures;

  const CacheManifest({this.entries = const [], this.failures = const []});

  Map<String, dynamic> toJson() => {
        'version': 1,
        'entries': [for (final e in entries) e.toJson()],
        'failures': [for (final f in failures) f.toJson()],
      };

  factory CacheManifest.fromJson(Map<String, dynamic> j) => CacheManifest(
        entries: [
          for (final e in (j['entries'] as List? ?? const []))
            CacheEntry.fromJson(e as Map<String, dynamic>),
        ],
        failures: [
          for (final f in (j['failures'] as List? ?? const []))
            FailedAttempt.fromJson(f as Map<String, dynamic>),
        ],
      );
}

/// Disk cache for downloaded notebook EPUBs plus a JSON manifest. Lets the app
/// read notebooks offline and download each one only once.
///
/// Raw EPUB bytes are cached (re-parsed on demand with [parseEpub]) rather than
/// parsed `Week`s: the EPUB is the canonical artifact, so a parser change never
/// needs a cache migration. The manifest is app-owned metadata.
class MwbCache {
  /// [store] is injectable for tests; in the app it defaults to whatever this
  /// platform provides — a directory under application support on native, an
  /// IndexedDB object store on web.
  MwbCache({MwbStore? store}) : _store = store ?? defaultMwbStore();

  final MwbStore _store;

  static const _manifestName = 'manifest.json';

  String _epubName(String issue, String lang) => '$issue.$lang.epub';

  /// Reads the manifest. Returns an empty manifest if missing or corrupt.
  Future<CacheManifest> readManifest() async {
    final raw = await _store.readString(_manifestName);
    if (raw == null) return const CacheManifest();
    try {
      return CacheManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const CacheManifest();
    }
  }

  /// Writes the manifest. [MwbStore.writeString] is atomic, so an abrupt exit
  /// cannot leave the cache describing EPUBs that are not there.
  Future<void> _writeManifest(CacheManifest m) =>
      _store.writeString(_manifestName, jsonEncode(m.toJson()));

  bool has(CacheManifest m, String issue, String lang) =>
      m.entries.any((e) => e.issue == issue && e.lang == lang);

  /// Cached EPUB bytes for [issue]/[lang], or null if not present.
  Future<Uint8List?> readEpub(String issue, String lang) =>
      _store.readBytes(_epubName(issue, lang));

  /// Stores [bytes], records the entry in the manifest and clears any prior
  /// failure for this issue.
  Future<void> putEpub(
      String issue, String lang, Uint8List bytes, int weekCount) async {
    final name = _epubName(issue, lang);
    await _store.writeBytes(name, bytes);

    final m = await readManifest();
    await _writeManifest(CacheManifest(
      entries: [
        for (final e in m.entries)
          if (!(e.issue == issue && e.lang == lang)) e,
        CacheEntry(
          issue: issue,
          lang: lang,
          fileName: name,
          downloadedAt: DateTime.now(),
          weekCount: weekCount,
        ),
      ],
      failures: [
        for (final fa in m.failures)
          if (!(fa.issue == issue && fa.lang == lang)) fa,
      ],
    ));
  }

  /// Records/updates the last failed attempt for back-off. [at] defaults to now
  /// (injectable for deterministic tests).
  Future<void> recordFailure(String issue, String lang, String message,
      {DateTime? at}) async {
    final m = await readManifest();
    await _writeManifest(CacheManifest(
      entries: m.entries,
      failures: [
        for (final fa in m.failures)
          if (!(fa.issue == issue && fa.lang == lang)) fa,
        FailedAttempt(
          issue: issue,
          lang: lang,
          lastAttempt: at ?? DateTime.now(),
          message: message,
        ),
      ],
    ));
  }

  /// True if [issue] failed less than [backoff] ago (so it should be skipped).
  /// [now] is injectable for deterministic tests.
  bool inBackoff(CacheManifest m, String issue, String lang,
      {Duration backoff = const Duration(days: 1), DateTime? now}) {
    final ref = now ?? DateTime.now();
    for (final fa in m.failures) {
      if (fa.issue == issue && fa.lang == lang) {
        return ref.difference(fa.lastAttempt) < backoff;
      }
    }
    return false;
  }
}
