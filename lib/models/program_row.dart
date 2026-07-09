// Immutable program structure: rows and blocks. Participant NAMES do NOT live
// here but in the form state; this only holds the structure produced by the
// schedule calculation. See [Assignments].

/// A program row (an assignment, a song, or intro/conclusion words).
class ProgramRow {
  /// Stable id within the schedule (block + index), used to link the names.
  final String id;

  /// Time "h:mm".
  final String time;

  /// Content text (title + duration, or "Canción N").
  final String content;

  /// Role label ("Estudiante:", "Estudiante/Ayudante:", "Oración:"…) or "".
  final String role;

  /// Number of names in the Main Hall (0 = no assignment; 1; 2 = pair).
  final int slots;

  /// Number of names in the Auxiliary Room (>0 only on aux-eligible rows).
  final int auxSlots;

  /// Bulleted (songs, intro and conclusion).
  final bool bullet;

  /// Can have a parallel assignment in the Auxiliary Room (S-38 §26).
  final bool auxEligible;

  const ProgramRow({
    required this.id,
    required this.time,
    required this.content,
    this.role = '',
    this.slots = 1,
    this.auxSlots = 0,
    this.bullet = false,
    this.auxEligible = false,
  });

  ProgramRow copyWith({
    String? id,
    String? time,
    String? content,
    String? role,
    int? slots,
    int? auxSlots,
    bool? bullet,
    bool? auxEligible,
  }) {
    return ProgramRow(
      id: id ?? this.id,
      time: time ?? this.time,
      content: content ?? this.content,
      role: role ?? this.role,
      slots: slots ?? this.slots,
      auxSlots: auxSlots ?? this.auxSlots,
      bullet: bullet ?? this.bullet,
      auxEligible: auxEligible ?? this.auxEligible,
    );
  }
}

/// Rows computed per block + the meeting's actual duration.
class ProgramSchedule {
  final List<ProgramRow> opening;
  final List<ProgramRow> treasures;
  final List<ProgramRow> ministry;
  final List<ProgramRow> christianLife;
  final int actualMinutes;

  const ProgramSchedule({
    required this.opening,
    required this.treasures,
    required this.ministry,
    required this.christianLife,
    required this.actualMinutes,
  });

  /// All rows in order of appearance.
  List<ProgramRow> get rows =>
      [...opening, ...treasures, ...ministry, ...christianLife];
}

/// Participant names, indexed by `ProgramRow.id`. The bridge between the
/// editable form state and PDF generation.
class Assignments {
  final Map<String, List<String>> _main;
  final Map<String, List<String>> _auxiliary;

  const Assignments(this._main, this._auxiliary);

  static const empty = Assignments({}, {});

  List<String> main(ProgramRow r) =>
      _main[r.id] ?? List<String>.filled(r.slots, '');

  List<String> auxiliary(ProgramRow r) =>
      _auxiliary[r.id] ?? List<String>.filled(r.auxSlots, '');
}

/// Joins 1–2 names as the format shows them: "a / b", "a" or "".
String joinedNames(List<String> n) {
  if (n.isEmpty) return '';
  if (n.length >= 2) return '${n[0]} / ${n[1]}';
  return n[0];
}
