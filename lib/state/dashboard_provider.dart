import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/congregations_repository.dart';
import '../data/repos/projects_repository.dart';
import '../domain/schedule_rules.dart';
import '../i18n/strings.g.dart';
import '../models/congregation.dart';
import '../models/congregation_settings.dart';
import '../models/hall.dart';
import '../models/notebook.dart';
import '../models/project.dart';
import '../models/reminder.dart';
import '../models/week.dart';
import '../models/week_type.dart';
import 'auth_session.dart';
import 'db_provider.dart';

/// Dashboard state. Congregations and projects are DB-backed (milestone 3
/// of the phase-1 plan); everything here lives below AuthGate. The sync
/// `List` providers keep the pre-persistence contract so the UI reads them
/// directly (same policy as [notebooksProvider] / `peopleProvider`).

/// Session user (greeting and sidebar card): the local profile name when
/// unlocked in local mode ('' in cloud mode until 4b brings identity).
final sessionUserProvider = Provider<({String name, String role})>((ref) {
  final session = ref.watch(authSessionProvider);
  final name = session is SessionUnlocked ? (session.profileName ?? '') : '';
  return (name: name, role: '');
});

final congregationsRepositoryProvider = Provider<CongregationsRepository>(
    (ref) => CongregationsRepository(
        ref.watch(dbProvider), ref.watch(syncScribeProvider),
        defaultName: t.congregation.defaultName));

final congregationsStreamProvider = StreamProvider<List<Congregation>>(
    (ref) => ref.watch(congregationsRepositoryProvider).watchAll());

/// Synchronous view (empty during the first frame).
final congregationsProvider = Provider<List<Congregation>>(
    (ref) => ref.watch(congregationsStreamProvider).asData?.value ?? const []);

final congregationActionsProvider =
    Provider<CongregationActions>(CongregationActions.new);

class CongregationActions {
  CongregationActions(this._ref);

  final Ref _ref;

  CongregationsRepository get _repo =>
      _ref.read(congregationsRepositoryProvider);

  Future<void> add({
    required String name,
    required String number,
    CongregationSettings settings = const CongregationSettings(),
  }) =>
      _repo.create(name: name, number: number, settings: settings);

  Future<void> update(
    String id, {
    required String name,
    required String number,
    required CongregationSettings settings,
  }) =>
      _repo.update(id, name: name, number: number, settings: settings);
}

/// Catalog of cached notebooks. Starts empty and is filled by the background
/// sync ([mwbSyncProvider]) from the on-disk cache. Kept synchronous so the
/// project modal keeps reading it directly.
class NotebooksController extends Notifier<List<Notebook>> {
  @override
  List<Notebook> build() => const [];

  void setFrom(List<Notebook> notebooks) => state = notebooks;
}

final notebooksProvider =
    NotifierProvider<NotebooksController, List<Notebook>>(
        NotebooksController.new);

/// Pending-work reminders, derived from the drafts: one per week that
/// still has unassigned parts, newest project first, capped at 4.
final remindersProvider = Provider<List<Reminder>>((ref) {
  final drafts = ref
      .watch(projectsProvider)
      .where((p) => p.status == ProjectStatus.draft)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final reminders = <Reminder>[];
  for (final p in drafts) {
    for (final w in p.weekProgress) {
      final missing = w.total - w.done;
      if (missing <= 0) continue;
      reminders.add(Reminder(
        id: '${p.id}/${w.label}',
        type: w.done == 0 ? ReminderType.alert : ReminderType.task,
        title: t.dashboard.pendingItem(n: missing),
        meta: '${w.label} · ${p.name}',
        cta: t.dashboard.openProject,
        projectId: p.id,
      ));
      if (reminders.length >= 4) return reminders;
    }
  }
  return reminders;
});

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) =>
    ProjectsRepository(ref.watch(dbProvider),
        ref.watch(congregationsRepositoryProvider),
        ref.watch(syncScribeProvider)));

final projectsStreamProvider = StreamProvider<List<ProjectData>>(
    (ref) => ref.watch(projectsRepositoryProvider).watchAll());

/// Alive assignment counts per (programId, hall), reactive.
final _assignmentCountsProvider = StreamProvider<Map<(String, Hall), int>>(
    (ref) => ref.watch(projectsRepositoryProvider).watchAssignmentCounts());

/// Synchronous project cards derived from the DB rows: progress/status/
/// edited label are computed, never stored (docs/PHASE1_LOCAL_PERSISTENCE.md).
final projectsProvider = Provider<List<Project>>((ref) {
  final data = ref.watch(projectsStreamProvider).asData?.value ?? const [];
  final counts =
      ref.watch(_assignmentCountsProvider).asData?.value ?? const {};
  final congregations = ref.watch(congregationsProvider);
  final settingsById = {for (final c in congregations) c.id: c.settings};
  return [
    for (final d in data)
      _toCard(d, counts, settingsById[d.project.congregationId])
  ];
});

/// Fallback when a program has no content snapshot yet.
const _partsPerWeek = 14;

/// Real progress (phase 2): slot totals come from each program's content
/// snapshot through the same schedule rules the editor uses (slot counts
/// don't depend on start time/duration); done comes from the alive
/// assignment rows, clamped per program so stale aux rows never overflow.
Project _toCard(
  ProjectData d,
  Map<(String, Hall), int> counts,
  CongregationSettings? congregationSettings,
) {
  final weeks = [for (final p in d.programs) p.date];
  final weekProgress = <WeekProgress>[];
  var done = 0;
  var total = 0;
  for (final program in d.programs) {
    final auxRoom =
        program.auxRoom ?? congregationSettings?.auxRoom ?? false;
    final mainCount = counts[(program.id, Hall.main)] ?? 0;
    final auxCount = auxRoom ? (counts[(program.id, Hall.aux)] ?? 0) : 0;

    int programTotal;
    if (program.contentJson == null) {
      programTotal = _partsPerWeek;
    } else {
      final week = Week.fromJson(
          jsonDecode(program.contentJson!) as Map<String, dynamic>);
      final schedule = buildSchedule(week, 18 * 60, 105,
          circuitOverseer:
              program.weekType == WeekType.circuitOverseerVisit);
      programTotal = 1; // chairman
      for (final row in schedule.rows) {
        programTotal += row.slots;
        if (auxRoom) programTotal += row.auxSlots;
      }
    }
    final programDone = min(mainCount + auxCount, programTotal);
    weekProgress.add(
        (label: program.date, done: programDone, total: programTotal));
    total += programTotal;
    done += programDone;
  }

  final status = d.project.exportedAt != null
      ? ProjectStatus.exported
      : (total > 0 && done >= total)
          ? ProjectStatus.complete
          : ProjectStatus.draft;
  return Project(
    id: d.project.id,
    name: d.project.name,
    congregationId: d.project.congregationId,
    weeks: weeks,
    done: done,
    total: total,
    status: status,
    editedLabel: relativeEditedLabel(d.project.updatedAt),
    updatedAt: d.project.updatedAt,
    weekProgress: weekProgress,
  );
}

/// The hero "continue where you left off" project: the most recently edited
/// draft (null → the dashboard hides the hero card).
final heroProjectProvider = Provider<Project?>((ref) {
  final drafts = ref
      .watch(projectsProvider)
      .where((p) => p.status == ProjectStatus.draft)
      .toList();
  if (drafts.isEmpty) return null;
  drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return drafts.first;
});

/// Open drafts (subtitle count).
final draftCountProvider = Provider<int>((ref) => ref
    .watch(projectsProvider)
    .where((p) => p.status == ProjectStatus.draft)
    .length);

/// Missing assignments across drafts (subtitle count).
final pendingAssignmentsProvider = Provider<int>((ref) {
  var pending = 0;
  for (final p in ref.watch(projectsProvider)) {
    if (p.status == ProjectStatus.draft) pending += p.total - p.done;
  }
  return pending;
});

/// "hace 2 h" label for the project cards, from the row's `updatedAt`.
/// Coarse on purpose: it re-renders with the dashboard, it doesn't tick.
String relativeEditedLabel(DateTime updatedAt, {DateTime? now}) {
  final d = (now ?? DateTime.now().toUtc()).difference(updatedAt);
  if (d.inMinutes < 1) return t.relativeTime.now;
  if (d.inHours < 1) return t.relativeTime.minutes(n: d.inMinutes);
  if (d.inDays < 1) return t.relativeTime.hours(n: d.inHours);
  return t.relativeTime.days(n: d.inDays);
}

final projectActionsProvider = Provider<ProjectActions>(ProjectActions.new);

class ProjectActions {
  ProjectActions(this._ref);

  final Ref _ref;

  ProjectsRepository get _repo => _ref.read(projectsRepositoryProvider);

  /// Returns the new project id (callers chain the content snapshot).
  Future<String> create({
    required String name,
    required String congregationId,
    required List<String> weeks,
  }) =>
      _repo.create(name: name, congregationId: congregationId, weeks: weeks);

  Future<void> update(
    String id, {
    required String name,
    required String congregationId,
    required List<String> weeks,
  }) =>
      _repo.update(id,
          name: name, congregationId: congregationId, weeks: weeks);

  Future<void> delete(String id) => _repo.delete(id);

  Future<void> markExported(String id) => _repo.markExported(id);
}

/// Active filters: congregation (`'all'` = all) and status (`null` = any).
class DashboardFilters {
  /// `'all'` or a congregation id.
  final String congregationId;

  /// `null` = any status.
  final ProjectStatus? status;

  const DashboardFilters({this.congregationId = 'all', this.status});
}

class DashboardFiltersController extends Notifier<DashboardFilters> {
  @override
  DashboardFilters build() => const DashboardFilters();

  void setCongregation(String congregationId) =>
      state = DashboardFilters(congregationId: congregationId, status: state.status);

  void setStatus(ProjectStatus? status) =>
      state = DashboardFilters(congregationId: state.congregationId, status: status);
}

final dashboardFiltersProvider =
    NotifierProvider<DashboardFiltersController, DashboardFilters>(
        DashboardFiltersController.new);

/// Projects visible after applying the active filters.
final filteredProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsProvider);
  final f = ref.watch(dashboardFiltersProvider);
  return projects
      .where((p) =>
          (f.congregationId == 'all' || p.congregationId == f.congregationId) &&
          (f.status == null || p.status == f.status))
      .toList();
});
