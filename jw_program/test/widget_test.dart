// Smoke test básico de la app JW Program.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/app.dart';

void main() {
  testWidgets('La app arranca con la barra de contexto y el estado vacío',
      (WidgetTester tester) async {
    // Superficie de escritorio: la fuente Ahem de los tests es mucho más
    // ancha que Manrope y desborda la barra en el tamaño por defecto (800).
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: JwProgramApp()));

    expect(find.textContaining('Programa'), findsWidgets); // marca ctx bar
    expect(find.text('Exportar PDF'), findsOneWidget);
    expect(find.text('Descarga un cuaderno para empezar.'), findsOneWidget);
  });
}
