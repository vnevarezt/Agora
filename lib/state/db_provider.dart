import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/connection.dart';
import '../data/db/people_dao.dart';
import '../data/sync/hlc.dart';
import '../data/sync/sync_scribe.dart';
import '../i18n/strings.g.dart';
import 'app_settings.dart';
import 'auth_session.dart';

/// Encrypted local database. Only exists while the local session is unlocked:
/// INVARIANT — every widget/provider that watches [dbProvider] must live
/// below `AuthGate`, which unmounts them before `lock()` flips the state.
/// Locking disposes the provider (closing the DB); a read while locked is a
/// programming error and throws.
///
/// Tests override it with `AppDatabase(NativeDatabase.memory())` (no
/// keychain, no encryption).
final dbProvider = Provider<AppDatabase>((ref) {
  final dek = ref.watch(authSessionProvider
      .select((s) => s is SessionUnlocked ? s.dekHex : null));
  if (dek == null) {
    throw StateError(
        'dbProvider read while the local session is locked; every DB '
        'consumer must live below AuthGate.');
  }
  final db = AppDatabase(
    openEncryptedExecutor(dek),
    // Only used if the v1→v2 migration finds no usable congregation string.
    defaultCongregationName: t.congregation.defaultName,
  );
  ref.onDispose(db.close);
  return db;
});

final peopleDaoProvider =
    Provider<PeopleDao>((ref) => ref.watch(dbProvider).peopleDao);

/// Stamps every repository mutation with an HLC + outbox entry (phase 3).
final syncScribeProvider = Provider<SyncScribe>(
    (ref) => SyncScribe(ref.watch(dbProvider), HlcClock(deviceId())));
