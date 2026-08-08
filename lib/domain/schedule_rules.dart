import '../models/program_row.dart';
import '../models/week.dart';

/// Assignment rules and meeting-clock calculation (pure logic).

const int ministryMinutes = 15; // "Apply Yourself" section lasts 15 min (S-38 §6)
const int adviceMinutes = 1; // chairman's counsel after each student (§18)

/// hh:mm with no leading zero on the hour.
String hhmm(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

/// Role + number of names for a part.
///
/// Positional, so it holds in any meeting language: the Bible Reading closes
/// Treasures and the Congregation Bible Study closes Living as Christians
/// (verified across both mwb_202607 workbooks, 9 weeks each). Position cannot
/// tell a ministry talk from a demonstration, hence [Part.isTalk].
({SlotRole role, int n}) roleAndNames(
  Section section,
  Part part, {
  required bool isLastInSection,
}) {
  switch (section) {
    case Section.treasures:
      if (isLastInSection) return (role: SlotRole.student, n: 1); // Bible Reading
      return (role: SlotRole.none, n: 1); // talk / spiritual gems
    case Section.ministry:
      if (part.isTalk) return (role: SlotRole.student, n: 1);
      return (role: SlotRole.studentAssistant, n: 2); // demonstration
    case Section.christianLife:
      if (isLastInSection) return (role: SlotRole.conductorReader, n: 2); // CBS
      return (role: SlotRole.none, n: 1); // discussion / talk
  }
}

/// Parts with a parallel assignment in the auxiliary room (S-38 §26): Bible
/// Reading + every part of the "Apply Yourself to the Ministry" section.
bool isAuxEligible(Section section, {required bool isLastInSection}) =>
    (section == Section.treasures && isLastInSection) ||
    section == Section.ministry;

ProgramRow _row(String id, Section section, int t, Part p,
    {required bool isLastInSection}) {
  final roleNames =
      roleAndNames(section, p, isLastInSection: isLastInSection);
  final eligible =
      isAuxEligible(section, isLastInSection: isLastInSection);
  return ProgramRow(
    id: id,
    time: hhmm(t),
    kind: RowKind.part,
    title: p.title,
    minutes: p.minutes ?? 0,
    role: roleNames.role,
    slots: roleNames.n,
    auxSlots: eligible ? roleNames.n : 0,
    auxEligible: eligible,
  );
}

/// Builds the schedule honoring the total duration, the fixed 15 min of the
/// ministry section and the one-minute counsel after each student assignment.
///
/// When [circuitOverseer] is true, the Congregation Bible Study is replaced by
/// the overseer's talk: a single speaker ("Orador:") keeping the same slot.
ProgramSchedule buildSchedule(Week week, int startMinutes, int duration,
    {bool circuitOverseer = false}) {
  final parts = week.parts;
  final treasures = parts.where((p) => p.section == Section.treasures).toList();
  final ministry = parts.where((p) => p.section == Section.ministry).toList();
  final life = parts.where((p) => p.section == Section.christianLife).toList();
  final Part? cbs = life.isEmpty ? null : life.last; // see [roleAndNames]
  final lifeNoCbs = life.where((p) => !identical(p, cbs)).toList();

  final intro = week.introMinutes;
  final concl = week.conclusionMinutes;
  final treasuresBlock =
      treasures.fold<int>(0, (s, p) => s + (p.minutes ?? 0)) + adviceMinutes;
  final lifeNoCbsSum = lifeNoCbs.fold<int>(0, (s, p) => s + (p.minutes ?? 0));
  final cbsMinutes = (cbs?.minutes ?? 30);
  // On a circuit overseer visit the meeting ends with the overseer's talk, so
  // there are no concluding comments: that time is freed back into the slack.
  final conclBlock = circuitOverseer ? 0 : concl;
  final fixed = intro +
      treasuresBlock +
      ministryMinutes +
      lifeNoCbsSum +
      cbsMinutes +
      conclBlock;
  final slack = (duration - fixed) > 9 ? (duration - fixed) : 9;
  final sOpen = slack ~/ 3;
  final sMid = slack ~/ 3;
  final sClose = slack - sOpen - sMid;

  var t = startMinutes;
  final opening = <ProgramRow>[];
  final treasuresRows = <ProgramRow>[];
  final ministryRows = <ProgramRow>[];
  final lifeRows = <ProgramRow>[];

  // --- Opening ---
  if (week.openingSong != null) {
    opening.add(ProgramRow(
      id: 'ap${opening.length}',
      time: hhmm(t),
      kind: RowKind.song,
      songNumber: week.openingSong,
      role: SlotRole.prayer,
    ));
    t += sOpen;
  }
  opening.add(ProgramRow(
    id: 'ap${opening.length}',
    time: hhmm(t),
    kind: RowKind.openingWords,
    minutes: intro,
    slots: 0,
  ));
  t += intro;

  // --- Treasures From God's Word (counsel after the Bible Reading) ---
  for (final p in treasures) {
    final isLast = identical(p, treasures.last);
    treasuresRows.add(_row(
        'te${treasuresRows.length}', Section.treasures, t, p,
        isLastInSection: isLast));
    t += (p.minutes ?? 0);
    if (isLast) t += adviceMinutes; // counsel after the Bible Reading
  }

  // --- Apply Yourself: 15-min block, +1 of counsel per part ---
  final ministryStart = t;
  for (final p in ministry) {
    ministryRows.add(_row('se${ministryRows.length}', Section.ministry, t, p,
        isLastInSection: identical(p, ministry.last)));
    t += (p.minutes ?? 0) + adviceMinutes;
  }
  t = ministryStart + ministryMinutes; // pin the section to 15 min

  // --- Living as Christians ---
  if (week.middleSong != null) {
    lifeRows.add(ProgramRow(
      id: 'vi${lifeRows.length}',
      time: hhmm(t),
      kind: RowKind.song,
      songNumber: week.middleSong,
      slots: 0,
    ));
    t += sMid;
  }
  for (final p in lifeNoCbs) {
    lifeRows.add(_row('vi${lifeRows.length}', Section.christianLife, t, p,
        isLastInSection: false));
    t += (p.minutes ?? 0);
  }
  if (cbs != null) {
    if (circuitOverseer) {
      // Circuit overseer visit: the CBS becomes the overseer's talk (1 speaker).
      lifeRows.add(ProgramRow(
        id: 'vi${lifeRows.length}',
        time: hhmm(t),
        kind: RowKind.circuitOverseerTalk,
        minutes: cbsMinutes,
        role: SlotRole.speaker,
        slots: 1,
      ));
    } else {
      lifeRows.add(_row('vi${lifeRows.length}', Section.christianLife, t, cbs,
          isLastInSection: true));
    }
    t += cbsMinutes;
  }

  // --- Conclusion and closing song ---
  // Skipped on a circuit overseer visit (the meeting closes with his talk).
  if (!circuitOverseer) {
    lifeRows.add(ProgramRow(
      id: 'vi${lifeRows.length}',
      time: hhmm(t),
      kind: RowKind.closingWords,
      minutes: concl,
      slots: 0,
    ));
    t += concl;
  }
  if (week.closingSong != null) {
    lifeRows.add(ProgramRow(
      id: 'vi${lifeRows.length}',
      time: hhmm(t),
      kind: RowKind.song,
      songNumber: week.closingSong,
      role: SlotRole.prayer,
    ));
    t += sClose;
  }

  return ProgramSchedule(
    opening: opening,
    treasures: treasuresRows,
    ministry: ministryRows,
    christianLife: lifeRows,
    actualMinutes: t - startMinutes,
  );
}

/// Replaces a row's title with the user override (keyed by `ProgramRow.id`).
/// The duration is a field, so it survives the override on its own.
ProgramSchedule applyTitleOverrides(
    ProgramSchedule schedule, Map<String, String> overrides) {
  if (overrides.isEmpty) return schedule;
  List<ProgramRow> mapped(List<ProgramRow> rows) => [
        for (final r in rows)
          if (overrides.containsKey(r.id))
            r.copyWith(titleOverride: overrides[r.id])
          else
            r,
      ];
  return ProgramSchedule(
    opening: mapped(schedule.opening),
    treasures: mapped(schedule.treasures),
    ministry: mapped(schedule.ministry),
    christianLife: mapped(schedule.christianLife),
    actualMinutes: schedule.actualMinutes,
  );
}
