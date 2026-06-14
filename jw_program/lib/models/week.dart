// Modelos de datos de una semana del programa Vida y Ministerio Cristiano.
//
// Espejo del dict que produce `parsear_semana` en generar_programa.py
// (generador/generar_programa.py:68-70 y :104-105).

/// Sección de la reunión a la que pertenece una parte.
enum Section { treasures, ministry, christianLife }

/// Una parte numerada del programa (h3 "N. Título" en el EPUB).
class Part {
  final Section section;
  final int number;
  final String title;

  /// Duración en minutos, o null si el EPUB no la especifica.
  final int? minutes;

  const Part({
    required this.section,
    required this.number,
    required this.title,
    this.minutes,
  });
}

/// Programa completo de una semana.
class Week {
  String date;
  String reading;

  /// Número de canción (como String) o null si no aparece.
  String? openingSong;
  String? middleSong;
  String? closingSong;

  int introMinutes;
  int conclusionMinutes;

  final List<Part> parts;

  Week({
    this.date = '',
    this.reading = '',
    this.openingSong,
    this.middleSong,
    this.closingSong,
    this.introMinutes = 1,
    this.conclusionMinutes = 3,
    List<Part>? parts,
  }) : parts = parts ?? <Part>[];
}
