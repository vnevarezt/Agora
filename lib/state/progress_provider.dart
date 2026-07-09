import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/schedule_rules.dart';
import '../models/program_row.dart';
import 'assignment_ops.dart';
import 'program_form.dart';
import 'weeks_provider.dart';

typedef Progress = ({int done, int total});

/// Counts assigned/total slots of a given schedule against the assignments
/// (chairman + per-row lists). Slots, not rows: pairs and the auxiliary room
/// each count for what they're worth.
Progress _progressOf(
  ProgramSchedule schedule, {
  required String chairman,
  required Map<String, List<String>> main,
  required Map<String, List<String>> auxiliary,
  required bool auxRoom,
}) {
  var total = 1; // chairman
  var done = chairman.trim().isEmpty ? 0 : 1;
  for (final ProgramRow row in schedule.rows) {
    total += row.slots;
    done += filledNames(main[row.id], row.slots);
    if (auxRoom && row.auxSlots > 0) {
      total += row.auxSlots;
      done += filledNames(auxiliary[row.id], row.auxSlots);
    }
  }
  return (done: done, total: total);
}

/// Progress of the active week. Feeds the selector ring and the mobile bottom
/// bar.
final progressProvider = Provider<Progress>((ref) {
  final schedule = ref.watch(scheduleProvider);
  if (schedule == null) return (done: 0, total: 0);
  final f = ref.watch(formProvider);
  return _progressOf(schedule,
      chairman: f.chairman,
      main: f.main,
      auxiliary: f.auxiliary,
      auxRoom: f.auxRoom);
});

/// Progress of each notebook week (for the "Go to week" meters).
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

/// Aggregated progress of the whole project (sum of all weeks).
final projectProgressProvider = Provider<Progress>((ref) {
  final list = ref.watch(progressPerWeekProvider);
  var done = 0, total = 0;
  for (final p in list) {
    done += p.done;
    total += p.total;
  }
  return (done: done, total: total);
});
