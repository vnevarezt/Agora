import '../../models/program_row.dart';
import '../../state/assignment_ops.dart';
import '../limits.dart';

/// Mapper puro fila → vista de tarjeta. Único lugar donde vive la lógica de
/// presentación de las partes (tipo de tarjeta, chips, labels de slots).

enum PartKind {
  /// Línea de una sola fila sin asignación (canción media, intro/conclusión).
  fixedLine,

  /// Tarjeta con huecos de asignación.
  role,
}

/// Un hueco de asignación dentro de una tarjeta.
class SlotSpec {
  final String label;
  final SlotRef ref;
  final int maxLength;

  /// Slots de sala auxiliar: label en color accent.
  final bool accent;

  const SlotSpec({
    required this.label,
    required this.ref,
    required this.maxLength,
    this.accent = false,
  });
}

/// Datos listos para pintar de una tarjeta del workspace.
class PartView {
  final String id;
  final PartKind kind;
  final String time;
  final String title;

  /// "10 min" (extraído del sufijo "(10 mins.)" de `contenido`).
  final String? durationLabel;

  /// Etiqueta de la derecha en líneas fijas ("Cántico", "A cargo del
  /// presidente"); en tarjetas de rol, chip extra de la cabecera.
  final String? fixedTag;

  /// Mostrar "TODA LA REUNIÓN" en lugar de la hora (presidente).
  final bool allMeetingBadge;

  /// Indicador "Sala auxiliar" en la cabecera.
  final bool auxFlag;

  final List<SlotSpec> slots;

  const PartView({
    required this.id,
    required this.kind,
    this.time = '',
    required this.title,
    this.durationLabel,
    this.fixedTag,
    this.allMeetingBadge = false,
    this.auxFlag = false,
    this.slots = const [],
  });
}

final _duracionSufijo = RegExp(r'\s*\((\d+)\s*mins?\.\)$');

/// Labels de slot según el rol de la fila (misma regla que el editor previo).
List<String> _labelsDeRol(ProgramRow row) {
  if (row.slots == 2) {
    return row.rol.contains('Conductor')
        ? const ['Conductor', 'Lector']
        : const ['Estudiante', 'Ayudante'];
  }
  return [row.rol.isNotEmpty ? row.rol.replaceAll(':', '') : 'Encargado'];
}

int _maxLengthDeRol(ProgramRow row) =>
    row.slots == 2 && !row.rol.contains('Conductor')
        ? Limites.estAyud
        : Limites.nombre;

/// Tarjeta sintética del presidente de la reunión.
PartView presidenteView() {
  return const PartView(
    id: 'presidente',
    kind: PartKind.role,
    title: 'Presidente de la reunión',
    allMeetingBadge: true,
    slots: [
      SlotSpec(
        label: 'Presidente',
        ref: PresidenteSlot(),
        maxLength: Limites.nombre,
      ),
    ],
  );
}

/// Mapea una fila del horario a su tarjeta. [auxActivo] = switch Sala
/// Auxiliar del formulario.
PartView mapRow(ProgramRow row, {required bool auxActivo}) {
  final match = _duracionSufijo.firstMatch(row.contenido);
  final titulo = row.contenido.replaceAll(_duracionSufijo, '');
  final duracion = match != null ? '${match.group(1)} min' : null;
  final esCancion = row.contenido.startsWith('Canción');

  if (row.slots == 0) {
    return PartView(
      id: row.id,
      kind: PartKind.fixedLine,
      time: row.hora,
      title: titulo,
      durationLabel: duracion,
      fixedTag: esCancion ? 'Cántico' : 'A cargo del presidente',
    );
  }

  final labels = _labelsDeRol(row);
  final maxLength = _maxLengthDeRol(row);
  final conAux = auxActivo && row.auxSlots > 0;

  return PartView(
    id: row.id,
    kind: PartKind.role,
    time: row.hora,
    title: titulo,
    durationLabel: duracion,
    // La canción inicial/final lleva el slot de oración en el modelo: se
    // muestra como tarjeta de rol con el chip "Cántico".
    fixedTag: esCancion ? 'Cántico' : null,
    auxFlag: conAux,
    slots: [
      for (var i = 0; i < row.slots; i++)
        SlotSpec(
          label: labels[i],
          ref: RowSlot(row, i),
          maxLength: maxLength,
        ),
      if (conAux)
        for (var i = 0; i < row.auxSlots; i++)
          SlotSpec(
            label: '${labels[i]} · Aux.',
            ref: RowSlot(row, i, aux: true),
            maxLength: maxLength,
            accent: true,
          ),
    ],
  );
}
