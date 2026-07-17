import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/i18n/strings.g.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/state/people_provider.dart';
import 'package:jw_program/ui/participants/participants_view.dart';
import 'package:jw_program/ui/theme/app_theme.dart';
import 'package:jw_program/ui/theme/tokens.dart';

// Probamos solo la UI de ParticipantsView, sobreescribiendo el provider
// síncrono con una lista fija (sin BD) para que sea determinista y rápido.

Person _h(String id, String nombre) {
  final t = DateTime.utc(2026, 6, 1);
  return Person(
    id: id,
    congregationId: 'cong-test',
    firstName: '',
    lastName: '',
    displayName: nombre,
    gender: Gender.male,
    privilege: Role.publisher,
    qualifications: const [],
    originCongregation: '',
    active: true,
    notes: '',
    createdAt: t,
    updatedAt: t,
  );
}

Future<void> _pump(WidgetTester tester, List<Person> lista) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // TranslationProvider igual que en main.dart: slang_flutter lo exige en el
  // árbol para resolver context.t.
  await tester.pumpWidget(TranslationProvider(
    child: ProviderScope(
      overrides: [
        peopleProvider.overrideWithValue(lista),
      ],
      child: MaterialApp(
        theme: buildAppTheme(pizarra.light, Brightness.light),
        home: const Scaffold(body: SafeArea(child: ParticipantsView())),
      ),
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
        find.widgetWithText(TextField, 'Buscar participante…'), 'raul');
    await tester.pump();

    expect(find.text('Raúl Espinoza'), findsOneWidget);
    expect(find.text('Saúl Bravo'), findsNothing);
  });

  testWidgets('estado vacío y abre el modal de alta', (tester) async {
    await _pump(tester, const []);

    expect(find.textContaining('Aún no hay participantes'), findsOneWidget);

    await tester.tap(find.text('Añadir participante'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('El privilegio define qué partes se le pueden asignar.'),
      findsOneWidget,
    );
  });
}
