import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mwb_calendar.dart';
import '../domain/schedule_rules.dart';
import '../models/hall.dart';
import '../models/program_row.dart';
import '../models/week.dart';
import '../models/week_type.dart';
import 'program_content.dart';
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

  /// Per-week "circuit overseer visit" flag: replaces the Congregation Bible
  /// Study with the overseer's talk.
  final Map<int, bool> circuitOverseerByWeek;

  /// Per-week title overrides, keyed by `ProgramRow.id`. Lets the user rename
  /// any assignment's title (e.g. the overseer's talk, unknown in advance).
  final Map<int, Map<String, String>> titleOverridesByWeek;

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
    this.circuitOverseerByWeek = const {},
    this.titleOverridesByWeek = const {},
  });

  // congregationId is the printed congregation NAME; it starts empty and is
  // seeded from the opened project (dashboard) — no more hardcoded hall.
  static const initial = FormModel(
    issue: '202605',
    congregationId: '',
    startTime: '18:00',
    duration: 105,
    auxRoom: false,
    weekIndex: 0,
  );

  // Active week's assignments (stable contract for the rest of the app).
  String get chairman => chairmanByWeek[weekIndex] ?? '';
  Map<String, List<String>> get main => mainByWeek[weekIndex] ?? const {};
  Map<String, List<String>> get auxiliary => auxByWeek[weekIndex] ?? const {};
  bool get circuitOverseer => circuitOverseerByWeek[weekIndex] ?? false;
  Map<String, String> get titleOverrides =>
      titleOverridesByWeek[weekIndex] ?? const {};

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
    Map<int, bool>? circuitOverseerByWeek,
    Map<String, String>? titleOverrides,
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
      circuitOverseerByWeek:
          circuitOverseerByWeek ?? this.circuitOverseerByWeek,
      titleOverridesByWeek: titleOverrides == null
          ? titleOverridesByWeek
          : {...titleOverridesByWeek, idx: titleOverrides},
    );
  }
}

final formProvider =
    NotifierProvider<FormController, FormModel>(FormController.new);

class FormController extends Notifier<FormModel> {
  /// DB identity behind the form (phase 2 write-through). Empty when the
  /// editor has no open project (legacy/standalone form: state-only).
  String? _projectId;
  List<String> _programIds = const [];

  @override
  FormModel build() =>
      FormModel.initial.copyWith(issue: issueForDate(DateTime.now()));

  /// Replaces the whole form with the DB-hydrated [model] and arms the
  /// write-through ([programIds] is index-aligned with the weeks).
  void hydrate(FormModel model,
      {required String projectId, required List<String> programIds}) {
    _projectId = projectId;
    _programIds = programIds;
    state = model;
  }

  String? _programId(int week) =>
      (week >= 0 && week < _programIds.length) ? _programIds[week] : null;

  /// Fire-and-forget DB write: the form (already updated) stays the editing
  /// truth; the row write is what survives the restart.
  void _write(Future<void> Function(String programId) op, {int? week}) {
    final id = _programId(week ?? state.weekIndex);
    if (id != null) unawaited(op(id));
  }

  void setIssue(String v) => state = state.copyWith(issue: v);
  void setCongregation(String v) => state = state.copyWith(congregationId: v);

  void setStartTime(String v) {
    state = state.copyWith(startTime: v);
    _writeProjectConfig(startTime: v);
  }

  void setDuration(int v) {
    state = state.copyWith(duration: v);
    _writeProjectConfig(durationMinutes: v);
  }

  void setAuxRoom(bool v) {
    state = state.copyWith(auxRoom: v);
    _writeProjectConfig(auxRoom: v);
  }

  void _writeProjectConfig(
      {String? startTime, int? durationMinutes, bool? auxRoom}) {
    final projectId = _projectId;
    if (projectId == null) return;
    unawaited(ref.read(programsRepositoryProvider).setProjectConfig(
          projectId,
          startTime: startTime,
          durationMinutes: durationMinutes,
          auxRoom: auxRoom,
        ));
  }

  void setChairman(String v) {
    state = state.copyWith(chairman: v);
    _write((id) => ref.read(programsRepositoryProvider).saveSlotNames(
        programId: id, slotKey: 'chairman', hall: Hall.main, names: [v]));
  }

  /// Marks (or clears) the circuit overseer visit for the given [week] index.
  void setCircuitOverseer(int week, bool v) {
    state = state.copyWith(
      circuitOverseerByWeek: {...state.circuitOverseerByWeek, week: v},
    );
    _write(week: week,
        (id) => ref.read(programsRepositoryProvider).setWeekType(
            id, v ? WeekType.circuitOverseerVisit : WeekType.normal));
  }

  /// Sets or clears the title override for [rowId] in the active week. An empty
  /// or null title removes the override (back to the default title).
  void setTitleOverride(String rowId, String? title) {
    final next = {...state.titleOverrides};
    if (title == null || title.trim().isEmpty) {
      next.remove(rowId);
    } else {
      next[rowId] = title.trim();
    }
    state = state.copyWith(titleOverrides: next);
    _write((id) =>
        ref.read(programsRepositoryProvider).setTitleOverrides(id, next));
  }

  /// Switches week while preserving each week's assignments.
  void selectWeek(int idx) => state = state.copyWith(weekIndex: idx);

  void setMainNames(String rowId, List<String> names) {
    state = state.copyWith(main: {...state.main, rowId: names});
    _write((id) => ref.read(programsRepositoryProvider).saveSlotNames(
        programId: id, slotKey: rowId, hall: Hall.main, names: names));
  }

  void setAuxNames(String rowId, List<String> names) {
    state = state.copyWith(auxiliary: {...state.auxiliary, rowId: names});
    _write((id) => ref.read(programsRepositoryProvider).saveSlotNames(
        programId: id, slotKey: rowId, hall: Hall.aux, names: names));
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
  final sel = ref.watch(formProvider.select((f) =>
      (f.weekIndex, f.startMinutes, f.duration, f.circuitOverseer)));
  final overrides = ref.watch(formProvider.select((f) => f.titleOverrides));
  final week = weeks[sel.$1.clamp(0, weeks.length - 1)];
  final schedule =
      buildSchedule(week, sel.$2, sel.$3, circuitOverseer: sel.$4);
  return applyTitleOverrides(schedule, overrides);
});

/// Names as the PDF consumes them (derived from the form).
final assignmentsProvider = Provider<Assignments>((ref) {
  final maps = ref.watch(formProvider.select((f) => (f.main, f.auxiliary)));
  return Assignments(maps.$1, maps.$2);
});
