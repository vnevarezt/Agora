// Modelos de datos de una semana del programa Vida y Ministerio Cristiano.
//
// Espejo del dict que produce `parsear_semana` en generar_programa.py
// (generador/generar_programa.py:68-70 y :104-105).

/// Sección de la reunión a la que pertenece una parte.
/// Coincide con los valores de SECCION_POR_COLOR del .py:
///   teal -> tesoros, gold -> seamos, maroon -> vida.
enum Seccion { tesoros, seamos, vida }

/// Una parte numerada del programa (h3 "N. Título" en el EPUB).
class Part {
  final Seccion seccion;
  final int num;
  final String titulo;

  /// Duración en minutos, o null si el EPUB no la especifica.
  final int? min;

  const Part({
    required this.seccion,
    required this.num,
    required this.titulo,
    this.min,
  });
}

/// Programa completo de una semana.
class Week {
  String fecha;
  String lectura;

  /// Número de canción (como String) o null si no aparece.
  String? cancionInicial;
  String? cancionMedia;
  String? cancionFinal;

  int introMin;
  int conclusionMin;

  final List<Part> partes;

  Week({
    this.fecha = '',
    this.lectura = '',
    this.cancionInicial,
    this.cancionMedia,
    this.cancionFinal,
    this.introMin = 1,
    this.conclusionMin = 3,
    List<Part>? partes,
  }) : partes = partes ?? <Part>[];
}
