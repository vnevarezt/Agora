import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agora/data/mwb_cache.dart';
import 'package:agora/data/mwb_store_native.dart';
import 'package:agora/data/mwb_repository.dart';
import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/repos/programs_repository.dart';
import 'package:agora/data/sync/hlc.dart';
import 'package:agora/data/sync/sync_scribe.dart';
import 'package:agora/models/notebook.dart';
import 'package:agora/state/mwb_sync.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';

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
    cache = MwbCache(store: DirectoryMwbStore(root: tmp));
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

    final report = await runMwbSync(
      cache: cache,
      repository: repo,
      now: now,
      monthsAhead: 2,
    );

    expect(log, isEmpty, reason: 'no debe tocar la red si ya hay cobertura');
    expect(report.skippedCached, ['202605', '202607']);
    expect(report.downloaded, isEmpty);

    final catalog = await buildCatalog(cache, repo);
    expect(catalog['S']!.map((n) => n.id), ['202605', '202607']);
  });

  test('downloads only the missing issue', () async {
    final now = DateTime(2026, 6, 14);
    await cache.putEpub('202605', 'S', fakeBytes, 1);
    final log = <String>[];
    final repo = MwbRepository(cache, client: client(log, {'202607'}));

    final report = await runMwbSync(
      cache: cache,
      repository: repo,
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
        cache: cache, repository: repo, now: now);
    expect(ok.complete, isTrue);
  });

  test('backs off a future issue that is not published yet', () async {
    final now = DateTime(2026, 6, 14);
    await cache.putEpub('202605', 'S', fakeBytes, 1);
    final log = <String>[];
    final repo = MwbRepository(cache, client: client(log, const {}));

    final r1 = await runMwbSync(
        cache: cache, repository: repo, now: now);
    expect(r1.failed.keys, ['202607']);
    expect(r1.complete, isFalse, reason: 'falta un cuaderno -> incompleto');
    expect(log, ['202607']);

    // Same day: skipped by back-off, no new request.
    final r2 = await runMwbSync(
        cache: cache, repository: repo, now: now);
    expect(r2.skippedBackoff, ['202607']);
    expect(log, ['202607']);

    // Two days later: retried once.
    final r3 = await runMwbSync(
        cache: cache,
        repository: repo,
          now: now.add(const Duration(days: 2)));
    expect(log, ['202607', '202607']);
    expect(r3.failed.keys, ['202607']);
  });

  test('the catalog keeps every cached language, not just the synced one',
      () async {
    // A congregation switching from Spanish to English used to make the
    // Spanish catalog vanish: the sync rebuilt the whole map from the
    // languages of that pass alone, while the EPUBs stayed on disk and the
    // projects built from them still needed their weeks.
    final now = DateTime(2026, 6, 14);
    await cache.putEpub('202605', 'S', fakeBytes, 1);
    await cache.putEpub('202605', 'E', fakeBytes, 1);
    await cache.putEpub('202607', 'E', fakeBytes, 1);
    final repo = MwbRepository(cache, client: client([], const {}));

    await runMwbSync(
        cache: cache, repository: repo, lang: 'E', now: now, monthsAhead: 2);
    final catalog = await buildCatalog(cache, repo);

    expect(catalog.keys, containsAll(['S', 'E']));
    expect(catalog['S']!.map((n) => n.id), ['202605']);
    expect(catalog['E']!.map((n) => n.id), ['202605', '202607']);
  });

  group('purgeUnneededIssues', () {
    late AppDatabase db;
    late ProgramsRepository programs;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      programs = ProgramsRepository(db, SyncScribe(db, HlcClock('test0000')));
    });
    tearDown(() => db.close());

    /// A project with one program, so the purge has something to protect.
    Future<void> seedProgram(WeekRef week) async {
      final now = DateTime.utc(2026, 1, 10);
      await db.into(db.congregations).insert(CongregationsCompanion.insert(
          id: 'c1', name: 'N', color: 1, createdAt: now, updatedAt: now));
      await db.into(db.projects).insert(ProjectsCompanion.insert(
          id: 'pr1',
          congregationId: 'c1',
          name: 'P',
          createdAt: now,
          updatedAt: now));
      await db.into(db.programs).insert(ProgramsCompanion.insert(
            id: 'pg1',
            projectId: 'pr1',
            programTypeId: 'mwb-s140',
            date: week.label,
            weekStart:
                week.start.isEmpty ? const Value.absent() : Value(week.start),
            createdAt: now,
            updatedAt: now,
          ));
    }

    Future<Set<String>> cachedIssues() async =>
        {for (final e in (await cache.readManifest()).entries) e.issue};

    test('drops an issue nothing needs any more', () async {
      final now = DateTime(2026, 6, 14);
      await cache.putEpub('202601', 'S', fakeBytes, 1); // long past
      await cache.putEpub('202605', 'S', fakeBytes, 1); // in the window

      final removed = await purgeUnneededIssues(
          cache: cache, programs: programs, now: now, monthsAhead: 2);

      expect(removed, 1);
      expect(await cachedIssues(), {'202605'});
      expect(await cache.readEpub('202601', 'S'), isNull,
          reason: 'the bytes go too, not just the manifest entry');
    });

    test('keeps an out-of-window issue an alive program still needs',
        () async {
      final now = DateTime(2026, 6, 14);
      await cache.putEpub('202601', 'S', fakeBytes, 1);
      await seedProgram((start: '2026-02-02', label: '2-8 DE FEBRERO'));

      final removed = await purgeUnneededIssues(
          cache: cache, programs: programs, now: now, monthsAhead: 2);

      expect(removed, 0);
      expect(await cachedIssues(), contains('202601'));
    });

    test('keeps every language of an issue, not just the one in use',
        () async {
      // The Spanish workbook is what identifies a pre-v6 row even for a
      // congregation that now meets in English, so it must survive.
      final now = DateTime(2026, 6, 14);
      await cache.putEpub('202605', 'S', fakeBytes, 1);
      await cache.putEpub('202605', 'E', fakeBytes, 1);

      await purgeUnneededIssues(
          cache: cache, programs: programs, now: now, monthsAhead: 2);

      final manifest = await cache.readManifest();
      expect({for (final e in manifest.entries) e.lang}, {'S', 'E'});
    });

    test('does not run at all while a program is still unidentified',
        () async {
      final now = DateTime(2026, 6, 14);
      await cache.putEpub('202601', 'S', fakeBytes, 1);
      await seedProgram((start: '', label: '2-8 DE FEBRERO'));

      final removed = await purgeUnneededIssues(
          cache: cache, programs: programs, now: now, monthsAhead: 2);

      expect(removed, 0,
          reason: 'there is no telling which workbook that row needs');
      expect(await cachedIssues(), contains('202601'));
    });
  });
}
