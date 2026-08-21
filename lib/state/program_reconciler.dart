import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repos/programs_repository.dart';
import '../domain/meeting_language.dart';
import '../models/congregation.dart';
import '../models/congregation_settings.dart';
import 'dashboard_provider.dart';
import 'db_provider.dart';
import 'weeks_provider.dart';

final programsRepositoryProvider = Provider<ProgramsRepository>((ref) =>
    ProgramsRepository(ref.watch(dbProvider), ref.watch(syncScribeProvider)));

final programReconcilerProvider =
    Provider<ProgramReconciler>(ProgramReconciler.new);

/// What one reconciliation pass did, for the UI and for tests.
class ReconcileReport {
  /// Programs whose snapshot was written or rewritten.
  final int filled;

  /// Programs left as they were because the workbook they need is not cached.
  /// They keep whatever content they already had and are retried later.
  final int pending;

  const ReconcileReport({this.filled = 0, this.pending = 0});

  bool get complete => pending == 0;

  ReconcileReport operator +(ReconcileReport other) => ReconcileReport(
        filled: filled + other.filled,
        pending: pending + other.pending,
      );
}

/// Keeps every program's content in step with its congregation's meeting
/// language, and repairs the rows that predate that idea.
///
/// One pass over a project's programs does three things, in order:
///
///  1. **Identity.** A program written before v6 is keyed by its printed week
///     heading, which is language-dependent. Matching that label against the
///     cached workbooks of EVERY language yields the week's real date, which
///     is then stored. This is the data migration, and running it here rather
///     than in SQL is what lets it use the workbook cache — which a drift
///     migration cannot reach.
///  2. **Language.** A snapshot whose `contentLang` is not the one the
///     congregation now meets in is re-resolved from the right workbook and
///     rewritten. Assignments are untouched: they hang off `ProgramRow.id`,
///     which is positional (`te0`, `se1`, …) and not derived from any title,
///     so the names the user typed survive the change of language.
///  3. **Patience.** If the workbook needed is not on disk, the program keeps
///     the content it already has and is counted pending. Good content is
///     never traded for none — an offline user must not watch their program
///     empty itself.
class ProgramReconciler {
  ProgramReconciler(this._ref);

  final Ref _ref;

  /// Reconciles one project. Idempotent: a project already in step writes
  /// nothing, unless [force] is set — which is how a refreshed workbook
  /// reaches snapshots that are already in the right language.
  Future<ReconcileReport> reconcileProject(String projectId,
      {bool force = false}) async {
    final repo = _ref.read(programsRepositoryProvider);
    final programs = await repo.byProject(projectId);
    if (programs.isEmpty) return const ReconcileReport();

    // Resolved with direct lookups rather than the stream-backed providers:
    // this runs fire-and-forget in the background, and watching from here
    // would leave a drift subscription open behind it.
    final congregationId = await _ref
            .read(projectsRepositoryProvider)
            .congregationIdOf(projectId) ??
        '';
    final settings = await _ref
        .read(congregationsRepositoryProvider)
        .settingsOf(congregationId);
    final lang = workbookLangFor(settings?.meetingLanguage ??
        const CongregationSettings().meetingLanguage);

    var report = const ReconcileReport();
    for (final program in programs) {
      report = report + await _reconcileProgram(program, lang, repo, force);
    }
    return report;
  }

  /// Reconciles every project of one congregation — the pass a change of
  /// meeting language needs, since that setting moves for all of them at once.
  Future<ReconcileReport> reconcileCongregation(String congregationId,
      {bool force = false}) async {
    final projectIds = await _ref
        .read(projectsRepositoryProvider)
        .idsByCongregation(congregationId);
    var report = const ReconcileReport();
    for (final projectId in projectIds) {
      report = report + await reconcileProject(projectId, force: force);
    }
    return report;
  }

  Future<ReconcileReport> _reconcileProgram(
    ProgramRecord program,
    String lang,
    ProgramsRepository repo,
    bool force,
  ) async {
    var weekStart = program.weekStart;

    // (1) Identity, for rows written before it existed.
    if (weekStart == null || weekStart.isEmpty) {
      weekStart = _identityFromLabel(program.date);
      if (weekStart == null) return const ReconcileReport(pending: 1);
    }

    // (2) Already in the right language: nothing to do.
    if (!force && program.contentJson != null && program.contentLang == lang) {
      return const ReconcileReport();
    }

    final week = await _ref.read(repositoryProvider).weekFor(weekStart, lang);
    if (week == null) {
      // (3) The workbook is not cached yet. Record the identity we did manage
      // to resolve — it is language-free, so it stays true — and leave the
      // content alone for the next pass.
      if (program.weekStart != weekStart) {
        await repo.setWeekStart(program.id, weekStart);
      }
      return const ReconcileReport(pending: 1);
    }

    await repo.setContent(program.id, week, lang);
    return const ReconcileReport(filled: 1);
  }

  /// The real date behind a legacy week label, found in whichever cached
  /// workbook happens to list it — in ANY language.
  ///
  /// Searching across languages is what repairs a project whose programs are
  /// already a mix: the label was written in one language and the congregation
  /// may now meet in another, so insisting on the current one would find
  /// nothing and leave the program broken forever.
  String? _identityFromLabel(String label) {
    if (label.isEmpty) return null;
    for (final notebooks in _ref.read(notebooksByLangProvider).values) {
      for (final notebook in notebooks) {
        for (final week in notebook.weeks) {
          if (week.label == label && week.start.isNotEmpty) return week.start;
        }
      }
    }
    return null;
  }
}

/// Rewrites a congregation's programs when its meeting language changes.
///
/// Mounted next to the sync in `_SyncBootstrap`. The two halves of a language
/// switch are deliberately separate: the sync notices the new language and
/// downloads its workbook, this notices it and rewrites the programs. They
/// meet here — a pass that ran before the download finishes reports pending,
/// and the catalog landing retries it.
///
/// Scope is bounded on purpose. Only a congregation whose language actually
/// moved is reconciled, and only one that came back pending is retried; every
/// other project heals when it is next opened.
final congregationLanguageWatcherProvider = Provider<void>((ref) {
  final pending = <String>{};

  Future<void> reconcile(String congregationId) async {
    final report = await ref
        .read(programReconcilerProvider)
        .reconcileCongregation(congregationId);
    if (report.complete) {
      pending.remove(congregationId);
    } else {
      pending.add(congregationId);
    }
  }

  ref.listen<List<Congregation>>(congregationsProvider, (previous, next) {
    if (previous == null || previous.isEmpty) return;
    final before = {
      for (final c in previous) c.id: c.settings.meetingLanguage,
    };
    for (final congregation in next) {
      final was = before[congregation.id];
      if (was != null && was != congregation.settings.meetingLanguage) {
        unawaited(reconcile(congregation.id));
      }
    }
  });

  ref.listen(notebooksByLangProvider, (_, _) {
    for (final congregationId in pending.toList()) {
      unawaited(reconcile(congregationId));
    }
  });
});
