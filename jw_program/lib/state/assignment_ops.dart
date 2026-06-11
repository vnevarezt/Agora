import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program_row.dart';
import 'program_form.dart';

/// Referencia a un hueco de asignación concreto de la UI. Mapea sobre el
/// almacenamiento existente del formulario ([FormModel.principal] /
/// [FormModel.auxiliar], listas por `ProgramRow.id`) sin cambiar su contrato.
sealed class SlotRef {
  const SlotRef();

  /// Clave estable (p. ej. "presidente", "te0:0", "se1:aux:1").
  String get key;

  @override
  bool operator ==(Object other) => other is SlotRef && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Presidente de la reunión ([FormModel.presidente]).
class PresidenteSlot extends SlotRef {
  const PresidenteSlot();

  @override
  String get key => 'presidente';
}

/// Posición [index] dentro de la lista de nombres de una fila
/// (auditorio principal o sala auxiliar según [aux]).
class RowSlot extends SlotRef {
  const RowSlot(this.row, this.index, {this.aux = false});

  final ProgramRow row;
  final int index;
  final bool aux;

  @override
  String get key => aux ? '${row.id}:aux:$index' : '${row.id}:$index';
}

/// Lista de [slots] entradas con [nombre] colocado en [index], conservando
/// los demás valores de [actual] (función pura, testeable).
List<String> listaConNombre(
    List<String>? actual, int slots, int index, String nombre) {
  return [
    for (var i = 0; i < slots; i++)
      i == index
          ? nombre
          : (actual != null && i < actual.length ? actual[i] : ''),
  ];
}

/// Cuántas de las primeras [slots] entradas de [nombres] están llenas.
int nombresLlenos(List<String>? nombres, int slots) {
  if (nombres == null) return 0;
  var n = 0;
  for (var i = 0; i < slots && i < nombres.length; i++) {
    if (nombres[i].trim().isNotEmpty) n++;
  }
  return n;
}

/// Nombre actualmente asignado a [slot] ('' si está vacío).
String nombreDeSlot(FormModel f, SlotRef slot) {
  return switch (slot) {
    PresidenteSlot() => f.presidente,
    RowSlot(:final row, :final index, :final aux) => () {
        final lista = aux ? f.auxiliar[row.id] : f.principal[row.id];
        return (lista != null && index < lista.length) ? lista[index] : '';
      }(),
  };
}

/// Escribe [nombre] en [slot] usando los setters existentes del formulario.
/// Limpiar = escribir ''.
void escribirAsignacion(WidgetRef ref, SlotRef slot, String nombre) {
  final notifier = ref.read(formProvider.notifier);
  switch (slot) {
    case PresidenteSlot():
      notifier.setPresidente(nombre);
    case RowSlot(:final row, :final index, :final aux):
      final f = ref.read(formProvider);
      final lista = listaConNombre(
        aux ? f.auxiliar[row.id] : f.principal[row.id],
        aux ? row.auxSlots : row.slots,
        index,
        nombre,
      );
      aux
          ? notifier.setNombresAux(row.id, lista)
          : notifier.setNombresPrincipal(row.id, lista);
  }
}
