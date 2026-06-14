import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/schedule_rules.dart';
import '../models/program_row.dart';
import '../models/week.dart';
import 'weeks_provider.dart';

/// Estado editable del formulario (inmutable). Las asignaciones se guardan
/// **por semana** (índice → mapa por `ProgramRow.id`); los getters [presidente]
/// / [principal] / [auxiliar] exponen las de la semana activa, así que todo lo
/// que consume el formulario (PDF, progreso, slots) no cambia de contrato.
class FormModel {
  final String issue;
  final String cong;
  final String inicio; // "HH:MM"
  final int duracion; // minutos
  final bool aux;
  final int semanaIdx;

  final Map<int, String> presidentePorSemana;
  final Map<int, Map<String, List<String>>> principalPorSemana;
  final Map<int, Map<String, List<String>>> auxiliarPorSemana;

  const FormModel({
    required this.issue,
    required this.cong,
    required this.inicio,
    required this.duracion,
    required this.aux,
    required this.semanaIdx,
    this.presidentePorSemana = const {},
    this.principalPorSemana = const {},
    this.auxiliarPorSemana = const {},
  });

  static const inicial = FormModel(
    issue: '202605',
    cong: 'CONSTITUCIÓN J.A CASTRO',
    inicio: '18:00',
    duracion: 105,
    aux: false,
    semanaIdx: 0,
  );

  // Assignments de la semana activa (contrato estable para el resto de la app).
  String get presidente => presidentePorSemana[semanaIdx] ?? '';
  Map<String, List<String>> get principal =>
      principalPorSemana[semanaIdx] ?? const {};
  Map<String, List<String>> get auxiliar =>
      auxiliarPorSemana[semanaIdx] ?? const {};

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

  /// [presidente]/[principal]/[auxiliar] sobrescriben la **semana resultante**
  /// (la activa tras aplicar [semanaIdx]); el resto de semanas se conserva.
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
    final idx = semanaIdx ?? this.semanaIdx;
    return FormModel(
      issue: issue ?? this.issue,
      cong: cong ?? this.cong,
      inicio: inicio ?? this.inicio,
      duracion: duracion ?? this.duracion,
      aux: aux ?? this.aux,
      semanaIdx: idx,
      presidentePorSemana: presidente == null
          ? presidentePorSemana
          : {...presidentePorSemana, idx: presidente},
      principalPorSemana: principal == null
          ? principalPorSemana
          : {...principalPorSemana, idx: principal},
      auxiliarPorSemana: auxiliar == null
          ? auxiliarPorSemana
          : {...auxiliarPorSemana, idx: auxiliar},
    );
  }
}

final formProvider =
    NotifierProvider<FormController, FormModel>(FormController.new);

class FormController extends Notifier<FormModel> {
  @override
  FormModel build() => FormModel.inicial;

  void setIssue(String v) => state = state.copyWith(issue: v);
  void setCongregation(String v) => state = state.copyWith(cong: v);
  void setStartTime(String v) => state = state.copyWith(inicio: v);
  void setDuration(int v) => state = state.copyWith(duracion: v);
  void setChairman(String v) => state = state.copyWith(presidente: v);
  void setAuxRoom(bool v) => state = state.copyWith(aux: v);

  /// Cambia de semana conservando las asignaciones de cada una.
  void selectWeek(int idx) => state = state.copyWith(semanaIdx: idx);

  void setMainNames(String rowId, List<String> nombres) {
    state = state.copyWith(principal: {...state.principal, rowId: nombres});
  }

  void setAuxNames(String rowId, List<String> nombres) {
    state = state.copyWith(auxiliar: {...state.auxiliar, rowId: nombres});
  }
}

/// Semana seleccionada (o null si aún no se ha descargado el cuaderno).
final currentWeekProvider = Provider<Week?>((ref) {
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
  return buildSchedule(week, sel.$2, sel.$3);
});

/// Nombres como los consume el PDF (derivados del formulario).
final assignmentsProvider = Provider<Assignments>((ref) {
  final maps =
      ref.watch(formProvider.select((f) => (f.principal, f.auxiliar)));
  return Assignments(maps.$1, maps.$2);
});
