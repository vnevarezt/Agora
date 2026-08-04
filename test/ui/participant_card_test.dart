import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/i18n/strings.g.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/ui/participants/participant_card.dart';
import 'package:jw_program/ui/theme/app_theme.dart';
import 'package:jw_program/ui/theme/tokens.dart';

// The participants grid virtualises with a fixed tile extent taken from
// participantCardHeight(). That is only safe while every card really does lay
// out at that height, so these tests pin the prediction against the real one.
// A tile shorter than its card clips it; a tile taller wastes a little space.

Person _p(String name, {String origin = '', Gender gender = Gender.male}) {
  final t = DateTime.utc(2026, 6, 1);
  return Person(
    id: 'x',
    congregationId: 'c',
    firstName: '',
    lastName: '',
    displayName: name,
    gender: gender,
    privilege: Role.elder,
    qualifications: const [],
    originCongregation: origin,
    active: true,
    notes: '',
    createdAt: t,
    updatedAt: t,
  );
}

/// Lays out one card at [scale] and returns (actual height, prediction).
Future<(double, double)> _measure(
    WidgetTester tester, Person person, double scale) async {
  late double predicted;
  await tester.pumpWidget(TranslationProvider(
    child: MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 330,
              child: Builder(builder: (context) {
                predicted = participantCardHeight(context);
                return ParticipantCard(participant: person, onTap: () {});
              }),
            ),
          ),
        ),
      ),
    ),
  ));
  return (tester.getSize(find.byType(ParticipantCard)).height, predicted);
}

void main() {
  final variants = <String, Person>{
    'short name': _p('Ana'),
    'long name': _p('A Considerably Longer Participant Name Here'),
    'visitor with origin congregation': _p('Luis', origin: 'Another Congregation'),
    'incomplete data': _p('Sin género', gender: Gender.unspecified),
  };

  group('every card lays out at the same height', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('at text scale $scale', (tester) async {
        final heights = <double>{};
        for (final person in variants.values) {
          final (actual, _) = await _measure(tester, person, scale);
          heights.add(actual);
        }
        // One height for every variant: this uniformity is what the grid's
        // fixed tile extent depends on.
        expect(heights, hasLength(1),
            reason: 'card height varies with content: $heights');
      });
    }
  });

  group('participantCardHeight predicts the real height', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('at text scale $scale', (tester) async {
        for (final entry in variants.entries) {
          final (actual, predicted) = await _measure(tester, entry.value, scale);
          // Never under: a short tile clips the card. Never wildly over: a
          // couple of pixels of slack is invisible, more means the formula has
          // drifted from the card.
          expect(predicted, greaterThanOrEqualTo(actual),
              reason: '${entry.key} @ $scale would be clipped');
          expect(predicted, lessThanOrEqualTo(actual + 2),
              reason: '${entry.key} @ $scale wastes space');
        }
      });
    }
  });
}
