import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/schedule_rules.dart';
import '../models/program_row.dart';
import '../models/week.dart';
import 'weeks_provider.dart';

/// Estado editable del formulario (inmutable). Los nombres se guardan por
/// `ProgramRow.id` en [principal] / [auxiliar].
class FormModel {
  final String issue;
  final String cong;
  final String inicio; // "HH:MM"
  final int duracion; // minutos
  final bool aux;
  final int semanaIdx;
  final String presidente;
  final Map<String, List<String>> principal;
  final Map<String, List<String>> auxiliar;

  const FormModel({
    required this.issue,
    required this.cong,
    required this.inicio,
    required this.duracion,
    required this.aux,
    required this.semanaIdx,
    required this.presidente,
    required this.principal,
    required this.auxiliar,
  });

  static const inicial = FormModel(
    issue: '202605',
    cong: 'CONSTITUCIÓN J.A CASTRO',
    inicio: '18:00',
    duracion: 105,
    aux: false,
    semanaIdx: 0,
    presidente: '',
    principal: {},
    auxiliar: {},
  );

  /// Minutos desde medianoche del inicio (fallback 18:00 si el texto no es válido).
  int get inicioMin {
    final p = inicio.split(':');
    if (p.length == 2) {
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h != null && m != null) return h * 60 + m;
    }
    return 18 * 60;
  }

  FormModel copyWith({
    String? issue,
    String? cong,
    String? inicio,
    int? duracion,
    bool? aux,
    int? semanaIdx,
    String? presidente,
    Map<String, List<String>>? principal,
    Map<String, List<String>>? auxiliar,
  }) {
    return FormModel(
      issue: issue ?? this.issue,
      cong: cong ?? this.cong,
      inicio: inicio ?? this.inicio,
      duracion: duracion ?? this.duracion,
      aux: aux ?? this.aux,
      semanaIdx: semanaIdx ?? this.semanaIdx,
      presidente: presidente ?? this.presidente,
      principal: principal ?? this.principal,
      auxiliar: auxiliar ?? this.auxiliar,
    );
  }
}

final formProvider =
    NotifierProvider<FormController, FormModel>(FormController.new);

class FormController extends Notifier<FormModel> {
  @override
  FormModel build() => FormModel.inicial;

  void setIssue(String v) => state = state.copyWith(issue: v);
  void setCong(String v) => state = state.copyWith(cong: v);
  void setInicio(String v) => state = state.copyWith(inicio: v);
  void setDuracion(int v) => state = state.copyWith(duracion: v);
  void setPresidente(String v) => state = state.copyWith(presidente: v);
  void setAux(bool v) => state = state.copyWith(aux: v);

  /// Cambia de semana y limpia los nombres (no aplican a otra semana).
  void seleccionarSemana(int idx) =>
      state = state.copyWith(semanaIdx: idx, principal: {}, auxiliar: {});

  void setNombresPrincipal(String rowId, List<String> nombres) {
    state = state.copyWith(principal: {...state.principal, rowId: nombres});
  }

  void setNombresAux(String rowId, List<String> nombres) {
    state = state.copyWith(auxiliar: {...state.auxiliar, rowId: nombres});
  }
}

/// Semana seleccionada (o null si aún no se ha descargado el cuaderno).
final semanaActualProvider = Provider<Week?>((ref) {
  final weeks = ref.watch(weeksProvider).asData?.value;
  if (weeks == null || weeks.isEmpty) return null;
  final idx = ref.watch(formProvider.select((f) => f.semanaIdx));
  return weeks[idx.clamp(0, weeks.length - 1)];
});

/// Horario calculado de la semana seleccionada (se recalcula solo si cambian
/// semana, inicio o duración).
final scheduleProvider = Provider<ProgramSchedule?>((ref) {
  final weeks = ref.watch(weeksProvider).asData?.value;
  if (weeks == null || weeks.isEmpty) return null;
  final sel =
      ref.watch(formProvider.select((f) => (f.semanaIdx, f.inicioMin, f.duracion)));
  final week = weeks[sel.$1.clamp(0, weeks.length - 1)];
  return construirFilas(week, sel.$2, sel.$3);
});

/// Nombres como los consume el PDF (derivados del formulario).
final asignacionesProvider = Provider<Asignaciones>((ref) {
  final maps =
      ref.watch(formProvider.select((f) => (f.principal, f.auxiliar)));
  return Asignaciones(maps.$1, maps.$2);
});
