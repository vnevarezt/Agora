import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/schedule_rules.dart';
import '../models/program_row.dart';
import 'assignment_ops.dart';
import 'program_form.dart';
import 'weeks_provider.dart';

typedef Progress = ({int done, int total});

/// Cuenta huecos asignados/totales de un horario dado contra unas asignaciones
/// (presidente + listas por fila). Slots, no filas: parejas y sala auxiliar
/// pesan cada una lo suyo.
Progress _progressOf(
  ProgramSchedule sched, {
  required String chairman,
  required Map<String, List<String>> main,
  required Map<String, List<String>> auxiliary,
  required bool auxRoom,
}) {
  var total = 1; // presidente
  var done = chairman.trim().isEmpty ? 0 : 1;
  for (final ProgramRow row in sched.rows) {
    total += row.slots;
    done += filledNames(main[row.id], row.slots);
    if (auxRoom && row.auxSlots > 0) {
      total += row.auxSlots;
      done += filledNames(auxiliary[row.id], row.auxSlots);
    }
  }
  return (done: done, total: total);
}

/// Progreso de la semana activa. Alimenta el anillo del selector y la bottom
/// bar móvil.
final progressProvider = Provider<Progress>((ref) {
  final sched = ref.watch(scheduleProvider);
  if (sched == null) return (done: 0, total: 0);
  final f = ref.watch(formProvider);
  return _progressOf(sched,
      chairman: f.chairman,
      main: f.main,
      auxiliary: f.auxiliary,
      auxRoom: f.auxRoom);
});

/// Progreso de cada semana del cuaderno (para los meters de "Ir a la semana").
final progressPerWeekProvider = Provider<List<Progress>>((ref) {
  final weeks = ref.watch(weeksProvider).asData?.value;
  if (weeks == null || weeks.isEmpty) return const [];
  final f = ref.watch(formProvider);
  return [
    for (var i = 0; i < weeks.length; i++)
      _progressOf(
        buildSchedule(weeks[i], f.startMinutes, f.duration),
        chairman: f.chairmanByWeek[i] ?? '',
        main: f.mainByWeek[i] ?? const {},
        auxiliary: f.auxByWeek[i] ?? const {},
        auxRoom: f.auxRoom,
      ),
  ];
});

/// Progreso agregado de todo el proyecto (suma de todas las semanas).
final projectProgressProvider = Provider<Progress>((ref) {
  final list = ref.watch(progressPerWeekProvider);
  var done = 0, total = 0;
  for (final p in list) {
    done += p.done;
    total += p.total;
  }
  return (done: done, total: total);
});
