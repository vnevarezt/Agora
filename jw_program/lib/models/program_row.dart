// Estructura (inmutable) del programa: filas y bloques. Los NOMBRES de los
// participantes NO viven aquí, sino en el estado del formulario; aquí solo está
// la estructura que produce el cálculo del horario. Ver [Assignments].

/// Una fila del programa (una asignación, canción, palabras de intro/conclusión).
class ProgramRow {
  /// Id estable dentro del horario (bloque + índice), para asociar los nombres.
  final String id;

  /// Hora "h:mm".
  final String time;

  /// Texto del contenido (título + duración, o "Canción N").
  final String content;

  /// Etiqueta de rol ("Estudiante:", "Estudiante/Ayudante:", "Oración:"…) o "".
  final String role;

  /// Nº de nombres en Auditorio Principal (0 = sin asignación; 1; 2 = pareja).
  final int slots;

  /// Nº de nombres en Sala Auxiliar (>0 solo en filas auxiliar-elegibles).
  final int auxSlots;

  /// Con viñeta (canciones, intro y conclusión).
  final bool bullet;

  /// Puede tener asignación paralela en Sala Auxiliar (S-38 §26).
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
}

/// Filas calculadas por bloque + duración real de la reunión.
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

  /// Todas las filas en orden de aparición.
  List<ProgramRow> get rows =>
      [...opening, ...treasures, ...ministry, ...christianLife];
}

/// Nombres de los participantes, indexados por `ProgramRow.id`. Es el puente
/// entre el estado editable (formulario) y la generación del PDF.
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

/// Une 1–2 nombres como los muestra el formato: "a / b", "a" o "".
String joinedNames(List<String> n) {
  if (n.isEmpty) return '';
  if (n.length >= 2) return '${n[0]} / ${n[1]}';
  return n[0];
}
