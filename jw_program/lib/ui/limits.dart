/// Límites de caracteres de los campos (evitan textos enormes que rompan el
/// layout del PDF; un name completo cabe de sobra).
class Limits {
  Limits._();
  static const int name = 30; // por participante (1 name)
  static const int estAyud = 25; // pareja Estudiante/Ayudante (2 por fila)
  static const int congregationId = 40; // name de la congregación
  static const int notes = 200; // notes de un participant (directorio)
}
