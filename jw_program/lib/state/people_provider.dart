import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'program_form.dart';

/// Directorio de personas en memoria (solo esta sesión). La persistencia y
/// la gestión de personas llegarán en una fase posterior; por ahora alimenta
/// el picker con los nombres ya usados.
class PeopleState {
  final List<String> nombres;
  final List<String> recientes; // más reciente primero, máx. 6

  const PeopleState({required this.nombres, required this.recientes});

  PeopleState copyWith({List<String>? nombres, List<String>? recientes}) {
    return PeopleState(
      nombres: nombres ?? this.nombres,
      recientes: recientes ?? this.recientes,
    );
  }
}

final peopleProvider =
    NotifierProvider<PeopleController, PeopleState>(PeopleController.new);

class PeopleController extends Notifier<PeopleState> {
  @override
  PeopleState build() {
    // Siembra única con los nombres ya escritos en el formulario.
    final f = ref.read(formProvider);
    final nombres = <String>[];
    void agregar(String n) {
      final limpio = n.trim();
      if (limpio.isEmpty) return;
      if (nombres.any((e) => e.toLowerCase() == limpio.toLowerCase())) return;
      nombres.add(limpio);
    }

    agregar(f.presidente);
    for (final lista in [...f.principal.values, ...f.auxiliar.values]) {
      lista.forEach(agregar);
    }
    return PeopleState(nombres: nombres, recientes: const []);
  }

  /// Registra que [nombre] fue asignado: lo agrega al directorio si es nuevo
  /// (dedupe sin distinguir mayúsculas) y lo sube al frente de recientes.
  void registrarUso(String nombre) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return;
    final existente = state.nombres.firstWhere(
      (e) => e.toLowerCase() == limpio.toLowerCase(),
      orElse: () => limpio,
    );
    state = state.copyWith(
      nombres: state.nombres.contains(existente)
          ? state.nombres
          : [...state.nombres, existente],
      recientes: [
        existente,
        ...state.recientes.where((e) => e != existente),
      ].take(6).toList(),
    );
  }
}
