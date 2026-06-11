// Estructura (inmutable) del programa: filas y bloques. Los NOMBRES de los
// participantes NO viven aquí, sino en el estado del formulario; aquí solo está
// la estructura que produce el cálculo del horario. Ver [Asignaciones].

/// Una fila del programa (una asignación, canción, palabras de intro/conclusión).
class ProgramRow {
  /// Id estable dentro del horario (bloque + índice), para asociar los nombres.
  final String id;

  /// Hora "h:mm".
  final String hora;

  /// Texto del contenido (título + duración, o "Canción N").
  final String contenido;

  /// Etiqueta de rol ("Estudiante:", "Estudiante/Ayudante:", "Oración:"…) o "".
  final String rol;

  /// Nº de nombres en Auditorio Principal (0 = sin asignación; 1; 2 = pareja).
  final int slots;

  /// Nº de nombres en Sala Auxiliar (>0 solo en filas auxiliar-elegibles).
  final int auxSlots;

  /// Con viñeta (canciones, intro y conclusión).
  final bool vineta;

  /// Puede tener asignación paralela en Sala Auxiliar (S-38 §26).
  final bool auxElegible;

  const ProgramRow({
    required this.id,
    required this.hora,
    required this.contenido,
    this.rol = '',
    this.slots = 1,
    this.auxSlots = 0,
    this.vineta = false,
    this.auxElegible = false,
  });
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

  /// Todas las filas en orden de aparición.
  List<ProgramRow> get filas =>
      [...apertura, ...tesoros, ...seamos, ...vida];
}

/// Nombres de los participantes, indexados por `ProgramRow.id`. Es el puente
/// entre el estado editable (formulario) y la generación del PDF.
class Asignaciones {
  final Map<String, List<String>> _principal;
  final Map<String, List<String>> _auxiliar;

  const Asignaciones(this._principal, this._auxiliar);

  static const empty = Asignaciones({}, {});

  List<String> principal(ProgramRow r) =>
      _principal[r.id] ?? List<String>.filled(r.slots, '');

  List<String> auxiliar(ProgramRow r) =>
      _auxiliar[r.id] ?? List<String>.filled(r.auxSlots, '');
}

/// Une 1–2 nombres como los muestra el formato: "a / b", "a" o "".
String nombresUnidos(List<String> n) {
  if (n.isEmpty) return '';
  if (n.length >= 2) return '${n[0]} / ${n[1]}';
  return n[0];
}
