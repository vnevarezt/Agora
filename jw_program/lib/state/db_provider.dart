import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/connection.dart';
import '../data/db/db_key_manager.dart';
import '../data/db/participants_dao.dart';

final dbKeyManagerProvider = Provider<DbKeyManager>((ref) => DbKeyManager());

/// Base de datos local cifrada. En tests se hace override con
/// `AppDatabase(NativeDatabase.memory())` (sin llavero ni cifrado).
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(abrirEjecutorCifrado(ref.watch(dbKeyManagerProvider)));
  ref.onDispose(db.close);
  return db;
});

final participantsDaoProvider =
    Provider<ParticipantsDao>((ref) => ref.watch(dbProvider).participantsDao);
