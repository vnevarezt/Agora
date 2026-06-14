import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mwb_calendar.dart';
import '../domain/schedule_rules.dart';
import '../models/program_row.dart';
import '../models/week.dart';
import 'weeks_provider.dart';

/// Editable form state (immutable). Assignments are stored **per week** (index
/// → map keyed by `ProgramRow.id`); the [chairman] / [main] / [auxiliary]
/// getters expose the active week, so everything that consumes the form (PDF,
/// progress, slots) keeps the same contract.
class FormModel {
  final String issue;
  final String congregationId;
  final String startTime; // "HH:MM"
  final int duration; // minutes
  final bool auxRoom;
  final int weekIndex;

  final Map<int, String> chairmanByWeek;
  final Map<int, Map<String, List<String>>> mainByWeek;
  final Map<int, Map<String, List<String>>> auxByWeek;

  const FormModel({
    required this.issue,
    required this.congregationId,
    required this.startTime,
    required this.duration,
    required this.auxRoom,
    required this.weekIndex,
    this.chairmanByWeek = const {},
    this.mainByWeek = const {},
    this.auxByWeek = const {},
  });

  static const initial = FormModel(
    issue: '202605',
    congregationId: 'CONSTITUCIÓN J.A CASTRO',
    startTime: '18:00',
    duration: 105,
    auxRoom: false,
    weekIndex: 0,
  );

  // Active week's assignments (stable contract for the rest of the app).
  String get chairman => chairmanByWeek[weekIndex] ?? '';
  Map<String, List<String>> get main => mainByWeek[weekIndex] ?? const {};
  Map<String, List<String>> get auxiliary => auxByWeek[weekIndex] ?? const {};

  /// Start time in minutes from midnight (falls back to 18:00 if invalid).
  int get startMinutes {
    final p = startTime.split(':');
    if (p.length == 2) {
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h != null && m != null) return h * 60 + m;
    }
    return 18 * 60;
  }

  /// [chairman]/[main]/[auxiliary] overwrite the **resulting week** (the active
  /// one after applying [weekIndex]); the other weeks are preserved.
  FormModel copyWith({
    String? issue,
    String? congregationId,
    String? startTime,
    int? duration,
    bool? auxRoom,
    int? weekIndex,
    String? chairman,
    Map<String, List<String>>? main,
    Map<String, List<String>>? auxiliary,
  }) {
    final idx = weekIndex ?? this.weekIndex;
    return FormModel(
      issue: issue ?? this.issue,
      congregationId: congregationId ?? this.congregationId,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      auxRoom: auxRoom ?? this.auxRoom,
      weekIndex: idx,
      chairmanByWeek: chairman == null
          ? chairmanByWeek
          : {...chairmanByWeek, idx: chairman},
      mainByWeek: main == null ? mainByWeek : {...mainByWeek, idx: main},
      auxByWeek:
          auxiliary == null ? auxByWeek : {...auxByWeek, idx: auxiliary},
    );
  }
}

final formProvider =
    NotifierProvider<FormController, FormModel>(FormController.new);

class FormController extends Notifier<FormModel> {
  @override
  FormModel build() =>
      FormModel.initial.copyWith(issue: issueForDate(DateTime.now()));

  void setIssue(String v) => state = state.copyWith(issue: v);
  void setCongregation(String v) => state = state.copyWith(congregationId: v);
  void setStartTime(String v) => state = state.copyWith(startTime: v);
  void setDuration(int v) => state = state.copyWith(duration: v);
  void setChairman(String v) => state = state.copyWith(chairman: v);
  void setAuxRoom(bool v) => state = state.copyWith(auxRoom: v);

  /// Switches week while preserving each week's assignments.
  void selectWeek(int idx) => state = state.copyWith(weekIndex: idx);

  void setMainNames(String rowId, List<String> names) {
    state = state.copyWith(main: {...state.main, rowId: names});
  }

  void setAuxNames(String rowId, List<String> names) {
    state = state.copyWith(auxiliary: {...state.auxiliary, rowId: names});
  }
}

/// Selected week (or null if the notebook hasn't been downloaded yet).
final currentWeekProvider = Provider<Week?>((ref) {
  final weeks = ref.watch(weeksProvider).asData?.value;
  if (weeks == null || weeks.isEmpty) return null;
  final idx = ref.watch(formProvider.select((f) => f.weekIndex));
  return weeks[idx.clamp(0, weeks.length - 1)];
});

/// Schedule computed for the selected week (recomputed only when the week,
/// start time or duration change).
final scheduleProvider = Provider<ProgramSchedule?>((ref) {
  final weeks = ref.watch(weeksProvider).asData?.value;
  if (weeks == null || weeks.isEmpty) return null;
  final sel = ref.watch(
      formProvider.select((f) => (f.weekIndex, f.startMinutes, f.duration)));
  final week = weeks[sel.$1.clamp(0, weeks.length - 1)];
  return buildSchedule(week, sel.$2, sel.$3);
});

/// Names as the PDF consumes them (derived from the form).
final assignmentsProvider = Provider<Assignments>((ref) {
  final maps = ref.watch(formProvider.select((f) => (f.main, f.auxiliary)));
  return Assignments(maps.$1, maps.$2);
});
