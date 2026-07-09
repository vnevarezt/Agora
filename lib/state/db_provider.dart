import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/connection.dart';
import '../data/db/participants_dao.dart';
import 'local_auth.dart';

/// Encrypted local database. Only exists while the local session is unlocked:
/// INVARIANT — every widget/provider that watches [dbProvider] must live
/// below `AuthGate`, which unmounts them before `lock()` flips the state.
/// Locking disposes the provider (closing the DB); a read while locked is a
/// programming error and throws.
///
/// Tests override it with `AppDatabase(NativeDatabase.memory())` (no
/// keychain, no encryption).
final dbProvider = Provider<AppDatabase>((ref) {
  final dek = ref.watch(localAuthProvider
      .select((s) => s is LocalAuthUnlocked ? s.dekHex : null));
  if (dek == null) {
    throw StateError(
        'dbProvider read while the local session is locked; every DB '
        'consumer must live below AuthGate.');
  }
  final db = AppDatabase(openEncryptedExecutor(dek));
  ref.onDispose(db.close);
  return db;
});

final participantsDaoProvider =
    Provider<ParticipantsDao>((ref) => ref.watch(dbProvider).participantsDao);
