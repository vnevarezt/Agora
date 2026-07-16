import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mwb_cache.dart';
import '../data/mwb_repository.dart';
import '../models/week.dart';
import 'editor_session.dart';
import 'mwb_sync.dart';
import 'program_form.dart';

/// On-disk notebook cache (shared by the repository and the background sync).
final cacheProvider = Provider<MwbCache>((ref) => MwbCache());

/// Data repository (cache-first; downloads from jw.org only on a miss).
final repositoryProvider =
    Provider((ref) => MwbRepository(ref.watch(cacheProvider)));

/// Weeks of the current notebook. Auto-loads the active issue from the cache so
/// the editor fills itself once the sync has downloaded it (no button needed).
final weeksProvider =
    AsyncNotifierProvider<WeeksController, List<Week>>(WeeksController.new);

class WeeksController extends AsyncNotifier<List<Week>> {
  @override
  Future<List<Week>> build() async {
    // Project mode (phase 2): the weeks come from the programs' content
    // snapshots, reactive to background fills. A program whose snapshot is
    // still missing renders as an empty week (same date) until it lands.
    if (ref.watch(editorProjectProvider) != null) {
      final programs = ref.watch(editorProgramsProvider).asData?.value;
      if (programs == null) return const [];
      return [
        for (final p in programs)
          p.contentJson == null
              ? Week(date: p.date)
              : Week.fromJson(
                  jsonDecode(p.contentJson!) as Map<String, dynamic>),
      ];
    }

    // Legacy/standalone mode: parse the active issue from the epub cache.
    // Rebuild when the sync finishes so a freshly downloaded notebook shows up.
    ref.watch(mwbSyncProvider);
    final issue = ref.watch(formProvider.select((f) => f.issue));
    // Only read from disk: never hit the network here (that is the sync's job).
    if (await ref.read(cacheProvider).readEpub(issue, 'S') == null) {
      return const [];
    }
    return ref.read(repositoryProvider).weeks(issue);
  }

  /// Manually downloads and parses the notebook [issue] (YYYYMM). Used by the
  /// fallback button; goes to the network only if the issue is not cached.
  Future<void> load(String issue) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(repositoryProvider).weeks(issue),
    );
  }
}
