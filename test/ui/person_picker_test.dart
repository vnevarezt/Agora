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

Future<void> _pump(WidgetTester tester, List<Person> people,
    {double maxHeight = 1200}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(TranslationProvider(
    child: ProviderScope(
      overrides: [peopleProvider.overrideWithValue(people)],
      child: MaterialApp(
        theme: buildAppTheme(pizarra.light, Brightness.light),
        home: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 320),
              child: const PersonPickerPanel(
                  roleLabel: 'Lector', current: '', maxLength: 40),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

/// Lays out one row at [scale] and returns (actual height, prediction).
Future<(double, double)> _measureRow(
    WidgetTester tester, String name, String? tag, double scale) async {
  late double predicted;
  await tester.pumpWidget(TranslationProvider(
    child: MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: Builder(builder: (context) {
                predicted = personPickerRowHeight(context);
                return PersonPickerRow(name: name, tag: tag, onTap: () {});
              }),
            ),
          ),
        ),
      ),
    ),
  ));
  return (tester.getSize(find.byType(PersonPickerRow)).height, predicted);
}

void main() {
  // The picker virtualises with a fixed extent from personPickerRowHeight(),
  // which is only safe while every row really lays out at that height. A row
  // shorter than its extent leaves a gap; taller, it clips.
  group('personPickerRowHeight predicts the real row height', () {
    final variants = <String, (String, String?)>{
      'short name': ('Ana', null),
      'long name': ('A Considerably Longer Participant Name Here', null),
      'with privilege tag': ('Luis', 'Anciano'),
    };

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('at text scale $scale', (tester) async {
        final heights = <double>{};
        for (final v in variants.values) {
          final (actual, predicted) =
              await _measureRow(tester, v.$1, v.$2, scale);
          heights.add(actual);
          expect(predicted, greaterThanOrEqualTo(actual),
              reason: 'a shorter extent clips the row');
          expect(predicted - actual, lessThan(6),
              reason: 'prediction drifted too far above the real height');
        }
        expect(heights, hasLength(1),
            reason: 'row height varies with content: $heights');
      });
    }
  });

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

  testWidgets('the panel still shrinks to a short list', (tester) async {
    await _pump(tester, [_p('Ana'), _p('Bruno')], maxHeight: 600);

    // Sizing to content is what shrinkWrap buys; virtualising must not cost it.
    expect(tester.getSize(find.byType(PersonPickerPanel)).height,
        lessThan(400));
  });
}
