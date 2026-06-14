import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mwb_repository.dart';
import '../models/week.dart';

/// Data repository (download + parse from jw.org).
final repositoryProvider = Provider((ref) => const MwbRepository());

/// Weeks of the current notebook. Empty until [WeeksController.load] is called.
final weeksProvider =
    AsyncNotifierProvider<WeeksController, List<Week>>(WeeksController.new);

class WeeksController extends AsyncNotifier<List<Week>> {
  @override
  Future<List<Week>> build() async => const [];

  /// Downloads and parses the notebook [issue] (YYYYMM).
  Future<void> load(String issue) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(repositoryProvider).weeks(issue),
    );
  }
}
