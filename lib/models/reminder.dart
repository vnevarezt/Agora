import '../i18n/strings.g.dart';

/// Reminder type: drives the card's icon and colors.
enum ReminderType { alert, task, info }

/// Dashboard reminder, derived from the drafts' missing assignments.
class Reminder {
  final String id;
  final ReminderType type;

  /// Unassigned parts left in this week — what the title announces.
  final int missing;

  /// Week and project, both already in their own language (workbook text and
  /// a name the user typed), so nothing here needs translating.
  final String meta;

  /// Project the CTA opens (null = no action).
  final String? projectId;

  const Reminder({
    required this.id,
    required this.type,
    required this.missing,
    required this.meta,
    this.projectId,
  });
}

// Takes the active [Translations] rather than the global `t` — the same reason
// as [ProjectStatusX]: this is derived by a provider that has no reason to
// recompute when the app language changes, so a title rendered there would
// keep the language it was built in until the next edit.
extension ReminderX on Reminder {
  String title(Translations tr) => tr.dashboard.pendingItem(n: missing);
}
