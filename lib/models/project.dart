import '../i18n/strings.g.dart';

enum ProjectStatus { draft, complete, exported }

// Takes [Translations], not the global `t` — see the note in `person.dart`.
extension ProjectStatusX on ProjectStatus {
  String label(Translations tr) => switch (this) {
        ProjectStatus.draft => tr.status.draft,
        ProjectStatus.complete => tr.status.complete,
        ProjectStatus.exported => tr.status.exported,
      };

  String plural(Translations tr) => switch (this) {
        ProjectStatus.draft => tr.status.draftPlural,
        ProjectStatus.complete => tr.status.completePlural,
        ProjectStatus.exported => tr.status.exportedPlural,
      };
}

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

  final String editedLabel;

  /// Raw edit stamp (picks the hero "continue" project).
  final DateTime updatedAt;

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

  double get progress => total == 0 ? 0 : done / total;
}
