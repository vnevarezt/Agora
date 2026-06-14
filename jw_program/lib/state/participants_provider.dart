import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/participant.dart';
import 'program_form.dart';

// INVARIANTE: las asignaciones del programa siguen siendo strings planos
// por ProgramRow.id en formProvider (contrato del PDF). El directorio de
// participants es solo un catálogo de personas, NO una clave foránea.
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

  void markUsed(String id, DateTime when) => state = [
        for (final x in state)
          x.id == id ? x.copyWith(lastUsed: when) : x,
      ];

  void setActive(String id, bool v, DateTime when) => state = [
        for (final x in state)
          x.id == id ? x.copyWith(active: v, updatedAt: when) : x,
      ];

  void eliminar(String id) =>
      state = [for (final x in state) if (x.id != id) x];
}

/// Directorio completo (reactivo). Antes venía de la BD; ahora es memoria.
final participantsProvider =
    NotifierProvider<ParticipantsController, List<Participant>>(ParticipantsController.new);

/// Activos ordenados por name normalizado (list del picker).
final activeParticipantsProvider = Provider<List<Participant>>((ref) {
  final all = ref.watch(participantsProvider);
  return all.where((h) => h.active).toList()
    ..sort((a, b) =>
        normalizeName(a.name).compareTo(normalizeName(b.name)));
});

/// Recientes (por `ultimoUso` desc), máx. 6.
final recentParticipantsProvider = Provider<List<Participant>>((ref) {
  final active = ref.watch(activeParticipantsProvider);
  final conUso = active.where((h) => h.lastUsed != null).toList()
    ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
  return conUso.take(6).toList();
});

/// Congregaciones distintas (suggestions del formulario de personas).
final participantCongregationsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(participantsProvider);
  final distintas = <String>{
    for (final h in all)
      if (h.congregation.trim().isNotEmpty) h.congregation.trim(),
  };
  return distintas.toList()..sort();
});

/// Filtro de la pantalla de gestión (puro, testeable).
List<Participant> filterParticipants(
  List<Participant> all, {
  String query = '',
  Role? role,
  String? congregation,
  bool includeInactive = false,
}) {
  final q = normalizeName(query);
  return [
    for (final h in all)
      if ((includeInactive || h.active) &&
          (role == null || h.role == role) &&
          (congregation == null || h.congregation == congregation) &&
          (q.isEmpty || normalizeName(h.name).contains(q)))
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

  /// Asignación hecha desde el picker: si el name ya existe (normalizado)
  /// solo marca uso; si no, alta mínima que queda como 'Incompleto' en la
  /// pantalla de gestión (sexo sin especificar).
  Future<void> recordUsage(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final ahora = DateTime.now().toUtc();
    final clave = normalizeName(clean);
    for (final h in _ref.read(participantsProvider)) {
      if (normalizeName(h.name) == clave) {
        _dir.markUsed(h.id, ahora);
        return;
      }
    }
    _dir.upsert(Participant(
      id: _uuid.v4(),
      name: clean,
      gender: Gender.unspecified,
      role: Role.publisher,
      congregation: _ref.read(formProvider).congregationId,
      active: true,
      notes: '',
      createdAt: ahora,
      updatedAt: ahora,
      lastUsed: ahora,
    ));
  }

  Future<void> guardar(Participant h) async =>
      _dir.upsert(h.copyWith(updatedAt: DateTime.now().toUtc()));

  Future<void> setActive(String id, bool v) async =>
      _dir.setActive(id, v, DateTime.now().toUtc());

  Future<void> eliminar(String id) async => _dir.eliminar(id);
}
