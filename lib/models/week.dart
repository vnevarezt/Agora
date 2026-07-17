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

  factory Part.fromJson(Map<String, dynamic> json) => Part(
        section: Section.values.byName(json['section'] as String),
        number: json['number'] as int,
        title: json['title'] as String,
        minutes: json['minutes'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'section': section.name,
        'number': number,
        'title': title,
        'minutes': minutes,
      };
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

  /// JSON snapshot stored in `programs.contentJson` (phase 2): the program
  /// becomes self-contained — it renders offline and survives changes to
  /// the MWB cache it was generated from.
  factory Week.fromJson(Map<String, dynamic> json) => Week(
        date: json['date'] as String? ?? '',
        reading: json['reading'] as String? ?? '',
        openingSong: json['openingSong'] as String?,
        middleSong: json['middleSong'] as String?,
        closingSong: json['closingSong'] as String?,
        introMinutes: json['introMinutes'] as int? ?? 1,
        conclusionMinutes: json['conclusionMinutes'] as int? ?? 3,
        parts: [
          for (final p in (json['parts'] as List? ?? const []))
            Part.fromJson(p as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'reading': reading,
        'openingSong': openingSong,
        'middleSong': middleSong,
        'closingSong': closingSong,
        'introMinutes': introMinutes,
        'conclusionMinutes': conclusionMinutes,
        'parts': [for (final p in parts) p.toJson()],
      };
}
