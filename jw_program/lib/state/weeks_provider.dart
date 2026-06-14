import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mwb_repository.dart';
import '../models/week.dart';

/// Repositorio de datos (descarga + parseo de jw.org).
final repositoryProvider = Provider((ref) => const MwbRepository());

/// Semanas del notebook actual. Vacío hasta que se llama [WeeksController.load].
final weeksProvider =
    AsyncNotifierProvider<WeeksController, List<Week>>(WeeksController.new);

class WeeksController extends AsyncNotifier<List<Week>> {
  @override
  Future<List<Week>> build() async => const [];

  /// Descarga y parsea el notebook [issue] (YYYYMM).
  Future<void> load(String issue) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(repositoryProvider).weeks(issue),
    );
  }
}
