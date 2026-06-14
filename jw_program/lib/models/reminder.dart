/// Tipo de recordatorio: define el icono y los colores de la tarjeta.
enum ReminderType { alerta, tarea, info }

/// Reminder del dashboard. Puramente visual en esta fase: el [cta] no
/// dispara ninguna acción todavía.
class Reminder {
  final String id;
  final ReminderType tipo;
  final String titulo;
  final String meta;
  final String cta;

  const Reminder({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.meta,
    required this.cta,
  });
}
