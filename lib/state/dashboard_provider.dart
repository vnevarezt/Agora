import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repos/congregations_repository.dart';
import '../data/repos/projects_repository.dart';
import '../domain/meeting_language.dart';
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
import 'cloud_auth.dart';
import 'db_provider.dart';

/// Dashboard state. Congregations and projects are DB-backed (milestone 3
/// of the phase-1 plan); everything here lives below AuthGate. The sync
/// `List` providers keep the pre-persistence contract so the UI reads them
/// directly (same policy as [notebooksProvider] / `peopleProvider`).

/// Session user (greeting and sidebar card). Local mode: the profile name.
/// Cloud mode: the Firebase identity (display name, or the email's local
/// part). Widgets derive the subtitle from [mode]/[email] via `context.t`
/// so it follows locale switches.
final sessionUserProvider =
    Provider<({String name, String email, AccountMode? mode})>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session is! SessionUnlocked) return (name: '', email: '', mode: null);
  if (session.mode == AccountMode.local) {
    return (
      name: session.profileName ?? '',
      email: '',
      mode: AccountMode.local,
    );
  }
  final user = ref.watch(cloudUserProvider).value;
  final email = user?.email ?? '';
  final display = user?.displayName?.trim() ?? '';
  final name = display.isNotEmpty
      ? display
      : (email.contains('@') ? email.split('@').first : email);
  return (name: name, email: email, mode: AccountMode.cloud);
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

/// True until the dashboard streams emit their first value — the window
/// where "empty" would lie. Drives the skeleton UI.
final dashboardLoadingProvider = Provider<bool>((ref) =>
    ref.watch(congregationsStreamProvider).isLoading ||
    ref.watch(projectsStreamProvider).isLoading);

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

/// Catalog of cached notebooks, **keyed by workbook language** (the jw.org
/// `langwritten` code — see `domain/meeting_language.dart`). Starts empty and
/// is filled by the background sync ([mwbSyncProvider]) from the on-disk cache.
/// Kept synchronous so the project modal keeps reading it directly.
///
/// Per-language because the meeting language is a per-CONGREGATION setting: a
/// user with one Spanish and one English congregation needs both catalogs at
/// once, and each project must offer the weeks of its own congregation's
/// workbook.
class NotebooksController extends Notifier<Map<String, List<Notebook>>> {
  @override
  Map<String, List<Notebook>> build() => const {};

  void setFrom(Map<String, List<Notebook>> byLang) => state = byLang;
}

final notebooksByLangProvider =
    NotifierProvider<NotebooksController, Map<String, List<Notebook>>>(
        NotebooksController.new);

/// The catalog for one workbook language ('S', 'E', …).
final notebooksForLangProvider = Provider.family<List<Notebook>, String>(
    (ref, lang) => ref.watch(notebooksByLangProvider)[lang] ?? const []);

/// Workbook language a congregation's programs are built from. Falls back to
/// Spanish for an unknown id, which is also the schema default.
final congregationLangProvider = Provider.family<String, String>((ref, id) {
  for (final c in ref.watch(congregationsProvider)) {
    if (c.id == id) return workbookLangFor(c.settings.meetingLanguage);
  }
  return workbookLangFor('spanish');
});

/// The catalog a given congregation should offer.
final notebooksForCongregationProvider =
    Provider.family<List<Notebook>, String>((ref, congregationId) =>
        ref.watch(notebooksForLangProvider(ref.watch(congregationLangProvider(congregationId)))));

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
  final slotTotals = ref.watch(_slotTotalsProvider);
  final cards = [
    for (final d in data)
      _toCard(d, counts, settingsById[d.project.congregationId], slotTotals)
  ];
  slotTotals.retainAll({
    for (final d in data)
      for (final p in d.programs) p.id,
  });
  return cards;
});

/// Slot totals per program, kept across rebuilds of [projectsProvider].
///
/// That provider re-runs on every assignment saved anywhere — including from
/// the editor, with the dashboard off screen — and deriving the totals costs a
/// jsonDecode plus a buildSchedule per program of every project (0.6 ms for 90
/// programs on a desktop Mac, several times that on a phone). The totals only
/// change when a program's snapshot or week type does, which is rare.
final _slotTotalsProvider = Provider<_SlotTotals>((ref) => _SlotTotals());

typedef _ProgramSlots = ({int base, int aux});

class _SlotTotals {
  final _cache = <String, ({String? content, WeekType type, _ProgramSlots slots})>{};

  _ProgramSlots of(ProgramRecord program) {
    final hit = _cache[program.id];
    if (hit != null &&
        hit.content == program.contentJson &&
        hit.type == program.weekType) {
      return hit.slots;
    }
    final slots = _compute(program);
    _cache[program.id] = (
      content: program.contentJson,
      type: program.weekType,
      slots: slots,
    );
    return slots;
  }

  void retainAll(Set<String> programIds) =>
      _cache.removeWhere((id, _) => !programIds.contains(id));

  static _ProgramSlots _compute(ProgramRecord program) {
    if (program.contentJson == null) {
      return (base: _partsPerWeek, aux: 0);
    }
    final week =
        Week.fromJson(jsonDecode(program.contentJson!) as Map<String, dynamic>);
    final schedule = buildSchedule(week, 18 * 60, 105,
        circuitOverseer: program.weekType == WeekType.circuitOverseerVisit);
    var base = 1; // chairman
    var aux = 0;
    for (final row in schedule.rows) {
      base += row.slots;
      aux += row.auxSlots;
    }
    return (base: base, aux: aux);
  }
}

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
  _SlotTotals slotTotals,
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

    final slots = slotTotals.of(program);
    final programTotal = slots.base + (auxRoom ? slots.aux : 0);
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
