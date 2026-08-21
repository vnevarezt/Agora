// ProgramReconciler: keeps a program's content in the language its
// congregation actually meets in, repairs rows whose identity is still a
// localized label, and never trades good content for none.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/mwb_cache.dart';
import 'package:agora/data/mwb_repository.dart';
import 'package:agora/data/mwb_store_native.dart';
import 'package:agora/models/congregation.dart';
import 'package:agora/models/congregation_settings.dart';
import 'package:agora/models/hall.dart';
import 'package:agora/models/week.dart';
import 'package:agora/state/dashboard_provider.dart';
import 'package:agora/state/db_provider.dart';
import 'package:agora/state/mwb_sync.dart';
import 'package:agora/state/program_reconciler.dart';
import 'package:agora/state/weeks_provider.dart';

/// A one-week workbook for mwb_202605. 1 June 2026 is a Monday, so both
/// headings below resolve to the same 2026-06-01 — which is the property the
/// whole reconciler stands on.
Uint8List _epub(String heading, String talkMarker) {
  final xhtml = '<h1>$heading</h1>'
      '<h2 class="du-color--teal">TESOROS</h2>'
      '<h3 class="p">1. Lectura (4 mins.)</h3>'
      '<h2 class="du-color--gold">SEAMOS</h2>'
      '<h3 class="p">2. $talkMarker (5 mins.)</h3>';
  final archive = Archive()
    ..addFile(ArchiveFile.string('OEBPS/000000001.xhtml', xhtml));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _spanishLabel = '1-7 DE JUNIO';
const _englishLabel = 'JUNE 1-7';
const _monday = '2026-06-01';

void main() {
  late Directory tmp;
  late AppDatabase db;
  late MwbCache cache;
  late MwbRepository repo;
  late ProviderContainer container;

  final noNetwork = MockClient((_) async => fail('the reconciler used the network'));

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('reconciler');
    db = AppDatabase(NativeDatabase.memory());
    cache = MwbCache(store: DirectoryMwbStore(root: tmp));
    repo = MwbRepository(cache, client: noNetwork);
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      cacheProvider.overrideWithValue(cache),
      repositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// Caches the workbooks named and republishes the catalog from them, the way
  /// the sync does.
  Future<void> cacheWorkbooks({bool spanish = false, bool english = false}) async {
    if (spanish) {
      await cache.putEpub('202605', 'S', _epub(_spanishLabel, 'Discurso'), 1);
    }
    if (english) {
      await cache.putEpub('202605', 'E', _epub(_englishLabel, 'Talk'), 1);
    }
    container
        .read(notebooksByLangProvider.notifier)
        .setFrom(await buildCatalog(cache, repo));
  }

  Future<Congregation> congregation(String meetingLanguage) =>
      container.read(congregationsRepositoryProvider).create(
            name: 'Riverside',
            number: '1',
            settings: CongregationSettings(meetingLanguage: meetingLanguage),
          );

  Future<void> switchLanguageTo(Congregation cong, String meetingLanguage) =>
      container.read(congregationsRepositoryProvider).update(
            cong.id,
            name: cong.name,
            number: cong.number,
            settings: CongregationSettings(meetingLanguage: meetingLanguage),
          );

  Future<ProgramRecord> onlyProgram(String projectId) async =>
      (await container.read(programsRepositoryProvider).byProject(projectId))
          .single;

  test('fills a fresh project in its congregation language', () async {
    await cacheWorkbooks(spanish: true, english: true);
    final cong = await congregation('english');
    final projectId = await container
        .read(projectsRepositoryProvider)
        .create(name: 'June', congregationId: cong.id, weeks: [_englishLabel]);

    final report =
        await container.read(programReconcilerProvider).reconcileProject(projectId);

    expect(report.filled, 1);
    expect(report.complete, isTrue);
    final program = await onlyProgram(projectId);
    expect(program.contentLang, 'E');
    expect(program.weekStart, _monday);
  });

  test('a language switch rewrites the content and keeps the names', () async {
    await cacheWorkbooks(spanish: true, english: true);
    final cong = await congregation('spanish');
    final projectId = await container
        .read(projectsRepositoryProvider)
        .create(name: 'Junio', congregationId: cong.id, weeks: [_spanishLabel]);
    final reconciler = container.read(programReconcilerProvider);
    await reconciler.reconcileProject(projectId);

    // The user assigns somebody. Slot keys are positional (`te0`), not derived
    // from any title, which is exactly why this can survive what follows.
    final program = await onlyProgram(projectId);
    await container.read(programsRepositoryProvider).saveSlotNames(
        programId: program.id,
        slotKey: 'te0',
        hall: Hall.main,
        names: ['Vicente N.']);

    await switchLanguageTo(cong, 'english');
    final report = await reconciler.reconcileCongregation(cong.id);

    expect(report.filled, 1);
    final after = await onlyProgram(projectId);
    expect(after.contentLang, 'E');
    expect(Week.fromJson(_decode(after.contentJson!)).date, _englishLabel,
        reason: 'the printed heading follows the meeting language');
    expect(after.weekStart, _monday, reason: 'the identity never moved');

    final assignments = await container
        .read(programsRepositoryProvider)
        .assignmentsByPrograms([after.id]);
    expect(assignments.single.displayName, 'Vicente N.',
        reason: 'changing language must not cost the user their work');
  });

  test('without the new workbook the old content stays and is pending',
      () async {
    await cacheWorkbooks(spanish: true);
    final cong = await congregation('spanish');
    final projectId = await container
        .read(projectsRepositoryProvider)
        .create(name: 'Junio', congregationId: cong.id, weeks: [_spanishLabel]);
    final reconciler = container.read(programReconcilerProvider);
    await reconciler.reconcileProject(projectId);

    await switchLanguageTo(cong, 'english');
    final report = await reconciler.reconcileCongregation(cong.id);

    expect(report.pending, 1);
    expect(report.complete, isFalse);
    final after = await onlyProgram(projectId);
    expect(after.contentLang, 'S',
        reason: 'good content is never traded for none');
    expect(Week.fromJson(_decode(after.contentJson!)).date, _spanishLabel);
  });

  test('a legacy row is repaired through the catalog of any language',
      () async {
    // The row a v5 install leaves behind: a Spanish label, no identity, no
    // language — under a congregation that now meets in English.
    await cacheWorkbooks(spanish: true, english: true);
    final cong = await congregation('english');
    final projectId = await container
        .read(projectsRepositoryProvider)
        .create(name: 'June', congregationId: cong.id, weeks: [_spanishLabel]);
    final program = await onlyProgram(projectId);
    expect(program.weekStart, isNull);
    expect(program.contentLang, isNull);

    final report =
        await container.read(programReconcilerProvider).reconcileProject(projectId);

    expect(report.filled, 1);
    final after = await onlyProgram(projectId);
    expect(after.weekStart, _monday,
        reason: 'the Spanish catalog is what identifies the week');
    expect(after.contentLang, 'E',
        reason: 'and the English workbook is what fills it');
  });

  test('an identity is recorded even when the content cannot be', () async {
    // Only the Spanish workbook is cached, but the congregation meets in
    // English: the week can be identified, just not filled.
    await cacheWorkbooks(spanish: true);
    final cong = await congregation('english');
    final projectId = await container
        .read(projectsRepositoryProvider)
        .create(name: 'June', congregationId: cong.id, weeks: [_spanishLabel]);

    final report =
        await container.read(programReconcilerProvider).reconcileProject(projectId);

    expect(report.pending, 1);
    final after = await onlyProgram(projectId);
    expect(after.weekStart, _monday,
        reason: 'the date is language-free, so it stays true either way');
    expect(after.contentJson, isNull);
  });

  test('a second pass over a project already in step writes nothing',
      () async {
    await cacheWorkbooks(spanish: true);
    final cong = await congregation('spanish');
    final projectId = await container
        .read(projectsRepositoryProvider)
        .create(name: 'Junio', congregationId: cong.id, weeks: [_spanishLabel]);
    final reconciler = container.read(programReconcilerProvider);

    expect((await reconciler.reconcileProject(projectId)).filled, 1);
    expect((await reconciler.reconcileProject(projectId)).filled, 0,
        reason: 'reconciling is idempotent');
  });

  test('a week no cached workbook knows stays pending, not broken', () async {
    await cacheWorkbooks(spanish: true);
    final cong = await congregation('spanish');
    final projectId = await container
        .read(projectsRepositoryProvider)
        .create(name: 'Junio', congregationId: cong.id, weeks: ['8-14 DE JUNIO']);

    final report =
        await container.read(programReconcilerProvider).reconcileProject(projectId);

    expect(report.pending, 1);
    final after = await onlyProgram(projectId);
    expect(after.weekStart, isNull);
    expect(after.contentJson, isNull);
  });

  group('congregationLanguageWatcher', () {
    /// The watcher only reacts while something holds it, exactly as
    /// `_SyncBootstrap` does in the app.
    void mount() =>
        container.listen(congregationLanguageWatcherProvider, (_, _) {});

    /// Polls rather than guessing a delay: the watcher fires through a stream
    /// tick and a fire-and-forget future, and the suite runs in parallel.
    Future<void> waitForLang(String projectId, String lang) async {
      for (var i = 0; i < 400; i++) {
        if ((await onlyProgram(projectId)).contentLang == lang) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('timed out waiting for the content to become $lang');
    }

    test('switching the language rewrites the programs with no prompting',
        () async {
      await cacheWorkbooks(spanish: true, english: true);
      mount();
      final cong = await congregation('spanish');
      final projectId = await container.read(projectsRepositoryProvider).create(
          name: 'Junio', congregationId: cong.id, weeks: [_spanishLabel]);
      await container
          .read(programReconcilerProvider)
          .reconcileProject(projectId);

      await switchLanguageTo(cong, 'english');

      await waitForLang(projectId, 'E');
    });

    test('a switch made before the workbook lands is retried when it does',
        () async {
      await cacheWorkbooks(spanish: true);
      mount();
      final cong = await congregation('spanish');
      final projectId = await container.read(projectsRepositoryProvider).create(
          name: 'Junio', congregationId: cong.id, weeks: [_spanishLabel]);
      await container
          .read(programReconcilerProvider)
          .reconcileProject(projectId);

      await switchLanguageTo(cong, 'english');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect((await onlyProgram(projectId)).contentLang, 'S',
          reason: 'nothing to switch to yet, so nothing is lost');

      // The sync finishes and republishes the catalog.
      await cacheWorkbooks(english: true);

      await waitForLang(projectId, 'E');
    });

    test('renaming a congregation reconciles nothing', () async {
      await cacheWorkbooks(spanish: true, english: true);
      mount();
      final cong = await congregation('spanish');
      final projectId = await container.read(projectsRepositoryProvider).create(
          name: 'Junio', congregationId: cong.id, weeks: [_spanishLabel]);
      await container
          .read(programReconcilerProvider)
          .reconcileProject(projectId);

      await container.read(congregationsRepositoryProvider).update(
            cong.id,
            name: 'Ribera',
            number: cong.number,
            settings: const CongregationSettings(meetingLanguage: 'spanish'),
          );
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect((await onlyProgram(projectId)).contentLang, 'S');
    });
  });
}

Map<String, dynamic> _decode(String json) =>
    jsonDecode(json) as Map<String, dynamic>;
