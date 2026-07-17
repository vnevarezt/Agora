import '../i18n/strings.g.dart';

/// Project status on the dashboard.
enum ProjectStatus { draft, complete, exported }

extension ProjectStatusX on ProjectStatus {
  /// Singular label for the badge ("Borrador").
  String get label => switch (this) {
        ProjectStatus.draft => t.status.draft,
        ProjectStatus.complete => t.status.complete,
        ProjectStatus.exported => t.status.exported,
      };

  /// Plural label for the filter chips ("Borradores").
  String get plural => switch (this) {
        ProjectStatus.draft => t.status.draftPlural,
        ProjectStatus.complete => t.status.completePlural,
        ProjectStatus.exported => t.status.exportedPlural,
      };
}

/// Per-week progress of a project (hero card chips).
typedef WeekProgress = ({String label, int done, int total});

/// Dashboard project CARD: view model computed from the DB rows by
/// `projectsProvider` (status/progress/edited label are derived, never
/// stored — docs/PHASE1_LOCAL_PERSISTENCE.md).
class Project {
  final String id;
  final String name;
  final String congregationId;
  final List<String> weeks;
  final int done;
  final int total;
  final ProjectStatus status;

  /// Relative last-edited text ("hace 2 horas").
  final String editedLabel;

  /// Raw edit stamp (picks the hero "continue" project).
  final DateTime updatedAt;

  /// Per-week done/total, in week order (hero card chips).
  final List<WeekProgress> weekProgress;

  const Project({
    required this.id,
    required this.name,
    required this.congregationId,
    required this.weeks,
    required this.done,
    required this.total,
    required this.status,
    required this.editedLabel,
    required this.updatedAt,
    this.weekProgress = const [],
  });

  /// Progress fraction 0..1 for the progress bar.
  double get progress => total == 0 ? 0 : done / total;
}
