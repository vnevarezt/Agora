import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/connection.dart';
import '../data/db/db_key_manager.dart';
import '../data/db/participants_dao.dart';

final dbKeyManagerProvider = Provider<DbKeyManager>((ref) => DbKeyManager());

/// Encrypted local database. Tests override it with
/// `AppDatabase(NativeDatabase.memory())` (no keychain, no encryption).
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openEncryptedExecutor(ref.watch(dbKeyManagerProvider)));
  ref.onDispose(db.close);
  return db;
});

final participantsDaoProvider =
    Provider<ParticipantsDao>((ref) => ref.watch(dbProvider).participantsDao);
