import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/dashboard_sample.dart';
import '../models/congregacion.dart';
import '../models/cuaderno.dart';
import '../models/proyecto.dart';
import '../models/recordatorio.dart';

/// Estado del dashboard. Por ahora expone los datos de ejemplo y el estado de
/// los filtros (UI pura). Cuando exista persistencia, solo cambian las fuentes
/// de estos providers; la UI no se entera.

final usuarioProvider = Provider((ref) => usuarioEjemplo);

final congregacionesDashProvider =
    Provider<List<Congregacion>>((ref) => congregacionesEjemplo);

final cuadernosProvider =
    Provider<List<Cuaderno>>((ref) => cuadernosEjemplo);

final recordatoriosProvider =
    Provider<List<Recordatorio>>((ref) => recordatoriosEjemplo);

/// Lista de proyectos editable en memoria. El modal de proyectos crea, edita y
/// elimina aquí; la persistencia llega en una fase posterior.
class ProyectosController extends Notifier<List<Proyecto>> {
  @override
  List<Proyecto> build() => proyectosEjemplo;

  /// 14 partes asignables por semana (réplica del cálculo del mock).
  static int _total(int semanas) => semanas * 14;

  void crear({
    required String nombre,
    required String congregacionId,
    required List<String> semanas,
  }) {
    final nuevo = Proyecto(
      id: const Uuid().v4(),
      nombre: nombre,
      congregacionId: congregacionId,
      semanas: semanas,
      done: 0,
      total: _total(semanas.length),
      estado: EstadoProyecto.borrador,
      editado: 'ahora mismo',
    );
    state = [nuevo, ...state];
  }

  void actualizar(
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

final proyectosProvider =
    NotifierProvider<ProyectosController, List<Proyecto>>(
        ProyectosController.new);

/// Filtros activos: congregación (`'all'` = todas) y estado (`null` = todos).
class DashFiltros {
  /// `'all'` o el id de una congregación.
  final String congId;

  /// `null` = todo estado.
  final EstadoProyecto? estado;

  const DashFiltros({this.congId = 'all', this.estado});
}

class DashFiltrosController extends Notifier<DashFiltros> {
  @override
  DashFiltros build() => const DashFiltros();

  void setCong(String congId) =>
      state = DashFiltros(congId: congId, estado: state.estado);

  void setEstado(EstadoProyecto? estado) =>
      state = DashFiltros(congId: state.congId, estado: estado);
}

final dashFiltrosProvider =
    NotifierProvider<DashFiltrosController, DashFiltros>(
        DashFiltrosController.new);

/// Proyectos visibles tras aplicar los filtros activos.
final proyectosFiltradosProvider = Provider<List<Proyecto>>((ref) {
  final proyectos = ref.watch(proyectosProvider);
  final f = ref.watch(dashFiltrosProvider);
  return proyectos
      .where((p) =>
          (f.congId == 'all' || p.congregacionId == f.congId) &&
          (f.estado == null || p.estado == f.estado))
      .toList();
});
