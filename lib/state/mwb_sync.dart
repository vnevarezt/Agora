import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mwb_cache.dart';
import '../data/mwb_repository.dart';
import '../domain/meeting_language.dart';
import '../domain/mwb_calendar.dart';
import '../models/notebook.dart';
import 'dashboard_provider.dart';
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
    List<String> weeks;
    try {
      final parsed = await repository.weeks(e.issue, lang: e.lang);
      weeks = [for (final w in parsed) w.date];
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
    ref
        .read(notebooksByLangProvider.notifier)
        .setFrom(await buildCatalog(cache, repository));
    return SyncReport.merge(reports);
  }
}

final mwbSyncProvider =
    AsyncNotifierProvider<MwbSyncController, SyncReport>(MwbSyncController.new);
