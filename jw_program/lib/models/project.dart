/// Project status on the dashboard.
enum ProjectStatus { draft, complete, exported }

extension ProjectStatusX on ProjectStatus {
  /// Singular label for the badge ("Borrador").
  String get label => switch (this) {
        ProjectStatus.draft => 'Borrador',
        ProjectStatus.complete => 'Completo',
        ProjectStatus.exported => 'Exportado',
      };

  /// Plural label for the filter chips ("Borradores").
  String get plural => switch (this) {
        ProjectStatus.draft => 'Borradores',
        ProjectStatus.complete => 'Completos',
        ProjectStatus.exported => 'Exportados',
      };
}

/// Dashboard project: the program for a month/period of a congregation.
class Project {
  final String id;
  final String name;
  final String congregationId;
  final List<String> weeks;
  final int done;
  final int total;
  final ProjectStatus status;

  /// Relative last-edited text ("hace 2 horas"); UI placeholder.
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

  /// Progress fraction 0..1 for the progress bar.
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
