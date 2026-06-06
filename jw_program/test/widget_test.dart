// Smoke test básico de la app JW Program.

import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/main.dart';

void main() {
  testWidgets('La app arranca y muestra el título', (WidgetTester tester) async {
    await tester.pumpWidget(const JwProgramApp());
    expect(find.text('JW Program — Vida y Ministerio'), findsOneWidget);
  });
}
