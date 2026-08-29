// The circuit overseer's visit: at most one week of a project is it, and the
// week that is prints ONE speaker.
//
// Both used to be free to go wrong on the same sheet. Nothing kept two weeks
// from being marked, so a two-per-sheet page could print his talk twice; and
// the talk reuses the Congregation Bible Study's row id, so the conductor and
// reader stored there came out as "Orador: A / B".

import 'package:agora/data/db/app_database.dart';
import 'package:agora/domain/schedule_rules.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/program_row.dart';
import 'package:agora/models/congregation_settings.dart';
import 'package:agora/models/week.dart';
import 'package:agora/models/week_type.dart';
import 'package:agora/state/editor_session.dart';
import 'package:agora/state/app_settings.dart';
import 'package:agora/state/program_form.dart';
import 'package:agora/state/weeks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Week _week(String date) => Week(
      date: date,
      reading: 'JEREMÍAS 26-28',
      openingSong: '77',
      middleSong: '16',
      closingSong: '71',
      parts: const [
        Part(
            section: Section.treasures,
            number: 1,
            title: 'No se deje engañar',
            minutes: 10),
        Part(
            section: Section.treasures,
            number: 3,
            title: 'Lectura de la Biblia',
            minutes: 4),
        Part(
            section: Section.ministry,
            number: 4,
            title: 'Empiece conversaciones',
            minutes: 3),
        Part(
            section: Section.christianLife,
            number: 8,
            title: 'Estudio bíblico de la congregación',
            minutes: 30),
      ],
    );

class _Weeks extends WeeksController {
  @override
  Future<List<Week>> build() async =>
      [_week('17-23 DE AGOSTO'), _week('24-30 DE AGOSTO'), _week('31 DE AGOSTO')];
}

bool _hasTalk(ProgramSchedule s) =>
    s.christianLife.any((r) => r.kind == RowKind.circuitOverseerTalk);

Future<ProviderContainer> _container() async {
  final c = ProviderContainer(overrides: [
    weeksProvider.overrideWith(_Weeks.new),
    twoPerSheetProvider.overrideWithValue(true),
  ]);
  addTearDown(c.dispose);
  await c.read(weeksProvider.future);
  // No program ids: the form is the whole truth here, so the write-through
  // stays out of the way and this exercises the rule, not the database.
  c.read(formProvider.notifier)
      .hydrate(FormModel.initial, projectId: 'p', programIds: const []);
  return c;
}

ProgramRecord _program(int i, WeekType type) => ProgramRecord(
      id: 'p$i',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      projectId: 'proj',
      programTypeId: 'mwb-s140',
      weekType: type,
      date: 'semana $i',
      sortIndex: i,
      label: '',
      titleOverridesJson: '{}',
    );

void main() {
  test('a project that already has two marked weeks loads with one', () {
    // The rule guards the setter, but rows written before it existed can hold
    // two — and that is what put his talk on both weeks of a printed sheet.
    final form = buildHydratedForm(
      programs: [
        _program(0, WeekType.circuitOverseerVisit),
        _program(1, WeekType.circuitOverseerVisit),
        _program(2, WeekType.normal),
      ],
      assignments: const [],
      congregationName: 'Constitucion J. A. Castro',
      congregationSettings: const CongregationSettings(),
    );

    final marked = [
      for (final e in form.circuitOverseerByWeek.entries)
        if (e.value) e.key
    ];
    expect(marked, [0]);
  });

  test('marking a week clears whichever week was marked before', () async {
    final c = await _container();
    final form = c.read(formProvider.notifier);

    form.setCircuitOverseer(0, true);
    form.setCircuitOverseer(1, true);

    final marked = [
      for (final e in c.read(formProvider).circuitOverseerByWeek.entries)
        if (e.value) e.key
    ];
    expect(marked, [1],
        reason: 'the overseer comes once, and a project is one workbook');
  });

  test('the two weeks of a sheet never both carry the talk', () async {
    final c = await _container();
    final form = c.read(formProvider.notifier);

    form.setCircuitOverseer(0, true);
    form.setCircuitOverseer(1, true);

    final entries = c.read(sheetEntriesProvider);
    expect(entries.length, 2);
    expect(entries.where((e) => _hasTalk(e.schedule)).length, 1);
  });

  test('unmarking the marked week leaves the sheet with none', () async {
    final c = await _container();
    final form = c.read(formProvider.notifier);

    form.setCircuitOverseer(1, true);
    form.setCircuitOverseer(1, false);

    expect(c.read(sheetEntriesProvider).any((e) => _hasTalk(e.schedule)),
        isFalse);
  });

  test("the talk prints one speaker, not the Bible study's pair", () {
    final tr = AppLocale.es.buildSync();
    final week = _week('24-30 DE AGOSTO');
    final study = buildSchedule(week, 18 * 60, 105);
    final cbs = study.christianLife
        .firstWhere((r) => r.role == SlotRole.conductorReader);
    // The names were entered against the Bible study, then the week was marked.
    final names = Assignments({
      cbs.id: const ['Josué Soto', 'Luis Vargas']
    }, {});

    final visit = buildSchedule(week, 18 * 60, 105, circuitOverseer: true);
    final talk = visit.christianLife
        .firstWhere((r) => r.kind == RowKind.circuitOverseerTalk);

    expect(talk.id, cbs.id, reason: 'same row, which is how the pair leaked');
    expect(talk.slots, 1);
    expect(names.main(talk), ['Josué Soto']);
    expect(joinedNames(names.main(talk)), 'Josué Soto');
    expect(talk.role.label(tr), 'Orador:');
  });

  test('an unfilled half of a pair takes its separator with it', () {
    expect(joinedNames(const ['', '']), '');
    expect(joinedNames(const ['', ' ']), '');
    expect(joinedNames(const ['Ana', '']), 'Ana',
        reason: 'the role label already says a second name is expected');
    expect(joinedNames(const ['', 'Ana']), 'Ana');
    expect(joinedNames(const ['Ana', 'Eva']), 'Ana / Eva');
  });
}
