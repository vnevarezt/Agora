import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../models/congregation_settings.dart';
import '../models/hall.dart';
import '../models/project.dart';
import '../models/week_type.dart';
import 'dashboard_provider.dart';
import 'program_content.dart';
import 'program_form.dart';

/// Editor session (phase 2, docs/PHASE2_PROGRAMS_IN_DB.md): which project
/// the editor has open. The form is hydrated ONCE from the DB on open and
/// writes every mutation back (write-through) — the DB is the source of
/// truth, the form its editing cache.

/// Active project id; null = editor closed.
final editorProjectProvider =
    NotifierProvider<EditorProjectController, String?>(
        EditorProjectController.new);

class EditorProjectController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

/// The open project's alive programs, reactive: content snapshots filled
/// in the background show up here (and re-derive the editor's weeks).
final editorProgramsProvider = StreamProvider<List<ProgramRecord>>((ref) {
  final projectId = ref.watch(editorProjectProvider);
  if (projectId == null) return Stream.value(const []);
  return ref.watch(programsRepositoryProvider).watchByProject(projectId);
});

/// Cold-start gap: the editor can open BEFORE the background sync fills the
/// notebook catalog, leaving pre-snapshot programs without content and no
/// retry (seen in the wild: empty titles/assignments until the project was
/// re-saved). Watching the catalog re-runs the fill the moment it lands;
/// `ensureProjectContent` is idempotent, so extra runs are no-ops.
final editorContentFillProvider = Provider<void>((ref) {
  final projectId = ref.watch(editorProjectProvider);
  final notebooks = ref.watch(notebooksProvider);
  if (projectId == null || notebooks.isEmpty) return;
  final service = ref.read(programContentServiceProvider);
  Future.microtask(() => service.ensureProjectContent(projectId));
});

final editorOpenerProvider = Provider<EditorOpener>(EditorOpener.new);

class EditorOpener {
  EditorOpener(this._ref);

  final Ref _ref;

  /// Opens [project] in the editor: kicks the content snapshot fill and
  /// hydrates the form with the stored assignments/flags/config.
  Future<void> open(Project project) async {
    _ref.read(editorProjectProvider.notifier).set(project.id);
    unawaited(_ref
        .read(programContentServiceProvider)
        .ensureProjectContent(project.id));

    final repo = _ref.read(programsRepositoryProvider);
    final programs = await repo.byProject(project.id);
    final assignments =
        await repo.assignmentsByPrograms([for (final p in programs) p.id]);

    // Congregation identity/config: the dashboard primed the stream before
    // navigating here, so the sync list is populated.
    final congregations = _ref.read(congregationsProvider);
    var congregationName = '';
    var settings = const CongregationSettings();
    for (final c in congregations) {
      if (c.id == project.congregationId) {
        congregationName = c.name;
        settings = c.settings;
        break;
      }
    }

    _ref.read(formProvider.notifier).hydrate(
          buildHydratedForm(
            programs: programs,
            assignments: assignments,
            congregationName: congregationName,
            congregationSettings: settings,
          ),
          projectId: project.id,
          programIds: [for (final p in programs) p.id],
        );
  }

  /// Editor closed: stops the programs stream. The form keeps its last
  /// state harmlessly — the next open() re-hydrates it.
  void close() => _ref.read(editorProjectProvider.notifier).set(null);
}

/// Pure mapping DB rows → editable form (unit-tested): assignment rows fill
/// the per-week maps, weekType drives the CO flag, per-program config falls
/// back to the congregation settings.
FormModel buildHydratedForm({
  required List<ProgramRecord> programs,
  required List<AssignmentRecord> assignments,
  required String congregationName,
  required CongregationSettings congregationSettings,
}) {
  final byProgram = <String, List<AssignmentRecord>>{};
  for (final a in assignments) {
    byProgram.putIfAbsent(a.programId, () => []).add(a);
  }

  final chairmanByWeek = <int, String>{};
  final mainByWeek = <int, Map<String, List<String>>>{};
  final auxByWeek = <int, Map<String, List<String>>>{};
  final circuitOverseerByWeek = <int, bool>{};
  final titleOverridesByWeek = <int, Map<String, String>>{};

  for (var wi = 0; wi < programs.length; wi++) {
    final program = programs[wi];
    circuitOverseerByWeek[wi] =
        program.weekType == WeekType.circuitOverseerVisit;

    final overrides = _decodeOverrides(program.titleOverridesJson);
    if (overrides.isNotEmpty) titleOverridesByWeek[wi] = overrides;

    final main = <String, List<String>>{};
    final aux = <String, List<String>>{};
    for (final a in byProgram[program.id] ?? const <AssignmentRecord>[]) {
      if (a.slotKey == 'chairman') {
        chairmanByWeek[wi] = a.displayName;
        continue;
      }
      final target = a.hall == Hall.aux ? aux : main;
      final names = target[a.slotKey] ?? <String>[];
      while (names.length <= a.position) {
        names.add('');
      }
      names[a.position] = a.displayName;
      target[a.slotKey] = names;
    }
    if (main.isNotEmpty) mainByWeek[wi] = main;
    if (aux.isNotEmpty) auxByWeek[wi] = aux;
  }

  final first = programs.isEmpty ? null : programs.first;
  return FormModel(
    issue: FormModel.initial.issue,
    congregationId: congregationName,
    startTime: first?.startTime ?? congregationSettings.midweekTime,
    duration: first?.durationMinutes ?? FormModel.initial.duration,
    auxRoom: first?.auxRoom ?? congregationSettings.auxRoom,
    weekIndex: 0,
    chairmanByWeek: chairmanByWeek,
    mainByWeek: mainByWeek,
    auxByWeek: auxByWeek,
    circuitOverseerByWeek: circuitOverseerByWeek,
    titleOverridesByWeek: titleOverridesByWeek,
  );
}

Map<String, String> _decodeOverrides(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) {
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    }
  } catch (_) {}
  return const {};
}
