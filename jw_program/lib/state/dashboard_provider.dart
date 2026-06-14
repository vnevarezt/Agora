import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/congregation.dart';
import '../models/notebook.dart';
import '../models/project.dart';
import '../models/reminder.dart';

/// Estado del dashboard. SOLO UI: arranca vacío y se llena en memoria durante
/// la sesión (sin persistencia). Cuando exista backend, solo cambian las
/// fuentes de estos providers; la UI no se entera.

/// Usuario en sesión (saludo y tarjeta lateral). Sin identidad real todavía:
/// neutro hasta que haya autenticación.
final sessionUserProvider = Provider<({String nombre, String rol})>(
    (ref) => (nombre: '', rol: ''));

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

  void add({required String nombre, required String numero}) {
    final color = _congColors[state.length % _congColors.length];
    state = [
      ...state,
      Congregation(
        id: const Uuid().v4(),
        nombre: nombre,
        numero: numero,
        color: color,
      ),
    ];
  }
}

final congregationsProvider =
    NotifierProvider<CongregationsController, List<Congregation>>(
        CongregationsController.new);

/// Catálogo de cuadernos disponibles. Vacío sin backend (se poblará con la
/// descarga real del editor).
final notebooksProvider = Provider<List<Notebook>>((ref) => const []);

/// Recordatorios/alertas. Vacío sin backend (son alertas derivadas).
final remindersProvider = Provider<List<Reminder>>((ref) => const []);

/// Lista de proyectos editable en memoria. El modal de proyectos crea, edita y
/// elimina aquí; la persistencia llega en una fase posterior.
class ProjectsController extends Notifier<List<Project>> {
  @override
  List<Project> build() => const [];

  /// 14 partes asignables por semana.
  static int _total(int semanas) => semanas * 14;

  void crear({
    required String nombre,
    required String congregacionId,
    required List<String> semanas,
  }) {
    final nuevo = Project(
      id: const Uuid().v4(),
      nombre: nombre,
      congregacionId: congregacionId,
      semanas: semanas,
      done: 0,
      total: _total(semanas.length),
      estado: ProjectStatus.draft,
      editado: 'ahora mismo',
    );
    state = [nuevo, ...state];
  }

  void update(
    String id, {
    required String nombre,
    required String congregacionId,
    required List<String> semanas,
  }) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(
            nombre: nombre,
            congregacionId: congregacionId,
            semanas: semanas,
            total: _total(semanas.length),
            editado: 'ahora mismo',
          )
        else
          p,
    ];
  }

  void eliminar(String id) =>
      state = [for (final p in state) if (p.id != id) p];
}

final projectsProvider =
    NotifierProvider<ProjectsController, List<Project>>(
        ProjectsController.new);

/// Filtros activos: congregación (`'all'` = todas) y estado (`null` = todos).
class DashboardFilters {
  /// `'all'` o el id de una congregación.
  final String congId;

  /// `null` = todo estado.
  final ProjectStatus? estado;

  const DashboardFilters({this.congId = 'all', this.estado});
}

class DashboardFiltersController extends Notifier<DashboardFilters> {
  @override
  DashboardFilters build() => const DashboardFilters();

  void setCongregation(String congId) =>
      state = DashboardFilters(congId: congId, estado: state.estado);

  void setStatus(ProjectStatus? estado) =>
      state = DashboardFilters(congId: state.congId, estado: estado);
}

final dashboardFiltersProvider =
    NotifierProvider<DashboardFiltersController, DashboardFilters>(
        DashboardFiltersController.new);

/// Proyectos visibles tras aplicar los filtros activos.
final filteredProjectsProvider = Provider<List<Project>>((ref) {
  final proyectos = ref.watch(projectsProvider);
  final f = ref.watch(dashboardFiltersProvider);
  return proyectos
      .where((p) =>
          (f.congId == 'all' || p.congregacionId == f.congId) &&
          (f.estado == null || p.estado == f.estado))
      .toList();
});
