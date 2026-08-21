import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mwb_cache.dart';
import '../data/mwb_repository.dart';
import '../data/repos/programs_repository.dart';
import '../domain/meeting_language.dart';
import '../domain/mwb_calendar.dart';
import '../models/notebook.dart';
import 'dashboard_provider.dart';
import 'program_reconciler.dart';
import 'weeks_provider.dart';

/// Outcome of one sync cycle (for the UI/diagnostics).
class SyncReport {
  final List<String> downloaded;
  final List<String> skippedCached;
  final List<String> skippedBackoff;
  final Map<String, String> failed;

  const SyncReport({
    this.downloaded = const [],
    this.skippedCached = const [],
    this.skippedBackoff = const [],
    this.failed = const {},
  });

  /// True when every needed issue ended up cached (nothing failed or backed
  /// off). False means a needed notebook couldn't be fetched yet (e.g. the next
  /// one isn't published).
  bool get complete => failed.isEmpty && skippedBackoff.isEmpty;

  /// Folds the per-language passes into one status for the dashboard card.
  /// Issue ids repeat across languages, which is fine — nothing keys off them
  /// beyond [complete] and the counts.
  static SyncReport merge(Iterable<SyncReport> reports) => SyncReport(
        downloaded: [for (final r in reports) ...r.downloaded],
        skippedCached: [for (final r in reports) ...r.skippedCached],
        skippedBackoff: [for (final r in reports) ...r.skippedBackoff],
        failed: {for (final r in reports) ...r.failed},
      );
}

/// Core sync algorithm (no Riverpod, so it is unit-testable):
/// 1. Compute the issues needed to cover [monthsAhead] months from [now].
/// 2. For each, skip if already cached or within back-off (no network);
///    otherwise download + cache it. A failure (e.g. a future issue not yet
///    published) is recorded for back-off, not rethrown.
///
/// Fetching only — the catalog is [buildCatalog]'s job, because it spans every
/// cached language while a pass covers exactly one.
///
/// When everything needed is already cached, **no network request is made**.
Future<SyncReport> runMwbSync({
  required MwbCache cache,
  required MwbRepository repository,
  DateTime? now,
  int monthsAhead = 2,
  String lang = 'S',
}) async {
  final at = now ?? DateTime.now();
  final needed = requiredIssues(at, monthsAhead: monthsAhead);
  final manifest = await cache.readManifest();

  final downloaded = <String>[];
  final skippedCached = <String>[];
  final skippedBackoff = <String>[];
  final failed = <String, String>{};

  for (final issue in needed) {
    if (cache.has(manifest, issue, lang)) {
      skippedCached.add(issue);
      continue;
    }
    if (cache.inBackoff(manifest, issue, lang, now: at)) {
      skippedBackoff.add(issue);
      continue;
    }
    try {
      await repository.ensureCached(issue, lang: lang);
      downloaded.add(issue);
    } catch (e) {
      await cache.recordFailure(issue, lang, '$e', at: at);
      failed[issue] = '$e';
    }
  }

  return SyncReport(
    downloaded: downloaded,
    skippedCached: skippedCached,
    skippedBackoff: skippedBackoff,
    failed: failed,
  );
}

/// One [Notebook] per cached issue, keyed by workbook language.
///
/// Reads the WHOLE manifest, not just the languages the caller happens to have
/// fetched: a congregation switching from Spanish to English must not make the
/// Spanish catalog vanish. Those EPUBs are still on disk and the projects built
/// from them still need their weeks.
///
/// A parse failure for an issue is tolerated (the notebook is listed with no
/// weeks) so one bad file never empties the catalog.
Future<Map<String, List<Notebook>>> buildCatalog(
    MwbCache cache, MwbRepository repository) async {
  final manifest = await cache.readManifest();
  final byLang = <String, List<Notebook>>{};
  for (final e in manifest.entries) {
    List<WeekRef> weeks;
    try {
      final parsed = await repository.weeks(e.issue, lang: e.lang);
      weeks = [for (final w in parsed) (start: w.weekStart, label: w.date)];
    } catch (_) {
      weeks = const [];
    }
    (byLang[e.lang] ??= []).add(Notebook(id: e.issue, weeks: weeks));
  }
  // Manifest order is write order (a re-download moves an issue to the end), so
  // sort: the project modal picks `notebooks.first` as its fallback tab.
  for (final notebooks in byLang.values) {
    notebooks.sort((a, b) => a.id.compareTo(b.id));
  }
  return byLang;
}

/// Drops the workbooks nothing needs any more: neither inside the coverage
/// window nor referenced by an alive program. Returns how many were removed.
///
/// Nothing evicted these before, so a long-running install accumulated every
/// issue it had ever seen — several megabytes each — and the project modal
/// grew a tab for each of them.
///
/// Skipped entirely while any alive program is still unidentified. Such a
/// program is matched by its printed heading against whatever workbook happens
/// to list it, so there is no way to know which one it needs; the reconciler
/// clears that state, and the next pass purges.
Future<int> purgeUnneededIssues({
  required MwbCache cache,
  required ProgramsRepository programs,
  DateTime? now,
  int monthsAhead = 2,
}) async {
  final alive = await programs.aliveWeekStarts();
  if (alive.anyUnidentified) return 0;
  final keep = {
    ...requiredIssues(now ?? DateTime.now(), monthsAhead: monthsAhead),
    for (final weekStart in alive.weekStarts) ...issuesForWeekStart(weekStart),
  };
  return (await cache.retainIssues(keep)).length;
}

/// Workbook languages the sync has to cover, as a canonical `'E,S'` string.
/// `null` while the congregation stream has not landed, `''` when there are no
/// congregations to serve.
///
/// A String rather than the `Set` [workbookLangsFor] returns, because Riverpod
/// compares with `==` and collections compare by identity: handing back a Set
/// re-ran the whole sync on every congregation write — including the settings
/// tab's 400 ms debounce, so roughly once per keystroke in the name field —
/// which relaunched every pass and blinked the dashboard's catalog indicator.
final requiredWorkbookLangsProvider = Provider<String?>((ref) {
  final congregations = ref.watch(congregationsStreamProvider);
  if (!congregations.hasValue) return null;
  final langs = workbookLangsFor(
    congregations.requireValue.map((c) => c.settings.meetingLanguage),
  );
  return (langs.toList()..sort()).join(',');
});

/// Runs [runMwbSync] once on first watch (app startup), in the background. The
/// dashboard reads the resulting [SyncReport] (loading / complete / incomplete)
/// to show a persistent catalog-status card.
class MwbSyncController extends AsyncNotifier<SyncReport> {
  @override
  Future<SyncReport> build() async {
    // One pass per workbook language actually in use. Watching the languages
    // (not the congregations) means adding one that meets in another language
    // pulls its workbook down without a restart, while renaming one does
    // nothing at all.
    final langs = ref.watch(requiredWorkbookLangsProvider);
    if (langs == null) {
      // The congregation stream has not landed, so there is nothing to guess
      // from — and guessing Spanish here cost an English-only user a
      // multi-megabyte download of a workbook they never meet in, kept
      // forever. Await it so the dashboard holds its "syncing" state instead
      // of flashing "up to date" before anything was checked; its arrival
      // re-runs this build with a real answer.
      await ref.watch(congregationsStreamProvider.future);
      return const SyncReport();
    }
    // No congregations yet: ensureDefault() creates one on the first real
    // write, so this resolves itself shortly.
    if (langs.isEmpty) return const SyncReport();
    final targets = langs.split(',');

    final cache = ref.read(cacheProvider);
    final repository = ref.read(repositoryProvider);
    final reports = <SyncReport>[];
    for (final lang in targets) {
      reports.add(await runMwbSync(
        cache: cache,
        repository: repository,
        lang: lang,
      ));
    }
    // Before publishing, not after: the catalog must describe what survived.
    await purgeUnneededIssues(
      cache: cache,
      programs: ref.read(programsRepositoryProvider),
    );
    ref
        .read(notebooksByLangProvider.notifier)
        .setFrom(await buildCatalog(cache, repository));
    return SyncReport.merge(reports);
  }
}

final mwbSyncProvider =
    AsyncNotifierProvider<MwbSyncController, SyncReport>(MwbSyncController.new);

/// Whether the workbook a congregation needs is on hand.
enum WorkbookStatus {
  /// The catalog holds notebooks in that meeting language.
  ready,

  /// Nothing yet, but a pass is running — the usual state for the seconds
  /// right after a language is switched.
  downloading,

  /// Nothing, and no pass is running: offline, or the issue is not published.
  unavailable,
}

/// Reads off the catalog rather than off the sync report, because the catalog
/// is the thing the rest of the app actually uses. Whatever the last pass
/// reported, a congregation whose language has notebooks can work.
final congregationWorkbookStatusProvider =
    Provider.family<WorkbookStatus, String>((ref, congregationId) {
  final lang = ref.watch(congregationLangProvider(congregationId));
  if (ref.watch(notebooksForLangProvider(lang)).isNotEmpty) {
    return WorkbookStatus.ready;
  }
  return ref.watch(mwbSyncProvider).isLoading
      ? WorkbookStatus.downloading
      : WorkbookStatus.unavailable;
});

/// Pulls the coverage window down again even though it is cached, then pushes
/// the result through to the programs.
///
/// The one thing the cache cannot decide for itself: jw.org republishes
/// corrected workbooks, and a cached issue is never fetched twice, so without
/// this a correction would never arrive. Manual rather than automatic — there
/// is no cheap way to know a workbook changed short of downloading it.
final catalogRefreshProvider =
    Provider<CatalogRefresher>(CatalogRefresher.new);

class CatalogRefresher {
  CatalogRefresher(this._ref);

  final Ref _ref;

  /// Returns how many issues were replaced. A language that fails is skipped,
  /// not fatal: what is on disk stays, so a partial refresh never costs the
  /// user a workbook they already had.
  Future<int> run({DateTime? now, int monthsAhead = 2}) async {
    final langs = _ref.read(requiredWorkbookLangsProvider) ?? '';
    if (langs.isEmpty) return 0;
    final cache = _ref.read(cacheProvider);
    final repository = _ref.read(repositoryProvider);

    var replaced = 0;
    for (final lang in langs.split(',')) {
      for (final issue
          in requiredIssues(now ?? DateTime.now(), monthsAhead: monthsAhead)) {
        try {
          await repository.refresh(issue, lang);
          replaced++;
        } catch (_) {
          // Offline, or the issue is not published yet. Both are fine.
        }
      }
    }
    if (replaced == 0) return 0;

    _ref
        .read(notebooksByLangProvider.notifier)
        .setFrom(await buildCatalog(cache, repository));

    // A corrected workbook has to reach the snapshots too, and those are
    // already in the right language — so this pass has to be forced.
    final reconciler = _ref.read(programReconcilerProvider);
    for (final congregation in _ref.read(congregationsProvider)) {
      await reconciler.reconcileCongregation(congregation.id, force: true);
    }
    return replaced;
  }
}
