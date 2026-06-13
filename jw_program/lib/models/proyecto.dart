/// Estado de un proyecto en el tablero (espejo de `status` del mock).
enum EstadoProyecto { borrador, completo, exportado }

extension EstadoProyectoX on EstadoProyecto {
  /// Etiqueta singular para la insignia ("Borrador").
  String get etiqueta => switch (this) {
        EstadoProyecto.borrador => 'Borrador',
        EstadoProyecto.completo => 'Completo',
        EstadoProyecto.exportado => 'Exportado',
      };

  /// Etiqueta plural para los chips de filtro ("Borradores").
  String get plural => switch (this) {
        EstadoProyecto.borrador => 'Borradores',
        EstadoProyecto.completo => 'Completos',
        EstadoProyecto.exportado => 'Exportados',
      };
}

/// Proyecto del dashboard: el programa de un mes/periodo de una congregación.
/// Solo presentación por ahora (sin persistencia ni lógica de asignación).
class Proyecto {
  final String id;
  final String nombre;
  final String congregacionId;
  final List<String> semanas;
  final int done;
  final int total;
  final EstadoProyecto estado;

  /// Texto relativo de última edición ("hace 2 horas"); placeholder de UI.
  final String editado;

  const Proyecto({
    required this.id,
    required this.nombre,
    required this.congregacionId,
    required this.semanas,
    required this.done,
    required this.total,
    required this.estado,
    required this.editado,
  });

  /// Fracción de avance 0..1 para la barra de progreso.
  double get progreso => total == 0 ? 0 : done / total;

  Proyecto copyWith({
    String? nombre,
    String? congregacionId,
    List<String>? semanas,
    int? done,
    int? total,
    EstadoProyecto? estado,
    String? editado,
  }) {
    return Proyecto(
      id: id,
      nombre: nombre ?? this.nombre,
      congregacionId: congregacionId ?? this.congregacionId,
      semanas: semanas ?? this.semanas,
      done: done ?? this.done,
      total: total ?? this.total,
      estado: estado ?? this.estado,
      editado: editado ?? this.editado,
    );
  }
}
