import 'package:drift/drift.dart';

import '../../models/participant.dart';
import 'app_database.dart';
import 'tablas.dart';

part 'hermanos_dao.g.dart';

/// Operaciones sobre el directorio de hermanos. El filtrado fino (búsqueda
/// sin acentos, privilegio, congregación) se deriva en Dart desde
/// [watchTodos] — el dataset es pequeño y SQLite no colaciona acentos.
@DriftAccessor(tables: [Hermanos])
class HermanosDao extends DatabaseAccessor<AppDatabase>
    with _$HermanosDaoMixin {
  HermanosDao(super.db);

  Stream<List<Hermano>> watchTodos() {
    return (select(hermanos)
          ..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .watch();
  }

  Future<List<Hermano>> todos() {
    return (select(hermanos)
          ..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .get();
  }

  /// Inserta o actualiza por id. El caller es responsable de fijar
  /// `updatedAt` cuando el cambio es una edición de usuario.
  Future<void> upsert(Hermano h) =>
      into(hermanos).insertOnConflictUpdate(h.toInsertable());

  /// Marca uso desde el picker. SOLO toca `ultimoUso`: si tocara
  /// `updatedAt`, cada asignación pisaría ediciones reales al fusionar.
  Future<void> marcarUso(String id, DateTime cuando) {
    return (update(hermanos)..where((t) => t.id.equals(id)))
        .write(HermanosCompanion(ultimoUso: Value(cuando)));
  }

  Future<void> setActivo(String id, bool v, DateTime cuando) {
    return (update(hermanos)..where((t) => t.id.equals(id))).write(
      HermanosCompanion(activo: Value(v), updatedAt: Value(cuando)),
    );
  }

  Future<void> eliminar(String id) =>
      (delete(hermanos)..where((t) => t.id.equals(id))).go();

  /// Import en modo fusionar: upsert masivo en una transacción.
  Future<void> bulkUpsert(List<Hermano> hs) {
    return transaction(() async {
      await batch((b) {
        b.insertAllOnConflictUpdate(
            hermanos, [for (final h in hs) h.toInsertable()]);
      });
    });
  }

  /// Import en modo reemplazar: borra todo y carga el archivo (transacción:
  /// si la carga falla, no se pierde nada).
  Future<void> reemplazarTodo(List<Hermano> hs) {
    return transaction(() async {
      await delete(hermanos).go();
      await batch((b) {
        b.insertAll(hermanos, [for (final h in hs) h.toInsertable()]);
      });
    });
  }

  Future<int> contar() async {
    final c = countAll();
    final row = await (selectOnly(hermanos)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
