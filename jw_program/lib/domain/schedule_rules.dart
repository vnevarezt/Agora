import '../models/program_row.dart';
import '../models/week.dart';

/// Assignment rules and meeting-clock calculation (pure logic).
///
/// Port of generar_programa.py:129-246 (rol_y_nombres, es_aux_elegible,
/// construir_filas, hhmm) and the SEAMOS_MIN / CONSEJO_MIN constants.

const int ministryMinutes = 15; // "Apply Yourself" section lasts 15 min (S-38 §6)
const int adviceMinutes = 1; // chairman's counsel after each student (§18)

/// hh:mm with no leading zero on the hour.
String hhmm(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

/// Role label + number of names for a part. The match strings stay in Spanish
/// because they test the title parsed from the jw.org workbook.
({String role, int n}) roleAndNames(Section section, String title) {
  final t = title.toLowerCase();
  switch (section) {
    case Section.treasures:
      if (t.contains('lectura de la biblia')) return (role: 'Estudiante:', n: 1);
      return (role: '', n: 1); // talk / spiritual gems
    case Section.ministry:
      if (t.contains('discurso')) return (role: 'Estudiante:', n: 1);
      return (role: 'Estudiante/Ayudante:', n: 2); // demonstration
    case Section.christianLife:
      if (t.contains('estudio bíblico de la congregaci')) {
        return (role: 'Conductor/Lector:', n: 2);
      }
      return (role: '', n: 1); // discussion / talk
  }
}

/// Parts with a parallel assignment in the auxiliary room (S-38 §26): Bible
/// Reading + every part of the "Apply Yourself to the Ministry" section.
bool isAuxEligible(Section section, String title) {
  if (section == Section.treasures &&
      title.toLowerCase().contains('lectura de la biblia')) {
    return true;
  }
  if (section == Section.ministry) return true;
  return false;
}

ProgramRow _row(String id, Section section, int t, Part p) {
  final roleNames = roleAndNames(section, p.title);
  final mins = p.minutes ?? 0;
  final content = mins > 0 ? '${p.title} ($mins mins.)' : p.title;
  final eligible = isAuxEligible(section, p.title);
  return ProgramRow(
    id: id,
    time: hhmm(t),
    content: content,
    role: roleNames.role,
    slots: roleNames.n,
    auxSlots: eligible ? roleNames.n : 0,
    auxEligible: eligible,
  );
}

/// Default title for the talk that replaces the Congregation Bible Study on a
/// circuit overseer's visit. Stays in the meeting language, like the other
/// fixed titles built here ("Palabras de introducción", "Canción N").
const String circuitOverseerTalkTitle =
    'Discurso del superintendente de circuito';

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
  Part? cbs;
  for (final p in life) {
    if (p.title.toLowerCase().contains('estudio bíblico de la congrega')) {
      cbs = p;
      break;
    }
  }
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
      content: 'Canción ${week.openingSong}',
      role: 'Oración:',
      bullet: true,
    ));
    t += sOpen;
  }
  opening.add(ProgramRow(
    id: 'ap${opening.length}',
    time: hhmm(t),
    content: 'Palabras de introducción ($intro min.)',
    bullet: true,
    slots: 0,
  ));
  t += intro;

  // --- Treasures From God's Word (counsel after the Bible Reading) ---
  for (final p in treasures) {
    treasuresRows.add(_row('te${treasuresRows.length}', Section.treasures, t, p));
    t += (p.minutes ?? 0);
    if (p.title.toLowerCase().contains('lectura de la biblia')) {
      t += adviceMinutes;
    }
  }

  // --- Apply Yourself: 15-min block, +1 of counsel per part ---
  final ministryStart = t;
  for (final p in ministry) {
    ministryRows.add(_row('se${ministryRows.length}', Section.ministry, t, p));
    t += (p.minutes ?? 0) + adviceMinutes;
  }
  t = ministryStart + ministryMinutes; // pin the section to 15 min

  // --- Living as Christians ---
  if (week.middleSong != null) {
    lifeRows.add(ProgramRow(
      id: 'vi${lifeRows.length}',
      time: hhmm(t),
      content: 'Canción ${week.middleSong}',
      bullet: true,
      slots: 0,
    ));
    t += sMid;
  }
  for (final p in lifeNoCbs) {
    lifeRows.add(_row('vi${lifeRows.length}', Section.christianLife, t, p));
    t += (p.minutes ?? 0);
  }
  if (cbs != null) {
    if (circuitOverseer) {
      // Circuit overseer visit: the CBS becomes the overseer's talk (1 speaker).
      lifeRows.add(ProgramRow(
        id: 'vi${lifeRows.length}',
        time: hhmm(t),
        content: '$circuitOverseerTalkTitle ($cbsMinutes mins.)',
        role: 'Orador:',
        slots: 1,
      ));
    } else {
      lifeRows.add(_row('vi${lifeRows.length}', Section.christianLife, t, cbs));
    }
    t += cbsMinutes;
  }

  // --- Conclusion and closing song ---
  // Skipped on a circuit overseer visit (the meeting closes with his talk).
  if (!circuitOverseer) {
    lifeRows.add(ProgramRow(
      id: 'vi${lifeRows.length}',
      time: hhmm(t),
      content: 'Palabras de conclusión ($concl min.)',
      bullet: true,
      slots: 0,
    ));
    t += concl;
  }
  if (week.closingSong != null) {
    lifeRows.add(ProgramRow(
      id: 'vi${lifeRows.length}',
      time: hhmm(t),
      content: 'Canción ${week.closingSong}',
      role: 'Oración:',
      bullet: true,
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

final _titleDurationSuffix = RegExp(r'\s*\(\d+\s*mins?\.\)$');

/// Replaces a row's title with the user override (keyed by `ProgramRow.id`)
/// while keeping its "(N mins.)" suffix, so the duration chip and the PDF stay
/// in sync. Returns [schedule] unchanged when there are no overrides.
ProgramSchedule applyTitleOverrides(
    ProgramSchedule schedule, Map<String, String> overrides) {
  if (overrides.isEmpty) return schedule;
  List<ProgramRow> mapped(List<ProgramRow> rows) => [
        for (final r in rows)
          if (overrides.containsKey(r.id))
            r.copyWith(
              content: overrides[r.id]! +
                  (_titleDurationSuffix.firstMatch(r.content)?.group(0) ?? ''),
            )
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
