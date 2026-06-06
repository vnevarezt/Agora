import '../models/week.dart';

/// Reglas de asignación y cálculo del reloj de la reunión.
///
/// Port EXACTO de generar_programa.py:129-246 (rol_y_nombres, es_aux_elegible,
/// construir_filas, hhmm) y de las constantes SEAMOS_MIN / CONSEJO_MIN.

const int seamosMin = 15; // la sección "Seamos mejores maestros" dura 15 min (S-38 §6)
const int consejoMin = 1; // consejo del presidente tras cada asignación de estudiante (§18)

/// hh:mm sin cero a la izquierda en la hora (py:158-160).
String hhmm(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

/// Etiqueta de rol + nº de nombres para una parte (py:129-140).
({String rol, int n}) rolYNombres(Seccion seccion, String titulo) {
  final t = titulo.toLowerCase();
  switch (seccion) {
    case Seccion.tesoros:
      if (t.contains('lectura de la biblia')) return (rol: 'Estudiante:', n: 1);
      return (rol: '', n: 1); // discurso / perlas
    case Seccion.seamos:
      if (t.contains('discurso')) return (rol: 'Estudiante:', n: 1);
      return (rol: 'Estudiante/Ayudante:', n: 2); // demostración
    case Seccion.vida:
      if (t.contains('estudio bíblico de la congregaci')) {
        return (rol: 'Conductor/Lector:', n: 2);
      }
      return (rol: '', n: 1); // análisis / discurso
  }
}

/// Partes que pueden tener asignación paralela en sala auxiliar (S-38 §26):
/// Lectura de la Biblia + todas las partes de "Seamos mejores maestros".
/// (py:142-149 — se conserva aunque el render de aux quede para otra fase.)
bool esAuxElegible(Seccion seccion, String titulo) {
  if (seccion == Seccion.tesoros &&
      titulo.toLowerCase().contains('lectura de la biblia')) {
    return true;
  }
  if (seccion == Seccion.seamos) return true;
  return false;
}

/// Una fila renderizable del programa (modelo intermedio que consume el PDF).
class ProgramRow {
  /// Hora "h:mm".
  final String hora;

  /// Texto del contenido (título + duración, o "Canción N").
  final String contenido;

  /// Etiqueta de rol ("Estudiante:", "Oración:", …) o "".
  final String rol;

  /// Con viñeta (filas \filav: canciones, intro y conclusión).
  final bool vineta;

  /// Marcada como auxiliar-elegible (informativo; no afecta el render no-aux).
  final bool auxElegible;

  /// Nombres editables de los participantes. Su longitud = nº de campos
  /// (0 = sin asignación, p. ej. intro/conclusión/canción sin oración;
  /// 1 = un nombre; 2 = pareja, mostrados unidos por " / ").
  final List<String> nombres;

  ProgramRow({
    required this.hora,
    required this.contenido,
    this.rol = '',
    int slots = 1,
    this.vineta = false,
    this.auxElegible = false,
  }) : nombres = List<String>.filled(slots, '');

  /// Nº de campos de nombre de esta fila.
  int get slots => nombres.length;

  /// Cadena de nombres para el PDF: 2 campos -> "a / b", 1 -> "a", 0 -> "".
  String get nombreTexto {
    if (slots == 0) return '';
    if (slots >= 2) return '${nombres[0]} / ${nombres[1]}';
    return nombres[0];
  }
}

/// Filas calculadas por bloque + duración real de la reunión.
class ProgramSchedule {
  final List<ProgramRow> apertura;
  final List<ProgramRow> tesoros;
  final List<ProgramRow> seamos;
  final List<ProgramRow> vida;
  final int realMin;

  const ProgramSchedule({
    required this.apertura,
    required this.tesoros,
    required this.seamos,
    required this.vida,
    required this.realMin,
  });
}

/// Construye una fila de parte (port de _fila, py:165-180).
ProgramRow _fila(Seccion seccion, int t, Part p) {
  final rn = rolYNombres(seccion, p.titulo);
  final mins = p.min ?? 0;
  final cont = mins > 0 ? '${p.titulo} ($mins mins.)' : p.titulo;
  return ProgramRow(
    hora: hhmm(t),
    contenido: cont,
    rol: rn.rol,
    slots: rn.n,
    auxElegible: esAuxElegible(seccion, p.titulo),
  );
}

/// Calcula el reloj de la reunión respetando duración total, los 15 min de
/// Seamos mejores maestros y el minuto de consejo tras cada asignación.
/// Port de construir_filas (py:182-246).
ProgramSchedule construirFilas(Week semana, int inicioMin, int duracion) {
  final P = semana.partes;
  final tesoros = P.where((p) => p.seccion == Seccion.tesoros).toList();
  final seamos = P.where((p) => p.seccion == Seccion.seamos).toList();
  final vida = P.where((p) => p.seccion == Seccion.vida).toList();
  Part? cbs;
  for (final p in vida) {
    if (p.titulo.toLowerCase().contains('estudio bíblico de la congrega')) {
      cbs = p;
      break;
    }
  }
  final nvPre = vida.where((p) => !identical(p, cbs)).toList();

  final intro = semana.introMin;
  final concl = semana.conclusionMin;
  final tesorosBlock =
      tesoros.fold<int>(0, (s, p) => s + (p.min ?? 0)) + consejoMin;
  final nvPreSum = nvPre.fold<int>(0, (s, p) => s + (p.min ?? 0));
  final cbsMin = (cbs?.min ?? 30);
  final fijo =
      intro + tesorosBlock + seamosMin + nvPreSum + cbsMin + concl;
  final slack = (duracion - fijo) > 9 ? (duracion - fijo) : 9;
  final sOpen = slack ~/ 3;
  final sMid = slack ~/ 3;
  final sClose = slack - sOpen - sMid;

  var t = inicioMin;
  final apertura = <ProgramRow>[];
  final outTesoros = <ProgramRow>[];
  final outSeamos = <ProgramRow>[];
  final outVida = <ProgramRow>[];

  // --- Apertura ---
  if (semana.cancionInicial != null) {
    apertura.add(ProgramRow(
      hora: hhmm(t),
      contenido: 'Canción ${semana.cancionInicial}',
      rol: 'Oración:',
      vineta: true,
    ));
    t += sOpen;
  }
  apertura.add(ProgramRow(
    hora: hhmm(t),
    contenido: 'Palabras de introducción ($intro min.)',
    vineta: true,
    slots: 0,
  ));
  t += intro;

  // --- Tesoros de la Biblia (consejo tras la Lectura) ---
  for (final p in tesoros) {
    outTesoros.add(_fila(Seccion.tesoros, t, p));
    t += (p.min ?? 0);
    if (p.titulo.toLowerCase().contains('lectura de la biblia')) {
      t += consejoMin;
    }
  }

  // --- Seamos mejores maestros: bloque de 15 min, +1 de consejo por parte ---
  final seamosIni = t;
  for (final p in seamos) {
    outSeamos.add(_fila(Seccion.seamos, t, p));
    t += (p.min ?? 0) + consejoMin;
  }
  t = seamosIni + seamosMin; // fija la sección a 15 min

  // --- Nuestra vida cristiana ---
  if (semana.cancionMedia != null) {
    outVida.add(ProgramRow(
      hora: hhmm(t),
      contenido: 'Canción ${semana.cancionMedia}',
      vineta: true,
      slots: 0,
    ));
    t += sMid;
  }
  for (final p in nvPre) {
    outVida.add(_fila(Seccion.vida, t, p));
    t += (p.min ?? 0);
  }
  if (cbs != null) {
    outVida.add(_fila(Seccion.vida, t, cbs));
    t += cbsMin;
  }

  // --- Conclusión y canción final ---
  outVida.add(ProgramRow(
    hora: hhmm(t),
    contenido: 'Palabras de conclusión ($concl min.)',
    vineta: true,
    slots: 0,
  ));
  t += concl;
  if (semana.cancionFinal != null) {
    outVida.add(ProgramRow(
      hora: hhmm(t),
      contenido: 'Canción ${semana.cancionFinal}',
      rol: 'Oración:',
      vineta: true,
    ));
    t += sClose;
  }

  return ProgramSchedule(
    apertura: apertura,
    tesoros: outTesoros,
    seamos: outSeamos,
    vida: outVida,
    realMin: t - inicioMin,
  );
}
