/// Tipo de recordatorio: define el icono y los colores de la tarjeta.
enum TipoRecordatorio { alerta, tarea, info }

/// Recordatorio del dashboard. Puramente visual en esta fase: el [cta] no
/// dispara ninguna acción todavía.
class Recordatorio {
  final String id;
  final TipoRecordatorio tipo;
  final String titulo;
  final String meta;
  final String cta;

  const Recordatorio({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.meta,
    required this.cta,
  });
}
