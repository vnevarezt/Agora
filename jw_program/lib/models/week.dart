// Data models for one week of the Christian Life and Ministry program.
//
// Mirrors the dict produced by `parsear_semana` in generar_programa.py
// (generador/generar_programa.py:68-70 and :104-105).

/// Meeting section a part belongs to.
enum Section { treasures, ministry, christianLife }

/// A numbered program part (h3 "N. Title" in the EPUB).
class Part {
  final Section section;
  final int number;
  final String title;

  /// Duration in minutes, or null if the EPUB doesn't specify it.
  final int? minutes;

  const Part({
    required this.section,
    required this.number,
    required this.title,
    this.minutes,
  });
}

/// Full program of one week.
class Week {
  String date;
  String reading;

  /// Song number (as String) or null if absent.
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
