import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/repos/people_repository.dart';
import '../models/person.dart';
import 'dashboard_provider.dart';
import 'db_provider.dart';

// DB-backed person directory (milestone 2 of the phase-1 plan). Everything
// here lives below AuthGate — watching these providers while the session is
// locked is a programming error (see dbProvider).

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) =>
    PeopleRepository(ref.watch(dbProvider),
        ref.watch(congregationsRepositoryProvider),
        ref.watch(syncScribeProvider)));

/// Reactive directory straight from drift.
final peopleStreamProvider = StreamProvider<List<Person>>(
    (ref) => ref.watch(peopleRepositoryProvider).watchAll());

/// Synchronous view of the directory (empty during the first frame). Kept
/// synchronous so pickers/filters read it directly, same policy as
/// [notebooksProvider].
final peopleProvider = Provider<List<Person>>(
    (ref) => ref.watch(peopleStreamProvider).asData?.value ?? const []);

/// Active ones sorted by normalized display name (picker list).
final activePeopleProvider = Provider<List<Person>>((ref) {
  final all = ref.watch(peopleProvider);
  return all.where((p) => p.active).toList()
    ..sort((a, b) =>
        normalizeName(a.displayName).compareTo(normalizeName(b.displayName)));
});

/// Recently used (by `lastUsed` desc), max 6.
final recentPeopleProvider = Provider<List<Person>>((ref) {
  final active = ref.watch(activePeopleProvider);
  final withUsage = active.where((p) => p.lastUsed != null).toList()
    ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
  return withUsage.take(6).toList();
});

/// Distinct origin congregations (suggestions for the person form; '' =
/// local member, so only visitors contribute).
final originCongregationsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(peopleProvider);
  final distinct = <String>{
    for (final p in all)
      if (p.originCongregation.trim().isNotEmpty) p.originCongregation.trim(),
  };
  return distinct.toList()..sort();
});

/// Filter for the management screen (pure, testable). Searches across the
/// display name and the optional first/last names.
List<Person> filterPeople(
  List<Person> all, {
  String query = '',
  Role? privilege,
  String? originCongregation,
  bool includeInactive = false,
}) {
  final q = normalizeName(query);
  return [
    for (final p in all)
      if ((includeInactive || p.active) &&
          (privilege == null || p.privilege == privilege) &&
          (originCongregation == null ||
              p.originCongregation == originCongregation) &&
          (q.isEmpty ||
              normalizeName('${p.displayName} ${p.firstName} ${p.lastName}')
                  .contains(q)))
        p,
  ];
}

final personActionsProvider = Provider<PersonActions>(PersonActions.new);

/// Writes to the directory through the repository. `save` always stamps
/// `updatedAt`; `recordUsage` does NOT (only `lastUsed`).
class PersonActions {
  PersonActions(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  PeopleRepository get _repo => _ref.read(peopleRepositoryProvider);

  /// Assignment made from the picker: if the name already exists
  /// (normalized), just mark usage; otherwise create a minimal entry that
  /// shows as "Incompleto" on the management screen (gender unspecified).
  Future<void> recordUsage(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now().toUtc();
    final key = normalizeName(clean);
    for (final p in await _repo.all()) {
      if (normalizeName(p.displayName) == key) {
        await _repo.markUsed(p.id);
        return;
      }
    }
    await _repo.save(Person(
      id: _uuid.v4(),
      congregationId: '', // resolved to the default congregation on save
      firstName: '',
      lastName: '',
      displayName: clean,
      gender: Gender.unspecified,
      privilege: Role.publisher,
      qualifications: const [],
      originCongregation: '',
      active: true,
      notes: '',
      createdAt: now,
      updatedAt: now,
      lastUsed: now,
    ));
  }

  Future<void> save(Person p) => _repo.save(p);

  Future<void> setActive(String id, bool v) => _repo.setActive(id, v);

  Future<void> delete(String id) => _repo.delete(id);
}
