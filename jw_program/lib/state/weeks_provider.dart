import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mwb_repository.dart';
import '../models/week.dart';

/// Repositorio de datos (descarga + parseo de jw.org).
final repositoryProvider = Provider((ref) => const MwbRepository());

/// Semanas del cuaderno actual. Vacío hasta que se llama [WeeksController.cargar].
final weeksProvider =
    AsyncNotifierProvider<WeeksController, List<Week>>(WeeksController.new);

class WeeksController extends AsyncNotifier<List<Week>> {
  @override
  Future<List<Week>> build() async => const [];

  /// Descarga y parsea el cuaderno [issue] (YYYYMM).
  Future<void> cargar(String issue) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(repositoryProvider).semanas(issue),
    );
  }
}
