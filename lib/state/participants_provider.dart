import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/participant.dart';
import 'program_form.dart';

// INVARIANT: program assignments are still plain strings keyed by ProgramRow.id
// in formProvider (the PDF contract). The participant directory is just a
// catalog of people, NOT a foreign key.
//
// UI-ONLY: ephemeral in-memory directory (no DB, no persistence). The encrypted
// DB scaffolding (data/db/*, db_provider) stays dormant — no active route uses
// it — ready to be reconnected later.

/// In-memory directory. Starts empty; creates/edits live only for the session.
/// Keeps the DB semantics: `markUsed` touches `lastUsed` without altering
/// `updatedAt`.
class ParticipantsController extends Notifier<List<Participant>> {
  @override
  List<Participant> build() => const [];

  void upsert(Participant p) {
    final i = state.indexWhere((x) => x.id == p.id);
    state = i < 0
        ? [...state, p]
        : [for (final x in state) x.id == p.id ? p : x];
  }

  void markUsed(String id, DateTime when) => state = [
        for (final x in state)
          x.id == id ? x.copyWith(lastUsed: when) : x,
      ];

  void setActive(String id, bool v, DateTime when) => state = [
        for (final x in state)
          x.id == id ? x.copyWith(active: v, updatedAt: when) : x,
      ];

  void delete(String id) =>
      state = [for (final x in state) if (x.id != id) x];
}

/// Full directory (reactive). Used to come from the DB; now it's in memory.
final participantsProvider =
    NotifierProvider<ParticipantsController, List<Participant>>(
        ParticipantsController.new);

/// Active ones sorted by normalized name (picker list).
final activeParticipantsProvider = Provider<List<Participant>>((ref) {
  final all = ref.watch(participantsProvider);
  return all.where((p) => p.active).toList()
    ..sort((a, b) => normalizeName(a.name).compareTo(normalizeName(b.name)));
});

/// Recently used (by `lastUsed` desc), max 6.
final recentParticipantsProvider = Provider<List<Participant>>((ref) {
  final active = ref.watch(activeParticipantsProvider);
  final withUsage = active.where((p) => p.lastUsed != null).toList()
    ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
  return withUsage.take(6).toList();
});

/// Distinct congregations (suggestions for the participant form).
final participantCongregationsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(participantsProvider);
  final distinct = <String>{
    for (final p in all)
      if (p.congregation.trim().isNotEmpty) p.congregation.trim(),
  };
  return distinct.toList()..sort();
});

/// Filter for the management screen (pure, testable).
List<Participant> filterParticipants(
  List<Participant> all, {
  String query = '',
  Role? role,
  String? congregation,
  bool includeInactive = false,
}) {
  final q = normalizeName(query);
  return [
    for (final p in all)
      if ((includeInactive || p.active) &&
          (role == null || p.role == role) &&
          (congregation == null || p.congregation == congregation) &&
          (q.isEmpty || normalizeName(p.name).contains(q)))
        p,
  ];
}

final participantActionsProvider =
    Provider<ParticipantActions>(ParticipantActions.new);

/// Writes to the in-memory directory. `save` always stamps `updatedAt`;
/// `recordUsage` does NOT (only `lastUsed`).
class ParticipantActions {
  ParticipantActions(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  ParticipantsController get _dir => _ref.read(participantsProvider.notifier);

  /// Assignment made from the picker: if the name already exists (normalized),
  /// just mark usage; otherwise create a minimal entry that shows as
  /// "Incompleto" on the management screen (gender unspecified).
  Future<void> recordUsage(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now().toUtc();
    final key = normalizeName(clean);
    for (final p in _ref.read(participantsProvider)) {
      if (normalizeName(p.name) == key) {
        _dir.markUsed(p.id, now);
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
      createdAt: now,
      updatedAt: now,
      lastUsed: now,
    ));
  }

  Future<void> save(Participant p) async =>
      _dir.upsert(p.copyWith(updatedAt: DateTime.now().toUtc()));

  Future<void> setActive(String id, bool v) async =>
      _dir.setActive(id, v, DateTime.now().toUtc());

  Future<void> delete(String id) async => _dir.delete(id);
}
