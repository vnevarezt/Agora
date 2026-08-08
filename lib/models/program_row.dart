// Immutable program structure: rows and blocks. Participant NAMES do NOT live
// here but in the form state; this only holds the structure produced by the
// schedule calculation. See [Assignments].
//
// Rows carry stable IDENTITY ([RowKind], [SlotRole]) rather than rendered text.
// Everything downstream — the workspace cards, the PDF, the column widths —
// used to branch on the Spanish strings this file produced
// (`role == 'Estudiante/Ayudante:'`, `content.startsWith('Canción')`), so
// translating the program silently broke the layout. Presentation now happens
// at the edge, via [ProgramRowX.content] / [SlotRoleX.label], each taking the
// [Translations] of the language that output is meant to be in.

import '../i18n/strings.g.dart';

/// What a row *is*, independent of the text rendered for it.
enum RowKind {
  /// A numbered workbook part. [ProgramRow.title] holds the title parsed from
  /// the EPUB and is NOT translated: it stays in the meeting's own language.
  part,

  /// Opening / middle / closing song, identified by [ProgramRow.songNumber].
  song,

  /// The chairman's opening comments.
  openingWords,

  /// The chairman's concluding comments.
  closingWords,

  /// Talk that replaces the Congregation Bible Study on a circuit overseer's
  /// visit.
  circuitOverseerTalk,
}

/// Who fills a row's slots. Replaces the old free-text role label.
enum SlotRole {
  /// No role prefix printed (talks, discussions).
  none,
  student,
  studentAssistant,
  conductorReader,
  prayer,
  speaker,
}

extension SlotRoleX on SlotRole {
  /// Printed role prefix ('Estudiante/Ayudante:'), in the language of [tr].
  String label(Translations tr) => switch (this) {
        SlotRole.none => '',
        SlotRole.student => tr.program.roleStudent,
        SlotRole.studentAssistant => tr.program.roleStudentAssistant,
        SlotRole.conductorReader => tr.program.roleConductorReader,
        SlotRole.prayer => tr.program.rolePrayer,
        SlotRole.speaker => tr.program.roleSpeaker,
      };

  /// True for the paired student + assistant slot, which the PDF lays out
  /// differently (two names in one cell) and caps to a shorter length.
  bool get isStudentPair => this == SlotRole.studentAssistant;
}

/// A program row (an assignment, a song, or intro/conclusion words).
class ProgramRow {
  /// Stable id within the schedule (block + index), used to link the names.
  final String id;

  /// Time "h:mm".
  final String time;

  final RowKind kind;

  /// Workbook part title, verbatim from the EPUB. Only for [RowKind.part];
  /// empty for generated rows, whose text comes from the catalog.
  final String title;

  /// Song number, only for [RowKind.song].
  final String? songNumber;

  /// Duration in minutes; 0 = not shown.
  final int minutes;

  /// User-supplied replacement for the row's text (see `applyTitleOverrides`).
  /// Wins over [kind]-based rendering; the duration suffix is still appended,
  /// so the duration chip and the PDF stay in sync.
  final String? titleOverride;

  final SlotRole role;

  /// Number of names in the Main Hall (0 = no assignment; 1; 2 = pair).
  final int slots;

  /// Number of names in the Auxiliary Room (>0 only on aux-eligible rows).
  final int auxSlots;

  /// Can have a parallel assignment in the Auxiliary Room (S-38 §26).
  final bool auxEligible;

  const ProgramRow({
    required this.id,
    required this.time,
    required this.kind,
    this.title = '',
    this.songNumber,
    this.minutes = 0,
    this.titleOverride,
    this.role = SlotRole.none,
    this.slots = 1,
    this.auxSlots = 0,
    this.auxEligible = false,
  });

  /// Bulleted in the printed program: songs and the chairman's comments.
  bool get bullet =>
      kind == RowKind.song ||
      kind == RowKind.openingWords ||
      kind == RowKind.closingWords;

  ProgramRow copyWith({
    String? id,
    String? time,
    RowKind? kind,
    String? title,
    String? songNumber,
    int? minutes,
    String? titleOverride,
    SlotRole? role,
    int? slots,
    int? auxSlots,
    bool? auxEligible,
  }) {
    return ProgramRow(
      id: id ?? this.id,
      time: time ?? this.time,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      songNumber: songNumber ?? this.songNumber,
      minutes: minutes ?? this.minutes,
      titleOverride: titleOverride ?? this.titleOverride,
      role: role ?? this.role,
      slots: slots ?? this.slots,
      auxSlots: auxSlots ?? this.auxSlots,
      auxEligible: auxEligible ?? this.auxEligible,
    );
  }
}

extension ProgramRowX on ProgramRow {
  /// The row's display text, in the language of [tr].
  ///
  /// [RowKind.part] returns the EPUB title untouched (plus its duration): the
  /// workbook content is authored in the meeting's language and is not ours to
  /// translate. Every other kind is generated from the catalog.
  String content(Translations tr) {
    final text = titleOnly(tr);
    if (minutes <= 0) return text;
    // The chairman's comments print "(1 min.)"; parts print "(10 mins.)".
    // Two keys rather than a plural rule, to match the S-140 form exactly.
    return switch (kind) {
      RowKind.openingWords || RowKind.closingWords =>
        tr.program.commentsWithDuration(title: text, n: minutes),
      _ => tr.program.partWithDuration(title: text, n: minutes),
    };
  }

  /// The row's text WITHOUT the duration suffix. The workspace shows the
  /// duration as a separate chip, so it needs the two apart.
  String titleOnly(Translations tr) {
    final override = titleOverride;
    if (override != null) return override;
    return switch (kind) {
      RowKind.part => title,
      RowKind.song => tr.program.song(n: songNumber ?? ''),
      RowKind.openingWords => tr.program.openingWords,
      RowKind.closingWords => tr.program.closingWords,
      RowKind.circuitOverseerTalk => tr.program.circuitOverseerTalk,
    };
  }

  /// "10 min" chip for the workspace card, or null when untimed.
  String? durationLabel(Translations tr) =>
      minutes > 0 ? tr.workspace.duration(n: '$minutes') : null;
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
