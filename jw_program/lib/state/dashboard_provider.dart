import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/congregacion.dart';
import '../models/cuaderno.dart';
import '../models/proyecto.dart';
import '../models/recordatorio.dart';

/// Estado del dashboard. SOLO UI: arranca vacío y se llena en memoria durante
/// la sesión (sin persistencia). Cuando exista backend, solo cambian las
/// fuentes de estos providers; la UI no se entera.

/// Usuario en sesión (saludo y tarjeta lateral). Sin identidad real todavía:
/// neutro hasta que haya autenticación.
final usuarioProvider = Provider<({String nombre, String rol})>(
    (ref) => (nombre: '', rol: ''));

/// Paleta para el punto de color de cada congregación nueva (se cicla).
const _coloresCong = <Color>[
  Color(0xFF7A2230),
  Color(0xFF3E6651),
  Color(0xFF3F6193),
  Color(0xFF6B4E8A),
  Color(0xFF9A6A2E),
];

/// Congregaciones en memoria. Vacío al inicio; el modal "Nueva congregación"
/// las añade durante la sesión.
class CongregacionesController extends Notifier<List<Congregacion>> {
  @override
  List<Congregacion> build() => const [];

  void agregar({required String nombre, required String numero}) {
    final color = _coloresCong[state.length % _coloresCong.length];
    state = [
      ...state,
      Congregacion(
        id: const Uuid().v4(),
        nombre: nombre,
        numero: numero,
        color: color,
      ),
    ];
  }
}

final congregacionesDashProvider =
    NotifierProvider<CongregacionesController, List<Congregacion>>(
        CongregacionesController.new);

/// Catálogo de cuadernos disponibles. Vacío sin backend (se poblará con la
/// descarga real del editor).
final cuadernosProvider = Provider<List<Cuaderno>>((ref) => const []);

/// Recordatorios/alertas. Vacío sin backend (son alertas derivadas).
final recordatoriosProvider = Provider<List<Recordatorio>>((ref) => const []);

/// Lista de proyectos editable en memoria. El modal de proyectos crea, edita y
/// elimina aquí; la persistencia llega en una fase posterior.
class ProyectosController extends Notifier<List<Proyecto>> {
  @override
  List<Proyecto> build() => const [];

  /// 14 partes asignables por semana.
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
