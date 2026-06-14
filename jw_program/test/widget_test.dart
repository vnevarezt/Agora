// Smoke test básico de la app JW Program: arranca en el dashboard (Inicio).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/app.dart';

void main() {
  testWidgets('La app arranca en el dashboard (Inicio)',
      (WidgetTester tester) async {
    // Superficie de escritorio: la fuente Ahem de los tests es mucho más
    // ancha que Manrope y desborda en el tamaño por defecto (800).
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: JwProgramApp()));
    await tester.pump();

    expect(find.text('Programa'), findsOneWidget); // marca de la barra lateral
    expect(find.text('Inicio'), findsOneWidget); // navegación
    expect(find.text('Tus proyectos y pendientes'), findsOneWidget); // subtítulo
  });
}
