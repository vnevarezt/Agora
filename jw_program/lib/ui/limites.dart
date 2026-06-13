/// Límites de caracteres de los campos (evitan textos enormes que rompan el
/// layout del PDF; un nombre completo cabe de sobra).
class Limites {
  Limites._();
  static const int nombre = 30; // por participante (1 nombre)
  static const int estAyud = 25; // pareja Estudiante/Ayudante (2 por fila)
  static const int cong = 40; // nombre de la congregación
  static const int notas = 200; // notas de un hermano (directorio)
}
