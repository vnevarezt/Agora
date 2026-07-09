import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program_row.dart';
import 'program_form.dart';

/// Reference to a concrete UI assignment slot. Maps onto the form's existing
/// storage ([FormModel.main] / [FormModel.auxiliary], lists keyed by
/// `ProgramRow.id`) without changing its contract.
sealed class SlotRef {
  const SlotRef();

  /// Stable key (e.g. "chairman", "te0:0", "se1:aux:1").
  String get key;

  @override
  bool operator ==(Object other) => other is SlotRef && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Meeting chairman ([FormModel.chairman]).
class ChairmanSlot extends SlotRef {
  const ChairmanSlot();

  @override
  String get key => 'chairman';
}

/// Position [index] within a row's name list (main hall or auxiliary room,
/// depending on [aux]).
class RowSlot extends SlotRef {
  const RowSlot(this.row, this.index, {this.aux = false});

  final ProgramRow row;
  final int index;
  final bool aux;

  @override
  String get key => aux ? '${row.id}:aux:$index' : '${row.id}:$index';
}

/// List of [slots] entries with [name] placed at [index], keeping the other
/// values of [current] (pure, testable function).
List<String> listWithName(
    List<String>? current, int slots, int index, String name) {
  return [
    for (var i = 0; i < slots; i++)
      i == index
          ? name
          : (current != null && i < current.length ? current[i] : ''),
  ];
}

/// How many of the first [slots] entries of [names] are filled.
int filledNames(List<String>? names, int slots) {
  if (names == null) return 0;
  var n = 0;
  for (var i = 0; i < slots && i < names.length; i++) {
    if (names[i].trim().isNotEmpty) n++;
  }
  return n;
}

/// Name currently assigned to [slot] ('' if empty).
String slotName(FormModel f, SlotRef slot) {
  return switch (slot) {
    ChairmanSlot() => f.chairman,
    RowSlot(:final row, :final index, :final aux) => () {
        final list = aux ? f.auxiliary[row.id] : f.main[row.id];
        return (list != null && index < list.length) ? list[index] : '';
      }(),
  };
}

/// Writes [name] into [slot] using the form's existing setters. Clearing = "".
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
