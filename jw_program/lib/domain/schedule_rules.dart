import '../models/program_row.dart';
import '../models/week.dart';

/// Reglas de asignación y cálculo del reloj de la reunión (lógica pura).
///
/// Port de generar_programa.py:129-246 (rol_y_nombres, es_aux_elegible,
/// construir_filas, hhmm) y de las constantes SEAMOS_MIN / CONSEJO_MIN.

const int ministryMinutes = 15; // "Seamos mejores maestros" dura 15 min (S-38 §6)
const int adviceMinutes = 1; // consejo del presidente tras cada estudiante (§18)

/// hh:mm sin cero a la izquierda en la hora.
String hhmm(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

/// Etiqueta de role + nº de nombres para una parte.
({String role, int n}) roleAndNames(Section section, String title) {
  final t = title.toLowerCase();
  switch (section) {
    case Section.treasures:
      if (t.contains('lectura de la biblia')) return (role: 'Estudiante:', n: 1);
      return (role: '', n: 1); // discurso / perlas
    case Section.ministry:
      if (t.contains('discurso')) return (role: 'Estudiante:', n: 1);
      return (role: 'Estudiante/Ayudante:', n: 2); // demostración
    case Section.christianLife:
      if (t.contains('estudio bíblico de la congregaci')) {
        return (role: 'Conductor/Lector:', n: 2);
      }
      return (role: '', n: 1); // análisis / discurso
  }
}

/// Partes con asignación paralela en sala auxiliar (S-38 §26): Lectura de la
/// Biblia + todas las partes de "Seamos mejores maestros".
bool isAuxEligible(Section section, String title) {
  if (section == Section.treasures &&
      title.toLowerCase().contains('lectura de la biblia')) {
    return true;
  }
  if (section == Section.ministry) return true;
  return false;
}

ProgramRow _row(String id, Section section, int t, Part p) {
  final rn = roleAndNames(section, p.title);
  final mins = p.minutes ?? 0;
  final cont = mins > 0 ? '${p.title} ($mins mins.)' : p.title;
  final eligible = isAuxEligible(section, p.title);
  return ProgramRow(
    id: id,
    time: hhmm(t),
    content: cont,
    role: rn.role,
    slots: rn.n,
    auxSlots: eligible ? rn.n : 0,
    auxEligible: eligible,
  );
}

/// Construye el horario respetando duración total, los 15 min de Seamos y el
/// minuto de consejo tras cada asignación de estudiante.
ProgramSchedule buildSchedule(Week week, int startMinutes, int duration) {
  final P = week.parts;
  final tesoros = P.where((p) => p.section == Section.treasures).toList();
  final seamos = P.where((p) => p.section == Section.ministry).toList();
  final vida = P.where((p) => p.section == Section.christianLife).toList();
  Part? cbs;
  for (final p in vida) {
    if (p.title.toLowerCase().contains('estudio bíblico de la congrega')) {
      cbs = p;
      break;
    }
  }
  final nvPre = vida.where((p) => !identical(p, cbs)).toList();

  final intro = week.introMinutes;
  final concl = week.conclusionMinutes;
  final treasuresBlock =
      tesoros.fold<int>(0, (s, p) => s + (p.minutes ?? 0)) + adviceMinutes;
  final nvPreSum = nvPre.fold<int>(0, (s, p) => s + (p.minutes ?? 0));
  final cbsMin = (cbs?.minutes ?? 30);
  final fixed = intro + treasuresBlock + ministryMinutes + nvPreSum + cbsMin + concl;
  final slack = (duration - fixed) > 9 ? (duration - fixed) : 9;
  final sOpen = slack ~/ 3;
  final sMid = slack ~/ 3;
  final sClose = slack - sOpen - sMid;

  var t = startMinutes;
  final apertura = <ProgramRow>[];
  final outTesoros = <ProgramRow>[];
  final outSeamos = <ProgramRow>[];
  final outVida = <ProgramRow>[];

  // --- Apertura ---
  if (week.openingSong != null) {
    apertura.add(ProgramRow(
      id: 'ap${apertura.length}',
      time: hhmm(t),
      content: 'Canción ${week.openingSong}',
      role: 'Oración:',
      bullet: true,
    ));
    t += sOpen;
  }
  apertura.add(ProgramRow(
    id: 'ap${apertura.length}',
    time: hhmm(t),
    content: 'Palabras de introducción ($intro min.)',
    bullet: true,
    slots: 0,
  ));
  t += intro;

  // --- Tesoros de la Biblia (consejo tras la Lectura) ---
  for (final p in tesoros) {
    outTesoros.add(_row('te${outTesoros.length}', Section.treasures, t, p));
    t += (p.minutes ?? 0);
    if (p.title.toLowerCase().contains('lectura de la biblia')) {
      t += adviceMinutes;
    }
  }

  // --- Seamos mejores maestros: bloque de 15 min, +1 de consejo por parte ---
  final seamosIni = t;
  for (final p in seamos) {
    outSeamos.add(_row('se${outSeamos.length}', Section.ministry, t, p));
    t += (p.minutes ?? 0) + adviceMinutes;
  }
  t = seamosIni + ministryMinutes; // fija la sección a 15 min

  // --- Nuestra vida cristiana ---
  if (week.middleSong != null) {
    outVida.add(ProgramRow(
      id: 'vi${outVida.length}',
      time: hhmm(t),
      content: 'Canción ${week.middleSong}',
      bullet: true,
      slots: 0,
    ));
    t += sMid;
  }
  for (final p in nvPre) {
    outVida.add(_row('vi${outVida.length}', Section.christianLife, t, p));
    t += (p.minutes ?? 0);
  }
  if (cbs != null) {
    outVida.add(_row('vi${outVida.length}', Section.christianLife, t, cbs));
    t += cbsMin;
  }

  // --- Conclusión y canción final ---
  outVida.add(ProgramRow(
    id: 'vi${outVida.length}',
    time: hhmm(t),
    content: 'Palabras de conclusión ($concl min.)',
    bullet: true,
    slots: 0,
  ));
  t += concl;
  if (week.closingSong != null) {
    outVida.add(ProgramRow(
      id: 'vi${outVida.length}',
      time: hhmm(t),
      content: 'Canción ${week.closingSong}',
      role: 'Oración:',
      bullet: true,
    ));
    t += sClose;
  }

  return ProgramSchedule(
    opening: apertura,
    treasures: outTesoros,
    ministry: outSeamos,
    christianLife: outVida,
    actualMinutes: t - startMinutes,
  );
}
