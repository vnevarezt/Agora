import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/domain/schedule_rules.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/week.dart';
import 'package:agora/state/program_form.dart';
import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/section_header.dart';
import 'package:agora/ui/workspace/part_card.dart';
import 'package:agora/ui/workspace/workspace_panel.dart';

final _week = Week(
  date: '7-13 DE JULIO',
  openingSong: '101',
  closingSong: '61',
  parts: [
    const Part(
        section: Section.treasures,
        number: 1,
        title: 'Guarda tu corazon',
        minutes: 10),
    const Part(
        section: Section.treasures,
        number: 2,
        title: 'Lectura de la Biblia',
        minutes: 4),
    const Part(
        section: Section.ministry,
        number: 3,
        title: 'Haga revisitas',
        minutes: 5),
    const Part(
        section: Section.christianLife,
        number: 4,
        title: 'Estudio biblico de la congregacion',
        minutes: 30),
  ],
);

Future<ProviderContainer> _pump(WidgetTester tester, {Size? size}) async {
  tester.view.physicalSize = size ?? const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    scheduleProvider.overrideWithValue(buildSchedule(_week, 18 * 60, 105)),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(TranslationProvider(
    child: UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(pizarra.light, Brightness.light),
        home: const Scaffold(body: SafeArea(child: WorkspacePanel())),
      ),
    ),
  ));
  await tester.pump();
  return container;
}

List<String> _cardTitles(WidgetTester tester) => [
      for (final c in tester.widgetList<PartCard>(find.byType(PartCard)))
        c.view.title,
    ];

List<({int? done, int? total})> _counters(WidgetTester tester) => [
      for (final h in tester.widgetList<SectionHeader>(find.byType(SectionHeader)))
        (done: h.done, total: h.total),
    ];

void main() {
  testWidgets('section counters come from the schedule slots', (tester) async {
    await _pump(tester);

    // opening (prayer), treasures (gems + reading), ministry (student +
    // assistant), christian life (conductor + reader, closing prayer).
    expect(_counters(tester), [
      (done: 0, total: 1),
      (done: 0, total: 2),
      (done: 0, total: 2),
      (done: 0, total: 3),
    ]);
  });

  testWidgets('a name only moves its own section counter', (tester) async {
    final container = await _pump(tester);

    container.read(formProvider.notifier).setMainNames('te0', ['Ana']);
    await tester.pump();

    expect(_counters(tester), [
      (done: 0, total: 1),
      (done: 1, total: 2),
      (done: 0, total: 2),
      (done: 0, total: 3),
    ]);
  });

  testWidgets('a name does not rebuild any card', (tester) async {
    final container = await _pump(tester);
    final before =
        tester.widgetList<PartCard>(find.byType(PartCard)).toList();

    container.read(formProvider.notifier).setMainNames('te0', ['Ana']);
    await tester.pump();

    final after = tester.widgetList<PartCard>(find.byType(PartCard)).toList();
    expect(after, hasLength(before.length));
    for (var i = 0; i < before.length; i++) {
      expect(identical(before[i], after[i]), isTrue,
          reason: 'card $i was rebuilt; only its own slot should react');
    }
  });

  testWidgets('the auxiliary room adds its slots to the eligible sections',
      (tester) async {
    final container = await _pump(tester);

    container.read(formProvider.notifier).setAuxRoom(true);
    await tester.pump();

    // Aux slots: the Bible reading (1) and every ministry part (2).
    expect(_counters(tester), [
      (done: 0, total: 1),
      (done: 0, total: 3),
      (done: 0, total: 4),
      (done: 0, total: 3),
    ]);

    container.read(formProvider.notifier).setAuxNames('se0', ['Eva', 'Sara']);
    await tester.pump();

    expect(_counters(tester)[2], (done: 2, total: 4));
  });

  // The rows are built on demand, so a viewport shorter than the program has
  // to keep producing them as it scrolls.
  testWidgets('scrolling builds the rows further down', (tester) async {
    await _pump(tester, size: const Size(900, 400));
    final before = _cardTitles(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump();
    final after = _cardTitles(tester);

    expect(after, isNotEmpty);
    expect(after, isNot(equals(before)));
  });
}
