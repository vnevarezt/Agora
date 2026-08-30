// Which workbooks the startup sync is allowed to fetch. It must not guess:
// before the congregation stream lands there is nothing to guess FROM, and
// guessing Spanish cost an English-only user a multi-megabyte download of a
// workbook they never meet in, kept on disk forever.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/mwb_cache.dart';
import 'package:agora/data/mwb_repository.dart';
import 'package:agora/data/mwb_store_native.dart';
import 'package:agora/domain/mwb_calendar.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/congregation_settings.dart';
import 'package:agora/models/notebook.dart';
import 'package:agora/models/week.dart';
import 'package:agora/state/dashboard_provider.dart';
import 'package:agora/state/db_provider.dart';
import 'package:agora/state/mwb_sync.dart';
import 'package:agora/state/weeks_provider.dart';

/// Records what the sync asked for, without touching disk or the network.
class _RecordingRepository extends MwbRepository {
  _RecordingRepository(super.cache);

  final requested = <String>[];

  /// Every fetch throws — the web build, where the browser cannot read the
  /// file at any policy, so no pass ever reports success.
  bool fails = false;

  @override
  Future<int> ensureCached(String issue, {String lang = 'S'}) async {
    requested.add('$issue.$lang');
    if (fails) throw const NotebookNotDownloadable();
    return 0;
  }

  @override
  Future<List<Week>> weeks(String issue, {String lang = 'S'}) async => const [];
}

void main() {
  late Directory tmp;
  late AppDatabase db;
  late _RecordingRepository repo;
  late ProviderContainer container;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mwb_sync_scope');
    db = AppDatabase(NativeDatabase.memory());
    repo = _RecordingRepository(MwbCache(store: DirectoryMwbStore(root: tmp)));
    container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        cacheProvider.overrideWithValue(
          MwbCache(store: DirectoryMwbStore(root: tmp)),
        ),
        repositoryProvider.overrideWithValue(repo),
      ],
    );
    // Riverpod 3 pauses unlistened providers, and the sync hangs off the
    // congregation stream.
    container.listen(mwbSyncProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// Fixed wait, for the assertions that are about something NOT happening.
  Future<void> settle() async {
    for (var i = 0; i < 25; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  /// Polls instead of guessing a duration: the whole suite runs in parallel,
  /// so a fixed wait long enough on an idle machine is not long enough on a
  /// busy one.
  Future<void> waitFor(bool Function() done, String what) async {
    for (var i = 0; i < 400; i++) {
      if (done()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('timed out waiting for $what');
  }

  test('fetches nothing while there is no congregation', () async {
    await settle();
    expect(repo.requested, isEmpty);
    expect(
      container.read(mwbSyncProvider).asData?.value.complete,
      isTrue,
      reason: 'nothing to sync is a complete state, not a failed one',
    );
  });

  test(
    'an English-only congregation never pulls the Spanish workbook',
    () async {
      await container
          .read(congregationsRepositoryProvider)
          .create(
            name: 'Riverside',
            number: '104772',
            settings: const CongregationSettings(meetingLanguage: 'english'),
          );
      await waitFor(() => repo.requested.isNotEmpty, 'the first fetch');

      expect(repo.requested, everyElement(endsWith('.E')));
    },
  );

  test('renaming a congregation does not re-run a single pass', () async {
    // The settings tab saves on a 400 ms debounce, so a rename is roughly one
    // write per keystroke. Each one used to relaunch every pass and blink the
    // dashboard's catalog indicator.
    final congregations = container.read(congregationsRepositoryProvider);
    final cong = await congregations.create(
      name: 'Riverside',
      number: '1',
      settings: const CongregationSettings(meetingLanguage: 'english'),
    );
    await waitFor(() => repo.requested.isNotEmpty, 'the first pass');
    await settle();
    final before = repo.requested.length;

    await congregations.update(
      cong.id,
      name: 'Riverside Park',
      number: '1',
      settings: const CongregationSettings(meetingLanguage: 'english'),
    );
    await settle();

    expect(
      repo.requested,
      hasLength(before),
      reason: 'only a change of language may relaunch a pass',
    );
  });

  test('switching the meeting language does re-run the sync', () async {
    final congregations = container.read(congregationsRepositoryProvider);
    final cong = await congregations.create(
      name: 'Riverside',
      number: '1',
      settings: const CongregationSettings(meetingLanguage: 'english'),
    );
    await waitFor(() => repo.requested.isNotEmpty, 'the English pass');
    expect(repo.requested, everyElement(endsWith('.E')));

    await congregations.update(
      cong.id,
      name: 'Riverside',
      number: '1',
      settings: const CongregationSettings(meetingLanguage: 'spanish'),
    );

    await waitFor(
      () => repo.requested.any((r) => r.endsWith('.S')),
      'the Spanish pass',
    );
  });

  test('a congregation in each language pulls both workbooks', () async {
    final repository = container.read(congregationsRepositoryProvider);
    await repository.create(
      name: 'Riverside',
      number: '1',
      settings: const CongregationSettings(meetingLanguage: 'english'),
    );
    await repository.create(
      name: 'Ribera',
      number: '2',
      settings: const CongregationSettings(meetingLanguage: 'spanish'),
    );
    Set<String> langs() => {for (final r in repo.requested) r.split('.').last};
    await waitFor(() => langs().length == 2, 'both languages');

    expect(langs(), {'S', 'E'});
  });

  group('catalogStatus', () {
    /// The catalog as the sync would leave it: one notebook per issue the
    /// coverage window asks for.
    void catalogue({required bool parsed}) {
      container.read(notebooksByLangProvider.notifier).setFrom({
        'S': [
          for (final issue in requiredIssues(DateTime.now()))
            Notebook(
              id: issue,
              weeks: parsed
                  ? const [(start: '2026-06-01', label: 'JUNIO 1-7')]
                  : const [],
            ),
        ],
      });
    }

    Future<void> spanishCongregation() async {
      await container
          .read(congregationsRepositoryProvider)
          .create(
            name: 'Ribera',
            number: '1',
            settings: const CongregationSettings(meetingLanguage: 'spanish'),
          );
      await waitFor(() => repo.requested.isNotEmpty, 'the first pass');
      await settle();
    }

    test('waits rather than reporting an all-clear it cannot back up', () {
      // The congregation stream has not landed, so nothing is known to be
      // needed — which is not the same as nothing being missing.
      expect(container.read(catalogStatusProvider), CatalogStatus.syncing);
    });

    test('a workbook catalogued with no weeks is not one on hand', () async {
      // buildCatalog lists an issue whose EPUB would not parse rather than
      // dropping it, so presence alone said "up to date" for a file nothing
      // can be built from.
      await spanishCongregation();
      catalogue(parsed: false);

      expect(container.read(catalogStatusProvider), CatalogStatus.incomplete);
      expect(
        container.read(missingNotebooksProvider),
        hasLength(requiredIssues(DateTime.now()).length),
      );
    });

    test(
      'a failed pass does not contradict a catalog that has everything',
      () async {
        // Web: every fetch fails by design, so the pass keeps reporting failure
        // long after the workbooks have been imported by hand.
        repo.fails = true;
        await spanishCongregation();
        expect(container.read(catalogStatusProvider), CatalogStatus.incomplete);

        catalogue(parsed: true);

        expect(container.read(catalogStatusProvider), CatalogStatus.ready);
        expect(container.read(missingNotebooksProvider), isEmpty);
      },
    );
  });

  group('offerableNotebooks', () {
    // The person most likely to be standing in the import modal is the one
    // whose account holds nothing yet — a fresh sign-in, or one whose first
    // cloud pull has not landed. Reading the list off the congregations meant
    // that person opened it to a numbered step with nothing under it.
    test(
      'offers the period even with no congregation to name a language',
      () async {
        await settle();

        final offered = container.read(offerableNotebooksProvider);
        expect(
          offered.map((n) => n.issue),
          containsAll(requiredIssues(DateTime.now())),
        );
        expect(
          container.read(requiredNotebooksProvider),
          isEmpty,
          reason:
              'requiring nothing is not the same as having nothing '
              'to offer',
        );
      },
    );

    test(
      'guesses the language from the app, and only until one is set',
      () async {
        LocaleSettings.setLocaleSync(AppLocale.en);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
        await settle();
        expect(
          container.read(offerableNotebooksProvider).map((n) => n.lang),
          everyElement('E'),
        );

        await container
            .read(congregationsRepositoryProvider)
            .create(
              name: 'Ribera',
              number: '1',
              settings: const CongregationSettings(meetingLanguage: 'spanish'),
            );
        await waitFor(
          () => container
              .read(offerableNotebooksProvider)
              .every((n) => n.lang == 'S'),
          'the congregation own language to take over',
        );
      },
    );
  });

  group('congregationWorkbookStatus', () {
    test('follows the catalog for the congregation own language', () async {
      final cong = await container
          .read(congregationsRepositoryProvider)
          .create(
            name: 'Riverside',
            number: '1',
            settings: const CongregationSettings(meetingLanguage: 'english'),
          );
      await waitFor(() => repo.requested.isNotEmpty, 'the first pass');

      // Nothing cached and no pass running: the honest answer is "not yet".
      await settle();
      expect(
        container.read(congregationWorkbookStatusProvider(cong.id)),
        WorkbookStatus.unavailable,
      );

      container.read(notebooksByLangProvider.notifier).setFrom({
        'E': [
          const Notebook(
            id: '202605',
            weeks: [(start: '2026-06-01', label: 'JUNE 1-7')],
          ),
        ],
      });

      expect(
        container.read(congregationWorkbookStatusProvider(cong.id)),
        WorkbookStatus.ready,
      );
    });

    test(
      'a Spanish catalog does not make an English congregation ready',
      () async {
        final cong = await container
            .read(congregationsRepositoryProvider)
            .create(
              name: 'Riverside',
              number: '1',
              settings: const CongregationSettings(meetingLanguage: 'english'),
            );
        await waitFor(() => repo.requested.isNotEmpty, 'the first pass');
        await settle();

        container.read(notebooksByLangProvider.notifier).setFrom({
          'S': [
            const Notebook(
              id: '202605',
              weeks: [(start: '2026-06-01', label: '1-7 DE JUNIO')],
            ),
          ],
        });

        expect(
          container.read(congregationWorkbookStatusProvider(cong.id)),
          WorkbookStatus.unavailable,
        );
      },
    );
  });
}
