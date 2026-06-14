/// Reminder type: drives the card's icon and colors.
enum ReminderType { alert, task, info }

/// Dashboard reminder. Purely visual for now: the [cta] doesn't trigger any
/// action yet.
class Reminder {
  final String id;
  final ReminderType type;
  final String title;
  final String meta;
  final String cta;

  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.meta,
    required this.cta,
  });
}
