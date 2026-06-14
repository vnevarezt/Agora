/// Congregación a la que pertenece un proyecto. El [color] (0xAARRGGBB)
/// identifica su punto en los filtros/tarjetas; la UI lo envuelve en Color.
class Congregation {
  final String id;
  final String name;
  final String number;
  final int color;

  const Congregation({
    required this.id,
    required this.name,
    required this.number,
    required this.color,
  });
}
