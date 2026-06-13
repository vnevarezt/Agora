import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_sample.dart';
import '../models/congregacion.dart';
import '../models/proyecto.dart';
import '../models/recordatorio.dart';

/// Estado del dashboard. Por ahora expone los datos de ejemplo y el estado de
/// los filtros (UI pura). Cuando exista persistencia, solo cambian las fuentes
/// de estos providers; la UI no se entera.

final usuarioProvider = Provider((ref) => usuarioEjemplo);

final congregacionesDashProvider =
    Provider<List<Congregacion>>((ref) => congregacionesEjemplo);

final proyectosProvider =
    Provider<List<Proyecto>>((ref) => proyectosEjemplo);

final recordatoriosProvider =
    Provider<List<Recordatorio>>((ref) => recordatoriosEjemplo);

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
