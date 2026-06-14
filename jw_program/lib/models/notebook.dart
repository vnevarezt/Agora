/// Cuaderno (issue) de Vida y Ministerio: un periodo con sus semanas. Sirve al
/// modal de projects para ofrecer las semanas disponibles.
class Notebook {
  final String id;
  final String label;
  final List<String> weeks;

  const Notebook({
    required this.id,
    required this.label,
    required this.weeks,
  });
}
