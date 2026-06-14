/// Congregation a project belongs to. The [color] (0xAARRGGBB) is its dot in
/// the filters/cards; the UI wraps it in a Color.
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
