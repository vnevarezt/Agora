/// Tipo de recordatorio: define el icono y los colores de la tarjeta.
enum ReminderType { alert, task, info }

/// Recordatorio del dashboard. Puramente visual en esta fase: el [cta] no
/// dispara ninguna acción todavía.
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
