/// Congregación a la que pertenece un proyecto. El [color] (0xAARRGGBB)
/// identifica su punto en los filtros/tarjetas; la UI lo envuelve en Color.
class Congregacion {
  final String id;
  final String nombre;
  final String numero;
  final int color;

  const Congregacion({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.color,
  });
}
