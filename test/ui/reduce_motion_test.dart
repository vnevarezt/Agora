import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/app_button.dart';
import 'package:agora/ui/widgets/filter_pill.dart';

// Every animated surface has to go through Motion.of, which zeroes the
// duration when the OS asks for reduced motion. A raw duration handed to an
// animated widget silently ignores the setting.

Future<Iterable<Duration>> _durationsOf(
    WidgetTester tester, Widget child, bool disableAnimations) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(pizarra.light, Brightness.light),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  ));
  await tester.pump();
  return tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .map((w) => w.duration);
}

void main() {
  final surfaces = <String, Widget>{
    'AppButton': AppButton(label: 'Guardar', onPressed: () {}),
    'AppIconButton': AppIconButton(icon: Icons.add, onPressed: () {}),
    'FilterPill': FilterPill(label: 'Todos', active: true, onTap: () {}),
  };

  for (final entry in surfaces.entries) {
    testWidgets('${entry.key} animates normally by default', (tester) async {
      final durations = await _durationsOf(tester, entry.value, false);
      expect(durations, isNotEmpty);
      expect(durations, everyElement(isNot(Duration.zero)));
    });

    testWidgets('${entry.key} honours reduced motion', (tester) async {
      final durations = await _durationsOf(tester, entry.value, true);
      expect(durations, isNotEmpty);
      expect(durations, everyElement(Duration.zero));
    });
  }
}
