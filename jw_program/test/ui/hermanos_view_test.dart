import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/models/hermano.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/ui/personas/hermanos_view.dart';
import 'package:jw_program/ui/theme/app_theme.dart';
import 'package:jw_program/ui/theme/tokens.dart';

Hermano _hermano(String id, String nombre) {
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

Future<AppDatabase> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(ProviderScope(
    overrides: [dbProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: const Scaffold(body: SafeArea(child: HermanosView())),
    ),
  ));
  await tester.pump(); // primera emisión del stream
  return db;
}

void main() {
  testWidgets('estado vacío y alta de un hermano', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Aún no hay hermanos'), findsOneWidget);

    await tester.tap(find.text('Añadir hermano'));
    await tester.pumpAndSettle();
    // El modal está abierto si aparece su descripción.
    expect(
      find.text('El privilegio define qué partes se le pueden asignar.'),
      findsOneWidget,
    );

    await tester.enterText(
        find.widgetWithText(TextField, 'Ej. Martín Salas'), 'Raúl Espinoza');
    await tester.pump();

    // Botón primario del modal (no el del topbar).
    await tester.tap(find.descendant(
      of: find.byType(Dialog),
      matching: find.text('Añadir hermano'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Raúl Espinoza'), findsOneWidget);
  });

  testWidgets('la búsqueda filtra sin acentos', (tester) async {
    final db = await _pump(tester);
    await db.hermanosDao.upsert(_hermano('a', 'Raúl Espinoza'));
    await db.hermanosDao.upsert(_hermano('b', 'Saúl Bravo'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Raúl Espinoza'), findsOneWidget);
    expect(find.text('Saúl Bravo'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Buscar hermano…'), 'raul');
    await tester.pump();

    expect(find.text('Raúl Espinoza'), findsOneWidget);
    expect(find.text('Saúl Bravo'), findsNothing);
  });
}
