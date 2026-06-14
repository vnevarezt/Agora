/// Estado de un proyecto en el tablero.
enum ProjectStatus { draft, complete, exported }

extension ProjectStatusX on ProjectStatus {
  /// Etiqueta singular para la insignia ("Borrador").
  String get label => switch (this) {
        ProjectStatus.draft => 'Borrador',
        ProjectStatus.complete => 'Completo',
        ProjectStatus.exported => 'Exportado',
      };

  /// Etiqueta plural para los chips de filtro ("Borradores").
  String get plural => switch (this) {
        ProjectStatus.draft => 'Borradores',
        ProjectStatus.complete => 'Completos',
        ProjectStatus.exported => 'Exportados',
      };
}

/// Proyecto del dashboard: el programa de un mes/periodo de una congregación.
class Project {
  final String id;
  final String name;
  final String congregationId;
  final List<String> weeks;
  final int done;
  final int total;
  final ProjectStatus status;

  /// Texto relativo de última edición ("hace 2 horas"); placeholder de UI.
  final String editedLabel;

  const Project({
    required this.id,
    required this.name,
    required this.congregationId,
    required this.weeks,
    required this.done,
    required this.total,
    required this.status,
    required this.editedLabel,
  });

  /// Fracción de avance 0..1 para la barra de progreso.
  double get progress => total == 0 ? 0 : done / total;

  Project copyWith({
    String? name,
    String? congregationId,
    List<String>? weeks,
    int? done,
    int? total,
    ProjectStatus? status,
    String? editedLabel,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      congregationId: congregationId ?? this.congregationId,
      weeks: weeks ?? this.weeks,
      done: done ?? this.done,
      total: total ?? this.total,
      status: status ?? this.status,
      editedLabel: editedLabel ?? this.editedLabel,
    );
  }
}
