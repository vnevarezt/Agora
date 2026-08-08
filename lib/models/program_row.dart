// Immutable program structure: rows and blocks. Participant NAMES do NOT live
// here but in the form state; this only holds the structure produced by the
// schedule calculation. See [Assignments].
//
// Rows carry IDENTITY ([RowKind], [SlotRole]), never rendered text: downstream
// used to branch on the Spanish strings this file produced, so translating the
// program broke the layout. Rendering happens at the edge, via
// [ProgramRowX.content] / [SlotRoleX.label], against a target [Translations].

import '../i18n/strings.g.dart';

enum RowKind {
  /// A numbered workbook part. [ProgramRow.title] holds the title parsed from
  /// the EPUB and is NOT translated: it stays in the meeting's own language.
  part,

  song,

  openingWords,

  closingWords,

  circuitOverseerTalk,
}

enum SlotRole {
  none,
  student,
  studentAssistant,
  conductorReader,
  prayer,
  speaker,
}

extension SlotRoleX on SlotRole {
  /// Printed role prefix ('Estudiante/Ayudante:'), in [tr]'s language.
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
  /// Wins over [kind]-based rendering; the duration is still appended.
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
  /// The row's display text in [tr]'s language. [RowKind.part] keeps the EPUB
  /// title verbatim — workbook content is authored in the meeting's language.
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

  /// Text without the duration — the workspace shows that as its own chip.
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
