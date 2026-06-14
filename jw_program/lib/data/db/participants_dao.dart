import 'package:drift/drift.dart';

import '../../models/participant.dart';
import 'app_database.dart';
import 'tables.dart';

part 'participants_dao.g.dart';

/// Operaciones sobre el directorio de participants. El filtrado fino (búsqueda
/// sin acentos, privilegio, congregación) se deriva en Dart desde
/// [watchAll] — el dataset es pequeño y SQLite no colaciona acentos.
@DriftAccessor(tables: [Participants])
class ParticipantsDao extends DatabaseAccessor<AppDatabase>
    with _$ParticipantsDaoMixin {
  ParticipantsDao(super.db);

  Stream<List<Participant>> watchAll() {
    return (select(participants)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Participant>> all() {
    return (select(participants)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Inserta o actualiza por id. El caller es responsable de fijar
  /// `updatedAt` when el cambio es una edición de user.
  Future<void> upsert(Participant h) =>
      into(participants).insertOnConflictUpdate(h.toInsertable());

  /// Marca uso desde el picker. SOLO toca `ultimoUso`: si tocara
  /// `updatedAt`, cada asignación pisaría ediciones reales al fusionar.
  Future<void> markUsed(String id, DateTime when) {
    return (update(participants)..where((t) => t.id.equals(id)))
        .write(ParticipantsCompanion(lastUsed: Value(when)));
  }

  Future<void> setActive(String id, bool v, DateTime when) {
    return (update(participants)..where((t) => t.id.equals(id))).write(
      ParticipantsCompanion(active: Value(v), updatedAt: Value(when)),
    );
  }

  Future<void> eliminar(String id) =>
      (delete(participants)..where((t) => t.id.equals(id))).go();

  /// Import en modo fusionar: upsert masivo en una transacción.
  Future<void> bulkUpsert(List<Participant> hs) {
    return transaction(() async {
      await batch((b) {
        b.insertAllOnConflictUpdate(
            participants, [for (final h in hs) h.toInsertable()]);
      });
    });
  }

  /// Import en modo reemplazar: borra todo y carga el archivo (transacción:
  /// si la carga falla, no se pierde nada).
  Future<void> replaceAll(List<Participant> hs) {
    return transaction(() async {
      await delete(participants).go();
      await batch((b) {
        b.insertAll(participants, [for (final h in hs) h.toInsertable()]);
      });
    });
  }

  Future<int> contar() async {
    final c = countAll();
    final row = await (selectOnly(participants)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
