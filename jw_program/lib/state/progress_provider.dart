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
Progress _progresoDe(
  ProgramSchedule sched, {
  required String presidente,
  required Map<String, List<String>> principal,
  required Map<String, List<String>> auxiliar,
  required bool aux,
}) {
  var total = 1; // presidente
  var done = presidente.trim().isEmpty ? 0 : 1;
  for (final ProgramRow row in sched.filas) {
    total += row.slots;
    done += filledNames(principal[row.id], row.slots);
    if (aux && row.auxSlots > 0) {
      total += row.auxSlots;
      done += filledNames(auxiliar[row.id], row.auxSlots);
    }
  }
  return (done: done, total: total);
}

/// Progress de la semana activa. Alimenta el anillo del selector y la bottom
/// bar móvil.
final progressProvider = Provider<Progress>((ref) {
  final sched = ref.watch(scheduleProvider);
  if (sched == null) return (done: 0, total: 0);
  final f = ref.watch(formProvider);
  return _progresoDe(sched,
      presidente: f.presidente,
      principal: f.principal,
      auxiliar: f.auxiliar,
      aux: f.aux);
});

/// Progress de cada semana del cuaderno (para los meters de "Ir a la semana").
final progresoPorSemanaProvider = Provider<List<Progress>>((ref) {
  final weeks = ref.watch(weeksProvider).asData?.value;
  if (weeks == null || weeks.isEmpty) return const [];
  final f = ref.watch(formProvider);
  return [
    for (var i = 0; i < weeks.length; i++)
      _progresoDe(
        buildSchedule(weeks[i], f.inicioMin, f.duracion),
        presidente: f.presidentePorSemana[i] ?? '',
        principal: f.principalPorSemana[i] ?? const {},
        auxiliar: f.auxiliarPorSemana[i] ?? const {},
        aux: f.aux,
      ),
  ];
});

/// Progress agregado de todo el proyecto (suma de todas las semanas).
final progresoProyectoProvider = Provider<Progress>((ref) {
  final lista = ref.watch(progresoPorSemanaProvider);
  var done = 0, total = 0;
  for (final p in lista) {
    done += p.done;
    total += p.total;
  }
  return (done: done, total: total);
});
