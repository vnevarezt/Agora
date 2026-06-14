import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program_row.dart';
import 'program_form.dart';

/// Referencia a un hueco de asignación concreto de la UI. Mapea sobre el
/// almacenamiento existente del formulario ([FormModel.main] /
/// [FormModel.auxiliary], listas por `ProgramRow.id`) sin cambiar su contrato.
sealed class SlotRef {
  const SlotRef();

  /// Clave estable (p. ej. "presidente", "te0:0", "se1:aux:1").
  String get key;

  @override
  bool operator ==(Object other) => other is SlotRef && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Presidente de la reunión ([FormModel.chairman]).
class ChairmanSlot extends SlotRef {
  const ChairmanSlot();

  @override
  String get key => 'chairman';
}

/// Posición [index] dentro de la list de names de una fila
/// (auditorio principal o sala auxiliar según [aux]).
class RowSlot extends SlotRef {
  const RowSlot(this.row, this.index, {this.aux = false});

  final ProgramRow row;
  final int index;
  final bool aux;

  @override
  String get key => aux ? '${row.id}:aux:$index' : '${row.id}:$index';
}

/// Lista de [slots] entradas con [name] colocado en [index], conservando
/// los demás valores de [current] (función pura, testeable).
List<String> listWithName(
    List<String>? current, int slots, int index, String name) {
  return [
    for (var i = 0; i < slots; i++)
      i == index
          ? name
          : (current != null && i < current.length ? current[i] : ''),
  ];
}

/// Cuántas de las primeras [slots] entradas de [names] están llenas.
int filledNames(List<String>? names, int slots) {
  if (names == null) return 0;
  var n = 0;
  for (var i = 0; i < slots && i < names.length; i++) {
    if (names[i].trim().isNotEmpty) n++;
  }
  return n;
}

/// Nombre actualmente asignado a [slot] ('' si está vacío).
String slotName(FormModel f, SlotRef slot) {
  return switch (slot) {
    ChairmanSlot() => f.chairman,
    RowSlot(:final row, :final index, :final aux) => () {
        final list = aux ? f.auxiliary[row.id] : f.main[row.id];
        return (list != null && index < list.length) ? list[index] : '';
      }(),
  };
}

/// Escribe [name] en [slot] usando los setters existentes del formulario.
/// Limpiar = escribir ''.
void writeAssignment(WidgetRef ref, SlotRef slot, String name) {
  final notifier = ref.read(formProvider.notifier);
  switch (slot) {
    case ChairmanSlot():
      notifier.setChairman(name);
    case RowSlot(:final row, :final index, :final aux):
      final f = ref.read(formProvider);
      final list = listWithName(
        aux ? f.auxiliary[row.id] : f.main[row.id],
        aux ? row.auxSlots : row.slots,
        index,
        name,
      );
      aux
          ? notifier.setAuxNames(row.id, list)
          : notifier.setMainNames(row.id, list);
  }
}
