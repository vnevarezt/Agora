import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/congregation.dart';
import '../models/notebook.dart';
import '../models/project.dart';
import '../models/reminder.dart';

/// Dashboard state. UI-ONLY: starts empty and fills in memory during the
/// session (no persistence). When a backend exists, only the sources of these
/// providers change; the UI doesn't notice.

/// Session user (greeting and sidebar card). No real identity yet: neutral
/// until there is authentication.
final sessionUserProvider = Provider<({String name, String role})>(
    (ref) => (name: '', role: ''));

/// Palette for each new congregation's color dot (cycled).
const _congColors = <int>[
  0xFF7A2230,
  0xFF3E6651,
  0xFF3F6193,
  0xFF6B4E8A,
  0xFF9A6A2E,
];

/// In-memory congregations. Empty at first; the "Nueva congregación" modal
/// adds them during the session.
class CongregationsController extends Notifier<List<Congregation>> {
  @override
  List<Congregation> build() => const [];

  void add({required String name, required String number}) {
    final color = _congColors[state.length % _congColors.length];
    state = [
      ...state,
      Congregation(
        id: const Uuid().v4(),
        name: name,
        number: number,
        color: color,
      ),
    ];
  }
}

final congregationsProvider =
    NotifierProvider<CongregationsController, List<Congregation>>(
        CongregationsController.new);

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

/// In-memory editable project list. The project modal creates, edits and
/// deletes here; persistence comes in a later phase.
class ProjectsController extends Notifier<List<Project>> {
  @override
  List<Project> build() => const [];

  /// 14 assignable parts per week.
  static int _total(int weeks) => weeks * 14;

  void create({
    required String name,
    required String congregationId,
    required List<String> weeks,
  }) {
    final newProject = Project(
      id: const Uuid().v4(),
      name: name,
      congregationId: congregationId,
      weeks: weeks,
      done: 0,
      total: _total(weeks.length),
      status: ProjectStatus.draft,
      editedLabel: 'ahora mismo',
    );
    state = [newProject, ...state];
  }

  void update(
    String id, {
    required String name,
    required String congregationId,
    required List<String> weeks,
  }) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(
            name: name,
            congregationId: congregationId,
            weeks: weeks,
            total: _total(weeks.length),
            editedLabel: 'ahora mismo',
          )
        else
          p,
    ];
  }

  void delete(String id) =>
      state = [for (final p in state) if (p.id != id) p];
}

final projectsProvider =
    NotifierProvider<ProjectsController, List<Project>>(
        ProjectsController.new);

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
