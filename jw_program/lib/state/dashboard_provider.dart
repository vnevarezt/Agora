import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/congregation.dart';
import '../models/notebook.dart';
import '../models/project.dart';
import '../models/reminder.dart';

/// Estado del dashboard. SOLO UI: arranca vacío y se llena en memoria durante
/// la sesión (sin persistencia). Cuando exista backend, solo cambian las
/// fuentes de estos providers; la UI no se entera.

/// Usuario en sesión (greeting y tarjeta lateral). Sin identidad real todavía:
/// neutro hasta que haya autenticación.
final sessionUserProvider = Provider<({String name, String role})>(
    (ref) => (name: '', role: ''));

/// Paleta para el punto de color de cada congregación nueva (se cicla).
const _congColors = <int>[
  0xFF7A2230,
  0xFF3E6651,
  0xFF3F6193,
  0xFF6B4E8A,
  0xFF9A6A2E,
];

/// Congregaciones en memoria. Vacío al inicio; el modal "Nueva congregación"
/// las añade durante la sesión.
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

/// Catálogo de notebooks disponibles. Vacío sin backend (se poblará con la
/// descarga real del editor).
final notebooksProvider = Provider<List<Notebook>>((ref) => const []);

/// Recordatorios/alerts. Vacío sin backend (son alerts derivadas).
final remindersProvider = Provider<List<Reminder>>((ref) => const []);

/// Lista de projects editable en memoria. El modal de projects crea, edita y
/// elimina aquí; la persistencia llega en una fase posterior.
class ProjectsController extends Notifier<List<Project>> {
  @override
  List<Project> build() => const [];

  /// 14 partes asignables por semana.
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

/// Filtros active: congregación (`'all'` = todas) y status (`null` = all).
class DashboardFilters {
  /// `'all'` o el id de una congregación.
  final String congregationId;

  /// `null` = todo status.
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

/// Proyectos visibles tras apply los filters active.
final filteredProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsProvider);
  final f = ref.watch(dashboardFiltersProvider);
  return projects
      .where((p) =>
          (f.congregationId == 'all' || p.congregationId == f.congregationId) &&
          (f.status == null || p.status == f.status))
      .toList();
});
