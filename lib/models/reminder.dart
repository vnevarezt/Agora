/// Reminder type: drives the card's icon and colors.
enum ReminderType { alert, task, info }

/// Dashboard reminder, derived from the drafts' missing assignments.
class Reminder {
  final String id;
  final ReminderType type;
  final String title;
  final String meta;
  final String cta;

  /// Project the CTA opens (null = no action).
  final String? projectId;

  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.meta,
    required this.cta,
    this.projectId,
  });
}
