import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/schedule_rules.dart';
import '../models/program_row.dart';
import '../models/week.dart';
import 'weeks_provider.dart';

/// Estado editable del formulario (inmutable). Las asignaciones se guardan
/// **por semana** (índice → mapa por `ProgramRow.id`); los getters [chairman]
/// / [main] / [auxiliary] exponen las de la semana activa, así que todo lo
/// que consume el formulario (PDF, progreso, slots) no cambia de contrato.
class FormModel {
  final String issue;
  final String congregationId;
  final String startTime; // "HH:MM"
  final int duration; // minutos
  final bool auxRoom;
  final int weekIndex;

  final Map<int, String> chairmanByWeek;
  final Map<int, Map<String, List<String>>> mainByWeek;
  final Map<int, Map<String, List<String>>> auxByWeek;

  const FormModel({
    required this.issue,
    required this.congregationId,
    required this.startTime,
    required this.duration,
    required this.auxRoom,
    required this.weekIndex,
    this.chairmanByWeek = const {},
    this.mainByWeek = const {},
    this.auxByWeek = const {},
  });

  static const initial = FormModel(
    issue: '202605',
    congregationId: 'CONSTITUCIÓN J.A CASTRO',
    startTime: '18:00',
    duration: 105,
    auxRoom: false,
    weekIndex: 0,
  );

  // Asignaciones de la semana activa (contrato estable para el resto de la app).
  String get chairman => chairmanByWeek[weekIndex] ?? '';
  Map<String, List<String>> get main => mainByWeek[weekIndex] ?? const {};
  Map<String, List<String>> get auxiliary => auxByWeek[weekIndex] ?? const {};

  /// Minutos desde medianoche del inicio (fallback 18:00 si el texto no es válido).
  int get startMinutes {
    final p = startTime.split(':');
    if (p.length == 2) {
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h != null && m != null) return h * 60 + m;
    }
    return 18 * 60;
  }

  /// [chairman]/[main]/[auxiliary] sobrescriben la **semana resultante**
  /// (la activa tras aplicar [weekIndex]); el resto de semanas se conserva.
  FormModel copyWith({
    String? issue,
    String? congregationId,
    String? startTime,
    int? duration,
    bool? auxRoom,
    int? weekIndex,
    String? chairman,
    Map<String, List<String>>? main,
    Map<String, List<String>>? auxiliary,
  }) {
    final idx = weekIndex ?? this.weekIndex;
    return FormModel(
      issue: issue ?? this.issue,
      congregationId: congregationId ?? this.congregationId,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      auxRoom: auxRoom ?? this.auxRoom,
      weekIndex: idx,
      chairmanByWeek: chairman == null
          ? chairmanByWeek
          : {...chairmanByWeek, idx: chairman},
      mainByWeek: main == null ? mainByWeek : {...mainByWeek, idx: main},
      auxByWeek:
          auxiliary == null ? auxByWeek : {...auxByWeek, idx: auxiliary},
    );
  }
}

final formProvider =
    NotifierProvider<FormController, FormModel>(FormController.new);

class FormController extends Notifier<FormModel> {
  @override
  FormModel build() => FormModel.initial;

  void setIssue(String v) => state = state.copyWith(issue: v);
  void setCongregation(String v) => state = state.copyWith(congregationId: v);
  void setStartTime(String v) => state = state.copyWith(startTime: v);
  void setDuration(int v) => state = state.copyWith(duration: v);
  void setChairman(String v) => state = state.copyWith(chairman: v);
  void setAuxRoom(bool v) => state = state.copyWith(auxRoom: v);

  /// Cambia de semana conservando las asignaciones de cada una.
  void selectWeek(int idx) => state = state.copyWith(weekIndex: idx);

  void setMainNames(String rowId, List<String> names) {
    state = state.copyWith(main: {...state.main, rowId: names});
  }

  void setAuxNames(String rowId, List<String> names) {
    state = state.copyWith(auxiliary: {...state.auxiliary, rowId: names});
  }
}

/// Semana seleccionada (o null si aún no se ha descargado el cuaderno).
final currentWeekProvider = Provider<Week?>((ref) {
  final weeks = ref.watch(weeksProvider).asData?.value;
  if (weeks == null || weeks.isEmpty) return null;
  final idx = ref.watch(formProvider.select((f) => f.weekIndex));
  return weeks[idx.clamp(0, weeks.length - 1)];
});

/// Horario calculado de la semana seleccionada (se recalcula solo si cambian
/// semana, inicio o duración).
final scheduleProvider = Provider<ProgramSchedule?>((ref) {
  final weeks = ref.watch(weeksProvider).asData?.value;
  if (weeks == null || weeks.isEmpty) return null;
  final sel = ref.watch(
      formProvider.select((f) => (f.weekIndex, f.startMinutes, f.duration)));
  final week = weeks[sel.$1.clamp(0, weeks.length - 1)];
  return buildSchedule(week, sel.$2, sel.$3);
});

/// Nombres como los consume el PDF (derivados del formulario).
final assignmentsProvider = Provider<Assignments>((ref) {
  final maps = ref.watch(formProvider.select((f) => (f.main, f.auxiliary)));
  return Assignments(maps.$1, maps.$2);
});
