import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/domain/schedule_rules.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/week.dart';
import 'package:agora/state/program_form.dart';
import 'package:agora/ui/shell/mobile_bars.dart';
import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';

final _week = Week(
  date: '7-13 DE JULIO',
  parts: [
    const Part(
        section: Section.treasures,
        number: 1,
        title: 'Lectura de la Biblia',
        minutes: 4),
  ],
);

void main() {
  // The frosted bar wraps a BackdropFilter, the most expensive paint here. It
  // must not rebuild when the progress changes — only the ring inside it may.
  testWidgets('assigning a name does not rebuild the frosted layer',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
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
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MobileBottomBar(),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    final before = tester.widget<BackdropFilter>(find.byType(BackdropFilter));

    container.read(formProvider.notifier).setChairman('Andrés');
    await tester.pump();

    final after = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(identical(before, after), isTrue,
        reason: 'the blur was rebuilt by a progress change');
  });
}
