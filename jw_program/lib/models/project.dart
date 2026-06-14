/// Estado de un proyecto en el tablero (espejo de `status` del mock).
enum ProjectStatus { borrador, completo, exportado }

extension ProjectStatusX on ProjectStatus {
  /// Etiqueta singular para la insignia ("Borrador").
  String get etiqueta => switch (this) {
        ProjectStatus.borrador => 'Borrador',
        ProjectStatus.completo => 'Completo',
        ProjectStatus.exportado => 'Exportado',
      };

  /// Etiqueta plural para los chips de filtro ("Borradores").
  String get plural => switch (this) {
        ProjectStatus.borrador => 'Borradores',
        ProjectStatus.completo => 'Completos',
        ProjectStatus.exportado => 'Exportados',
      };
}

/// Project del dashboard: el programa de un mes/periodo de una congregación.
/// Solo presentación por ahora (sin persistencia ni lógica de asignación).
class Project {
  final String id;
  final String nombre;
  final String congregacionId;
  final List<String> semanas;
  final int done;
  final int total;
  final ProjectStatus estado;

  /// Texto relativo de última edición ("hace 2 horas"); placeholder de UI.
  final String editado;

  const Project({
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

  Project copyWith({
    String? nombre,
    String? congregacionId,
    List<String>? semanas,
    int? done,
    int? total,
    ProjectStatus? estado,
    String? editado,
  }) {
    return Project(
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
