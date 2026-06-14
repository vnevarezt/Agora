import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

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
  /// [root] is injectable for tests; in the app it defaults to the application
  /// support directory (same base as the encrypted DB).
  MwbCache({Directory? root}) : _root = root;

  final Directory? _root;
  Directory? _resolved;

  static const _manifestName = 'manifest.json';

  Future<Directory> _dir() async {
    if (_resolved != null) return _resolved!;
    final base = _root ?? await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}mwb_cache');
    await dir.create(recursive: true);
    return _resolved = dir;
  }

  String _epubName(String issue, String lang) => '$issue.$lang.epub';

  Future<File> _file(String name) async =>
      File('${(await _dir()).path}${Platform.pathSeparator}$name');

  /// Reads the manifest. Returns an empty manifest if missing or corrupt.
  Future<CacheManifest> readManifest() async {
    final f = await _file(_manifestName);
    if (!await f.exists()) return const CacheManifest();
    try {
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return CacheManifest.fromJson(json);
    } catch (_) {
      return const CacheManifest();
    }
  }

  /// Writes the manifest atomically (.tmp + rename) to survive abrupt exits.
  Future<void> _writeManifest(CacheManifest m) async {
    final f = await _file(_manifestName);
    final tmp = await _file('$_manifestName.tmp');
    await tmp.writeAsString(jsonEncode(m.toJson()), flush: true);
    await tmp.rename(f.path);
  }

  bool has(CacheManifest m, String issue, String lang) =>
      m.entries.any((e) => e.issue == issue && e.lang == lang);

  /// Cached EPUB bytes for [issue]/[lang], or null if not present.
  Future<Uint8List?> readEpub(String issue, String lang) async {
    final f = await _file(_epubName(issue, lang));
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }

  /// Stores [bytes], records the entry in the manifest and clears any prior
  /// failure for this issue.
  Future<void> putEpub(
      String issue, String lang, Uint8List bytes, int weekCount) async {
    final name = _epubName(issue, lang);
    await (await _file(name)).writeAsBytes(bytes, flush: true);

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
