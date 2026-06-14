import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/participant.dart';
import 'program_form.dart';

// INVARIANTE: las asignaciones del programa siguen siendo strings planos
// por ProgramRow.id en formProvider (contrato del PDF). El directorio de
// hermanos es solo un catálogo de personas, NO una clave foránea.
//
// SOLO UI: directorio en memoria efímera (sin BD ni persistencia). El
// andamiaje de la BD cifrada (data/db/*, db_provider) queda latente, sin que
// ninguna ruta activa lo use, listo para reconectar en el futuro.

/// Directorio en memoria. Arranca vacío; las altas/ediciones viven solo en la
/// sesión. Mantiene la semántica que tenía la BD: `markUsed` toca `ultimoUso`
/// sin alterar `updatedAt`.
class ParticipantsController extends Notifier<List<Participant>> {
  @override
  List<Participant> build() => const [];

  void upsert(Participant h) {
    final i = state.indexWhere((x) => x.id == h.id);
    state = i < 0
        ? [...state, h]
        : [for (final x in state) x.id == h.id ? h : x];
  }

  void markUsed(String id, DateTime cuando) => state = [
        for (final x in state)
          x.id == id ? x.copyWith(ultimoUso: cuando) : x,
      ];

  void setActive(String id, bool v, DateTime cuando) => state = [
        for (final x in state)
          x.id == id ? x.copyWith(activo: v, updatedAt: cuando) : x,
      ];

  void eliminar(String id) =>
      state = [for (final x in state) if (x.id != id) x];
}

/// Directorio completo (reactivo). Antes venía de la BD; ahora es memoria.
final participantsProvider =
    NotifierProvider<ParticipantsController, List<Participant>>(ParticipantsController.new);

/// Activos ordenados por nombre normalizado (lista del picker).
final activeParticipantsProvider = Provider<List<Participant>>((ref) {
  final todos = ref.watch(participantsProvider);
  return todos.where((h) => h.activo).toList()
    ..sort((a, b) =>
        normalizeName(a.nombre).compareTo(normalizeName(b.nombre)));
});

/// Recientes (por `ultimoUso` desc), máx. 6.
final recentParticipantsProvider = Provider<List<Participant>>((ref) {
  final activos = ref.watch(activeParticipantsProvider);
  final conUso = activos.where((h) => h.ultimoUso != null).toList()
    ..sort((a, b) => b.ultimoUso!.compareTo(a.ultimoUso!));
  return conUso.take(6).toList();
});

/// Congregaciones distintas (sugerencias del formulario de personas).
final participantCongregationsProvider = Provider<List<String>>((ref) {
  final todos = ref.watch(participantsProvider);
  final distintas = <String>{
    for (final h in todos)
      if (h.congregacion.trim().isNotEmpty) h.congregacion.trim(),
  };
  return distintas.toList()..sort();
});

/// Filtro de la pantalla de gestión (puro, testeable).
List<Participant> filterParticipants(
  List<Participant> todos, {
  String query = '',
  Role? privilegio,
  String? congregacion,
  bool incluirInactivos = false,
}) {
  final q = normalizeName(query);
  return [
    for (final h in todos)
      if ((incluirInactivos || h.activo) &&
          (privilegio == null || h.privilegio == privilegio) &&
          (congregacion == null || h.congregacion == congregacion) &&
          (q.isEmpty || normalizeName(h.nombre).contains(q)))
        h,
  ];
}

final participantActionsProvider =
    Provider<ParticipantActions>(ParticipantActions.new);

/// Escrituras al directorio en memoria. `guardar` siempre sella `updatedAt`;
/// `recordUsage` NO lo toca (solo `ultimoUso`).
class ParticipantActions {
  ParticipantActions(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  ParticipantsController get _dir => _ref.read(participantsProvider.notifier);

  /// Asignación hecha desde el picker: si el nombre ya existe (normalizado)
  /// solo marca uso; si no, alta mínima que queda como 'Incompleto' en la
  /// pantalla de gestión (sexo sin especificar).
  Future<void> recordUsage(String nombre) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return;
    final ahora = DateTime.now().toUtc();
    final clave = normalizeName(limpio);
    for (final h in _ref.read(participantsProvider)) {
      if (normalizeName(h.nombre) == clave) {
        _dir.markUsed(h.id, ahora);
        return;
      }
    }
    _dir.upsert(Participant(
      id: _uuid.v4(),
      nombre: limpio,
      sexo: Gender.unspecified,
      privilegio: Role.publisher,
      congregacion: _ref.read(formProvider).cong,
      activo: true,
      notas: '',
      createdAt: ahora,
      updatedAt: ahora,
      ultimoUso: ahora,
    ));
  }

  Future<void> guardar(Participant h) async =>
      _dir.upsert(h.copyWith(updatedAt: DateTime.now().toUtc()));

  Future<void> setActive(String id, bool v) async =>
      _dir.setActive(id, v, DateTime.now().toUtc());

  Future<void> eliminar(String id) async => _dir.eliminar(id);
}
