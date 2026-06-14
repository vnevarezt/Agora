import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mwb_cache.dart';
import '../data/mwb_repository.dart';
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
  /// off). False means a needed cuaderno couldn't be fetched yet (e.g. the next
  /// one isn't published).
  bool get complete => failed.isEmpty && skippedBackoff.isEmpty;
}

/// Core sync algorithm (no Riverpod, so it is unit-testable):
/// 1. Compute the issues needed to cover [monthsAhead] months from [now].
/// 2. For each, skip if already cached or within back-off (no network);
///    otherwise download + cache it. A failure (e.g. a future issue not yet
///    published) is recorded for back-off, not rethrown.
/// 3. Rebuild the notebook catalog from the cache and hand it to [onCatalog].
///
/// When everything needed is already cached, **no network request is made**.
Future<SyncReport> runMwbSync({
  required MwbCache cache,
  required MwbRepository repository,
  required void Function(List<Notebook>) onCatalog,
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

  onCatalog(await _buildCatalog(cache, repository, lang));

  return SyncReport(
    downloaded: downloaded,
    skippedCached: skippedCached,
    skippedBackoff: skippedBackoff,
    failed: failed,
  );
}

/// Builds one [Notebook] per cached issue. A parse failure for an issue is
/// tolerated (the notebook is listed with no weeks) so it never breaks the sync.
Future<List<Notebook>> _buildCatalog(
    MwbCache cache, MwbRepository repository, String lang) async {
  final manifest = await cache.readManifest();
  final notebooks = <Notebook>[];
  for (final e in manifest.entries.where((e) => e.lang == lang)) {
    try {
      final weeks = await repository.weeks(e.issue, lang: lang);
      notebooks.add(Notebook(
        id: e.issue,
        label: labelForIssue(e.issue),
        weeks: [for (final w in weeks) w.date],
      ));
    } catch (_) {
      notebooks.add(Notebook(
        id: e.issue,
        label: labelForIssue(e.issue),
        weeks: const [],
      ));
    }
  }
  return notebooks;
}

/// Runs [runMwbSync] once on first watch (app startup), in the background. The
/// dashboard reads the resulting [SyncReport] (loading / complete / incomplete)
/// to show a persistent catalog-status card.
class MwbSyncController extends AsyncNotifier<SyncReport> {
  @override
  Future<SyncReport> build() => runMwbSync(
        cache: ref.read(cacheProvider),
        repository: ref.read(repositoryProvider),
        onCatalog: (ns) => ref.read(notebooksProvider.notifier).setFrom(ns),
      );
}

final mwbSyncProvider =
    AsyncNotifierProvider<MwbSyncController, SyncReport>(MwbSyncController.new);
