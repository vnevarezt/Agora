import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mwb_cache.dart';
import '../data/mwb_repository.dart';
import '../models/week.dart';
import 'dashboard_provider.dart';
import 'editor_session.dart';

/// On-disk notebook cache (shared by the repository and the background sync).
final cacheProvider = Provider<MwbCache>((ref) => MwbCache());

/// Data repository (cache-first; downloads from jw.org only on a miss).
final repositoryProvider =
    Provider((ref) => MwbRepository(ref.watch(cacheProvider)));

/// Weeks the editor is working on, derived from the open project's program
/// snapshots. Reactive to the background fill, so the editor completes itself
/// once the notebook lands — no button needed.
final weeksProvider =
    AsyncNotifierProvider<WeeksController, List<Week>>(WeeksController.new);

class WeeksController extends AsyncNotifier<List<Week>> {
  @override
  Future<List<Week>> build() async {
    // The weeks come from the programs' content snapshots, reactive to
    // background fills. A program whose snapshot is still missing renders as
    // an empty week (same date) until it lands.
    //
    // There is no notebook-parsing branch here any more. It only ran with no
    // project open, which the app cannot reach — every ProgramShell is built
    // with one — and it read the Spanish EPUB unconditionally, so the one way
    // to reach it would have shown an English congregation a Spanish program.
    ref.watch(editorContentFillProvider);
    final programs = ref.watch(editorProgramsProvider).asData?.value;
    if (programs == null) return const [];
    return [
      for (final p in programs)
        p.contentJson == null
            ? Week(date: p.date)
            : Week.fromJson(jsonDecode(p.contentJson!) as Map<String, dynamic>),
    ];
  }

  /// Manually downloads and parses the notebook [issue] (YYYYMM), in the
  /// meeting language of the open project's congregation. Used by the
  /// workspace's fallback button; goes to the network only on a cache miss.
  Future<void> load(String issue) async {
    final lang = ref.read(
        congregationLangProvider(ref.read(editorCongregationIdProvider)));
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(repositoryProvider).weeks(issue, lang: lang),
    );
  }
}
