import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/congregations_repository.dart';
import '../data/repos/projects_repository.dart';
import '../i18n/strings.g.dart';
import '../models/congregation.dart';
import '../models/congregation_settings.dart';
import '../models/notebook.dart';
import '../models/project.dart';
import '../models/reminder.dart';
import 'db_provider.dart';

/// Dashboard state. Congregations and projects are DB-backed (milestone 3
/// of the phase-1 plan); everything here lives below AuthGate. The sync
/// `List` providers keep the pre-persistence contract so the UI reads them
/// directly (same policy as [notebooksProvider] / `peopleProvider`).

/// Session user (greeting and sidebar card). No real identity yet: neutral
/// until there is authentication.
final sessionUserProvider = Provider<({String name, String role})>(
    (ref) => (name: '', role: ''));

final congregationsRepositoryProvider = Provider<CongregationsRepository>(
    (ref) => CongregationsRepository(ref.watch(dbProvider),
        defaultName: t.congregation.defaultName));

final congregationsStreamProvider = StreamProvider<List<Congregation>>(
    (ref) => ref.watch(congregationsRepositoryProvider).watchAll());

/// Synchronous view (empty during the first frame).
final congregationsProvider = Provider<List<Congregation>>(
    (ref) => ref.watch(congregationsStreamProvider).asData?.value ?? const []);

final congregationActionsProvider =
    Provider<CongregationActions>(CongregationActions.new);

class CongregationActions {
  CongregationActions(this._ref);

  final Ref _ref;

  CongregationsRepository get _repo =>
      _ref.read(congregationsRepositoryProvider);

  Future<void> add({
    required String name,
    required String number,
    CongregationSettings settings = const CongregationSettings(),
  }) =>
      _repo.create(name: name, number: number, settings: settings);

  Future<void> update(
    String id, {
    required String name,
    required String number,
    required CongregationSettings settings,
  }) =>
      _repo.update(id, name: name, number: number, settings: settings);
}

/// Catalog of cached notebooks. Starts empty and is filled by the background
/// sync ([mwbSyncProvider]) from the on-disk cache. Kept synchronous so the
/// project modal keeps reading it directly.
class NotebooksController extends Notifier<List<Notebook>> {
  @override
  List<Notebook> build() => const [];

  void setFrom(List<Notebook> notebooks) => state = notebooks;
}

final notebooksProvider =
    NotifierProvider<NotebooksController, List<Notebook>>(
        NotebooksController.new);

/// Reminders/alerts. Empty without a backend (they are derived alerts).
final remindersProvider = Provider<List<Reminder>>((ref) => const []);

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) =>
    ProjectsRepository(
        ref.watch(dbProvider), ref.watch(congregationsRepositoryProvider)));

final projectsStreamProvider = StreamProvider<List<ProjectData>>(
    (ref) => ref.watch(projectsRepositoryProvider).watchAll());

/// Synchronous project cards derived from the DB rows: progress/status/
/// edited label are computed, never stored (docs/PHASE1_LOCAL_PERSISTENCE.md).
final projectsProvider = Provider<List<Project>>((ref) {
  final data = ref.watch(projectsStreamProvider).asData?.value ?? const [];
  return [for (final d in data) _toCard(d)];
});

/// 14 assignable parts per week (until phase 2 counts real assignments).
const _partsPerWeek = 14;

Project _toCard(ProjectData d) {
  final weeks = [for (final p in d.programs) p.date]..sort();
  final total = weeks.length * _partsPerWeek;
  // Real assignment counting arrives with phase 2 (slots in the DB).
  const done = 0;
  final status = d.project.exportedAt != null
      ? ProjectStatus.exported
      : (total > 0 && done >= total)
          ? ProjectStatus.complete
          : ProjectStatus.draft;
  return Project(
    id: d.project.id,
    name: d.project.name,
    congregationId: d.project.congregationId,
    weeks: weeks,
    done: done,
    total: total,
    status: status,
    editedLabel: relativeEditedLabel(d.project.updatedAt),
  );
}

/// "hace 2 h" label for the project cards, from the row's `updatedAt`.
/// Coarse on purpose: it re-renders with the dashboard, it doesn't tick.
String relativeEditedLabel(DateTime updatedAt, {DateTime? now}) {
  final d = (now ?? DateTime.now().toUtc()).difference(updatedAt);
  if (d.inMinutes < 1) return t.relativeTime.now;
  if (d.inHours < 1) return t.relativeTime.minutes(n: d.inMinutes);
  if (d.inDays < 1) return t.relativeTime.hours(n: d.inHours);
  return t.relativeTime.days(n: d.inDays);
}

final projectActionsProvider = Provider<ProjectActions>(ProjectActions.new);

class ProjectActions {
  ProjectActions(this._ref);

  final Ref _ref;

  ProjectsRepository get _repo => _ref.read(projectsRepositoryProvider);

  Future<void> create({
    required String name,
    required String congregationId,
    required List<String> weeks,
  }) =>
      _repo.create(name: name, congregationId: congregationId, weeks: weeks);

  Future<void> update(
    String id, {
    required String name,
    required String congregationId,
    required List<String> weeks,
  }) =>
      _repo.update(id,
          name: name, congregationId: congregationId, weeks: weeks);

  Future<void> delete(String id) => _repo.delete(id);

  Future<void> markExported(String id) => _repo.markExported(id);
}

/// Active filters: congregation (`'all'` = all) and status (`null` = any).
class DashboardFilters {
  /// `'all'` or a congregation id.
  final String congregationId;

  /// `null` = any status.
  final ProjectStatus? status;

  const DashboardFilters({this.congregationId = 'all', this.status});
}

class DashboardFiltersController extends Notifier<DashboardFilters> {
  @override
  DashboardFilters build() => const DashboardFilters();

  void setCongregation(String congregationId) =>
      state = DashboardFilters(congregationId: congregationId, status: state.status);

  void setStatus(ProjectStatus? status) =>
      state = DashboardFilters(congregationId: state.congregationId, status: status);
}

final dashboardFiltersProvider =
    NotifierProvider<DashboardFiltersController, DashboardFilters>(
        DashboardFiltersController.new);

/// Projects visible after applying the active filters.
final filteredProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsProvider);
  final f = ref.watch(dashboardFiltersProvider);
  return projects
      .where((p) =>
          (f.congregationId == 'all' || p.congregationId == f.congregationId) &&
          (f.status == null || p.status == f.status))
      .toList();
});
