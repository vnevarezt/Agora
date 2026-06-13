import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/hermano.dart';
import 'db_provider.dart';
import 'program_form.dart';

// INVARIANTE: las asignaciones del programa siguen siendo strings planos
// por ProgramRow.id en formProvider (contrato del PDF). La BD de hermanos
// es un directorio de personas, NO una clave foránea de las asignaciones.

/// Directorio completo, reactivo a la BD (sustituye al people_provider en
/// memoria). Los derivados de abajo filtran en Dart: el dataset es pequeño
/// y SQLite no colaciona acentos del español.
final hermanosTodosProvider = StreamProvider<List<Hermano>>(
  (ref) => ref.watch(hermanosDaoProvider).watchTodos(),
);

/// Activos ordenados por nombre normalizado (lista del picker).
final hermanosActivosProvider = Provider<List<Hermano>>((ref) {
  final todos = ref.watch(hermanosTodosProvider).asData?.value ?? const [];
  return todos.where((h) => h.activo).toList()
    ..sort((a, b) =>
        normalizarNombre(a.nombre).compareTo(normalizarNombre(b.nombre)));
});

/// Recientes persistentes (por `ultimoUso` desc), máx. 6.
final recientesProvider = Provider<List<Hermano>>((ref) {
  final activos = ref.watch(hermanosActivosProvider);
  final conUso = activos.where((h) => h.ultimoUso != null).toList()
    ..sort((a, b) => b.ultimoUso!.compareTo(a.ultimoUso!));
  return conUso.take(6).toList();
});

/// Congregaciones distintas (sugerencias del formulario de personas).
final congregacionesProvider = Provider<List<String>>((ref) {
  final todos = ref.watch(hermanosTodosProvider).asData?.value ?? const [];
  final distintas = <String>{
    for (final h in todos)
      if (h.congregacion.trim().isNotEmpty) h.congregacion.trim(),
  };
  return distintas.toList()..sort();
});

/// Filtro de la pantalla de gestión (puro, testeable).
List<Hermano> filtrarHermanos(
  List<Hermano> todos, {
  String query = '',
  Privilegio? privilegio,
  String? congregacion,
  bool incluirInactivos = false,
}) {
  final q = normalizarNombre(query);
  return [
    for (final h in todos)
      if ((incluirInactivos || h.activo) &&
          (privilegio == null || h.privilegio == privilegio) &&
          (congregacion == null || h.congregacion == congregacion) &&
          (q.isEmpty || normalizarNombre(h.nombre).contains(q)))
        h,
  ];
}

final hermanosAccionesProvider =
    Provider<HermanosAcciones>(HermanosAcciones.new);

/// Escrituras al directorio. `guardar` siempre sella `updatedAt` (ediciones
/// de usuario deciden la fusión de imports); `registrarUso` NO lo toca.
class HermanosAcciones {
  HermanosAcciones(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  /// Asignación hecha desde el picker: si el nombre ya existe (normalizado)
  /// solo marca uso; si no, alta mínima que queda como 'Incompleto' en la
  /// pantalla de gestión (sexo sin especificar).
  Future<void> registrarUso(String nombre) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return;
    final dao = _ref.read(hermanosDaoProvider);
    final ahora = DateTime.now().toUtc();
    final clave = normalizarNombre(limpio);
    for (final h in await dao.todos()) {
      if (normalizarNombre(h.nombre) == clave) {
        return dao.marcarUso(h.id, ahora);
      }
    }
    return dao.upsert(Hermano(
      id: _uuid.v4(),
      nombre: limpio,
      sexo: Sexo.noEspecificado,
      privilegio: Privilegio.publicador,
      congregacion: _ref.read(formProvider).cong,
      activo: true,
      notas: '',
      createdAt: ahora,
      updatedAt: ahora,
      ultimoUso: ahora,
    ));
  }

  Future<void> guardar(Hermano h) => _ref
      .read(hermanosDaoProvider)
      .upsert(h.copyWith(updatedAt: DateTime.now().toUtc()));

  Future<void> setActivo(String id, bool v) => _ref
      .read(hermanosDaoProvider)
      .setActivo(id, v, DateTime.now().toUtc());

  Future<void> eliminar(String id) =>
      _ref.read(hermanosDaoProvider).eliminar(id);
}
