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

  /// Ministry part that is a student TALK rather than a demonstration (so one
  /// student, no assistant). Read from the workbook at parse time — the marker
  /// can sit in the title or in the body, and only the parser sees the body.
  /// False for every other section.
  ///
  /// Snapshots written before this field existed decode as false, i.e. as a
  /// demonstration — the same answer the old title-only matching gave them.
  final bool isTalk;

  const Part({
    required this.section,
    required this.number,
    required this.title,
    this.minutes,
    this.isTalk = false,
  });

  factory Part.fromJson(Map<String, dynamic> json) => Part(
        section: Section.values.byName(json['section'] as String),
        number: json['number'] as int,
        title: json['title'] as String,
        minutes: json['minutes'] as int?,
        isTalk: json['isTalk'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'section': section.name,
        'number': number,
        'title': title,
        'minutes': minutes,
        'isTalk': isTalk,
      };
}

/// Full program of one week.
class Week {
  /// Heading as the workbook prints it ('6-12 DE JULIO' / 'JULY 6-12'). This
  /// is what the PDF prints, so it stays in the meeting's own language — and
  /// it is exactly why it cannot also be the identity.
  String date;

  /// ISO Monday the week starts on ('2026-07-06'), or empty when the heading
  /// could not be resolved against its issue. THE language-free identity: two
  /// languages of the same week agree here and nowhere else.
  String weekStart;

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
    this.weekStart = '',
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
        // Snapshots written before this field existed decode as empty; the
        // reconciler resolves them from the catalog on the next pass.
        weekStart: json['weekStart'] as String? ?? '',
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
        'weekStart': weekStart,
        'reading': reading,
        'openingSong': openingSong,
        'middleSong': middleSong,
        'closingSong': closingSong,
        'introMinutes': introMinutes,
        'conclusionMinutes': conclusionMinutes,
        'parts': [for (final p in parts) p.toJson()],
      };
}
