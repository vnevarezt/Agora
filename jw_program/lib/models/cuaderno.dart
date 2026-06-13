/// Cuaderno (issue) de Vida y Ministerio: un periodo con sus semanas. Sirve al
/// modal de proyectos para ofrecer las semanas disponibles. Espejo de
/// `cuadernos` del mock.
class Cuaderno {
  final String id;
  final String label;
  final List<String> semanas;

  const Cuaderno({
    required this.id,
    required this.label,
    required this.semanas,
  });
}
