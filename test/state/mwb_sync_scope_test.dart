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
import 'package:agora/models/congregation_settings.dart';
import 'package:agora/models/week.dart';
import 'package:agora/state/dashboard_provider.dart';
import 'package:agora/state/db_provider.dart';
import 'package:agora/state/mwb_sync.dart';
import 'package:agora/state/weeks_provider.dart';

/// Records what the sync asked for, without touching disk or the network.
class _RecordingRepository extends MwbRepository {
  _RecordingRepository(super.cache);

  final requested = <String>[];

  @override
  Future<int> ensureCached(String issue, {String lang = 'S'}) async {
    requested.add('$issue.$lang');
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
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      cacheProvider
          .overrideWithValue(MwbCache(store: DirectoryMwbStore(root: tmp))),
      repositoryProvider.overrideWithValue(repo),
    ]);
    // Riverpod 3 pauses unlistened providers, and the sync hangs off the
    // congregation stream.
    container.listen(mwbSyncProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> settle() async {
    for (var i = 0; i < 15; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test('fetches nothing while there is no congregation', () async {
    await settle();
    expect(repo.requested, isEmpty);
    expect(container.read(mwbSyncProvider).asData?.value.complete, isTrue,
        reason: 'nothing to sync is a complete state, not a failed one');
  });

  test('an English-only congregation never pulls the Spanish workbook',
      () async {
    await container.read(congregationsRepositoryProvider).create(
          name: 'Riverside',
          number: '104772',
          settings: const CongregationSettings(meetingLanguage: 'english'),
        );
    await settle();

    expect(repo.requested, isNotEmpty);
    expect(repo.requested, everyElement(endsWith('.E')));
  });

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
    await settle();
    final before = repo.requested.length;
    expect(before, greaterThan(0));

    await congregations.update(
      cong.id,
      name: 'Riverside Park',
      number: '1',
      settings: const CongregationSettings(meetingLanguage: 'english'),
    );
    await settle();

    expect(repo.requested, hasLength(before),
        reason: 'only a change of language may relaunch a pass');
  });

  test('switching the meeting language does re-run the sync', () async {
    final congregations = container.read(congregationsRepositoryProvider);
    final cong = await congregations.create(
      name: 'Riverside',
      number: '1',
      settings: const CongregationSettings(meetingLanguage: 'english'),
    );
    await settle();
    expect(repo.requested, everyElement(endsWith('.E')));

    await congregations.update(
      cong.id,
      name: 'Riverside',
      number: '1',
      settings: const CongregationSettings(meetingLanguage: 'spanish'),
    );
    await settle();

    expect(repo.requested.where((r) => r.endsWith('.S')), isNotEmpty);
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
    await settle();

    final langs = {for (final r in repo.requested) r.split('.').last};
    expect(langs, {'S', 'E'});
  });
}
