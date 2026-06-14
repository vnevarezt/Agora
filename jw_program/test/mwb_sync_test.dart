import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jw_program/data/mwb_cache.dart';
import 'package:jw_program/data/mwb_repository.dart';
import 'package:jw_program/models/notebook.dart';
import 'package:jw_program/state/mwb_sync.dart';

/// Minimal but valid mwb EPUB: one weekly XHTML with one numbered part, so
/// [parseEpub] returns a single week.
Uint8List _fakeEpub() {
  const xhtml = '<h1>1-7 DE JUNIO DE 2026</h1>'
      '<h2 class="du-color--teal">TESOROS</h2>'
      '<h3 class="p">1. Discurso (10 mins.)</h3>';
  final archive = Archive()
    ..addFile(ArchiveFile.string('OEBPS/000000001.xhtml', xhtml));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late Directory tmp;
  late MwbCache cache;
  final fakeBytes = _fakeEpub();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mwb_sync_test');
    cache = MwbCache(root: tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// MockClient that logs every media-links lookup by issue and serves the EPUB
  /// only for issues listed in [available] (others 404, as future issues do).
  http.Client client(List<String> log, Set<String> available) {
    return MockClient((req) async {
      if (req.url.host == 'app.jw-cdn.org') {
        final issue = req.url.queryParameters['issue']!;
        log.add(issue);
        if (!available.contains(issue)) return http.Response('not found', 404);
        return http.Response(
          jsonEncode({
            'files': {
              'S': {
                'EPUB': [
                  {
                    'file': {'url': 'https://ex.test/$issue.epub'}
                  }
                ]
              }
            },
            'formattedDate': 'x',
          }),
          200,
        );
      }
      return http.Response.bytes(fakeBytes, 200);
    });
  }

  test('makes NO network request when coverage is already cached', () async {
    final now = DateTime(2026, 6, 14);
    for (final issue in ['202605', '202607']) {
      await cache.putEpub(issue, 'S', fakeBytes, 1);
    }
    final log = <String>[];
    final repo = MwbRepository(cache, client: client(log, const {}));

    var catalog = <Notebook>[];
    final report = await runMwbSync(
      cache: cache,
      repository: repo,
      onCatalog: (n) => catalog = n,
      now: now,
      monthsAhead: 2,
    );

    expect(log, isEmpty, reason: 'no debe tocar la red si ya hay cobertura');
    expect(report.skippedCached, ['202605', '202607']);
    expect(report.downloaded, isEmpty);
    expect(catalog.map((n) => n.id), ['202605', '202607']);
  });

  test('downloads only the missing issue', () async {
    final now = DateTime(2026, 6, 14);
    await cache.putEpub('202605', 'S', fakeBytes, 1);
    final log = <String>[];
    final repo = MwbRepository(cache, client: client(log, {'202607'}));

    final report = await runMwbSync(
      cache: cache,
      repository: repo,
      onCatalog: (_) {},
      now: now,
      monthsAhead: 2,
    );

    expect(report.downloaded, ['202607']);
    expect(report.skippedCached, ['202605']);
    expect(log, ['202607'], reason: 'solo el issue faltante pide a la red');
    expect(await cache.readEpub('202607', 'S'), isNotNull);
  });

  test('report.complete refleja cobertura total vs. faltante', () async {
    final now = DateTime(2026, 6, 14);
    for (final issue in ['202605', '202607']) {
      await cache.putEpub(issue, 'S', fakeBytes, 1);
    }
    final repo = MwbRepository(cache, client: client([], const {}));
    final ok = await runMwbSync(
        cache: cache, repository: repo, onCatalog: (_) {}, now: now);
    expect(ok.complete, isTrue);
  });

  test('backs off a future issue that is not published yet', () async {
    final now = DateTime(2026, 6, 14);
    await cache.putEpub('202605', 'S', fakeBytes, 1);
    final log = <String>[];
    final repo = MwbRepository(cache, client: client(log, const {}));

    final r1 = await runMwbSync(
        cache: cache, repository: repo, onCatalog: (_) {}, now: now);
    expect(r1.failed.keys, ['202607']);
    expect(r1.complete, isFalse, reason: 'falta un cuaderno -> incompleto');
    expect(log, ['202607']);

    // Same day: skipped by back-off, no new request.
    final r2 = await runMwbSync(
        cache: cache, repository: repo, onCatalog: (_) {}, now: now);
    expect(r2.skippedBackoff, ['202607']);
    expect(log, ['202607']);

    // Two days later: retried once.
    final r3 = await runMwbSync(
        cache: cache,
        repository: repo,
        onCatalog: (_) {},
        now: now.add(const Duration(days: 2)));
    expect(log, ['202607', '202607']);
    expect(r3.failed.keys, ['202607']);
  });
}
