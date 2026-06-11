import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program_row.dart';
import 'assignment_ops.dart';
import 'program_form.dart';

typedef Progreso = ({int done, int total});

/// Huecos asignados / totales de la semana (cuenta slots, no filas: las
/// parejas y la sala auxiliar pesan cada una lo suyo). Alimenta los anillos
/// de progreso de la barra de contexto y de la bottom bar móvil.
final progressProvider = Provider<Progreso>((ref) {
  final sched = ref.watch(scheduleProvider);
  if (sched == null) return (done: 0, total: 0);
  final f = ref.watch(formProvider);

  var total = 1; // presidente
  var done = f.presidente.trim().isEmpty ? 0 : 1;

  for (final ProgramRow row in sched.filas) {
    total += row.slots;
    done += nombresLlenos(f.principal[row.id], row.slots);
    if (f.aux && row.auxSlots > 0) {
      total += row.auxSlots;
      done += nombresLlenos(f.auxiliar[row.id], row.auxSlots);
    }
  }
  return (done: done, total: total);
});
