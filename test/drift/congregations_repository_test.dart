// The name a fresh install gives its first congregation is localized, so it
// has to be resolved when the congregation is actually created — not when the
// repository is built. The provider that builds it has no reason to rebuild on
// a language switch, so a captured String kept whatever language the app
// happened to start in.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/repos/congregations_repository.dart';
import 'package:agora/data/sync/hlc.dart';
import 'package:agora/data/sync/sync_scribe.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('ensureDefault names the congregation at creation time', () async {
    var language = 'Congregación';
    final repo = CongregationsRepository(
      db,
      SyncScribe(db, HlcClock('test0000')),
      defaultName: () => language,
    );

    final first = await repo.ensureDefault();
    expect((await repo.watchAll().first).single.name, 'Congregación');

    // A later switch must reach a congregation created after it.
    language = 'Congregation';
    expect(await repo.ensureDefault(), first,
        reason: 'an existing congregation is never renamed');
  });

  test('a language switch reaches the next fresh install', () async {
    var language = 'Congregación';
    final repo = CongregationsRepository(
      db,
      SyncScribe(db, HlcClock('test0000')),
      defaultName: () => language,
    );

    language = 'Congregation';
    await repo.ensureDefault();

    expect((await repo.watchAll().first).single.name, 'Congregation');
  });
}
