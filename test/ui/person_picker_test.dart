import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/person.dart';
import 'package:agora/state/people_provider.dart';
import 'package:agora/ui/picker/person_picker_panel.dart';
import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';

Person _p(String name, {bool active = true}) {
  final t = DateTime.utc(2026, 6, 1);
  return Person(
    id: name,
    congregationId: 'c',
    firstName: '',
    lastName: '',
    displayName: name,
    gender: Gender.male,
    privilege: Role.publisher,
    qualifications: const [],
    originCongregation: '',
    active: active,
    notes: '',
    createdAt: t,
    updatedAt: t,
  );
}

Future<void> _pump(WidgetTester tester, List<Person> people) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(TranslationProvider(
    child: ProviderScope(
      overrides: [peopleProvider.overrideWithValue(people)],
      child: MaterialApp(
        theme: buildAppTheme(pizarra.light, Brightness.light),
        home: const Scaffold(
          body: PersonPickerPanel(roleLabel: 'Lector', current: '', maxLength: 40),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('lists the active people, sorted, without the inactive ones',
      (tester) async {
    await _pump(tester, [
      _p('Zacarías'),
      _p('Ana'),
      _p('Bruno', active: false),
    ]);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Zacarías'), findsOneWidget);
    expect(find.text('Bruno'), findsNothing);
  });

  testWidgets('search ignores accents and case', (tester) async {
    await _pump(tester, [_p('Raúl Espinoza'), _p('Saúl Bravo')]);

    await tester.enterText(find.byType(TextField), 'RAUL');
    await tester.pump();

    expect(find.text('Raúl Espinoza'), findsOneWidget);
    expect(find.text('Saúl Bravo'), findsNothing);
  });

  testWidgets('a non-matching search leaves no rows', (tester) async {
    await _pump(tester, [_p('Raúl Espinoza')]);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('Raúl Espinoza'), findsNothing);
  });
}
