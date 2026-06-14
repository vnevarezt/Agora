import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/models/hermano.dart';
import 'package:jw_program/state/hermanos_provider.dart';
import 'package:jw_program/ui/personas/hermanos_view.dart';
import 'package:jw_program/ui/theme/app_theme.dart';
import 'package:jw_program/ui/theme/tokens.dart';

// Probamos solo la UI de HermanosView, alimentando el directorio en memoria
// con una lista fija para que sea determinista y rápido.
class _FakeHermanos extends HermanosController {
  _FakeHermanos(this._lista);

  final List<Hermano> _lista;

  @override
  List<Hermano> build() => _lista;
}

Hermano _h(String id, String nombre) {
  final t = DateTime.utc(2026, 6, 1);
  return Hermano(
    id: id,
    nombre: nombre,
    sexo: Sexo.hombre,
    privilegio: Privilegio.publicador,
    congregacion: 'TEST',
    activo: true,
    notas: '',
    createdAt: t,
    updatedAt: t,
  );
}

Future<void> _pump(WidgetTester tester, List<Hermano> lista) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      hermanosTodosProvider.overrideWith(() => _FakeHermanos(lista)),
    ],
    child: MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: const Scaffold(body: SafeArea(child: HermanosView())),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('renderiza tarjetas y la búsqueda filtra sin acentos',
      (tester) async {
    await _pump(tester, [_h('a', 'Raúl Espinoza'), _h('b', 'Saúl Bravo')]);

    expect(find.text('Raúl Espinoza'), findsOneWidget);
    expect(find.text('Saúl Bravo'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Buscar hermano…'), 'raul');
    await tester.pump();

    expect(find.text('Raúl Espinoza'), findsOneWidget);
    expect(find.text('Saúl Bravo'), findsNothing);
  });

  testWidgets('estado vacío y abre el modal de alta', (tester) async {
    await _pump(tester, const []);

    expect(find.textContaining('Aún no hay hermanos'), findsOneWidget);

    await tester.tap(find.text('Añadir hermano'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('El privilegio define qué partes se le pueden asignar.'),
      findsOneWidget,
    );
  });
}
