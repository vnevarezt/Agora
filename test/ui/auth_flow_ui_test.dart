import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/app.dart';
import 'package:jw_program/data/db/db_key_manager.dart';
import 'package:jw_program/i18n/strings.g.dart';
import 'package:jw_program/state/auth_session.dart';
import 'package:jw_program/state/cloud_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/map_key_store.dart';

// La creación/desbloqueo reales corren Argon2 en un isolate (incompatible con
// la zona fake-async de testWidgets); eso lo cubren auth_session_test y el
// test de integración. Aquí se verifica la UI del flujo: portada, navegación
// y validaciones síncronas.
Future<void> pumpApp(WidgetTester tester, MapKeyStore store) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(TranslationProvider(
    child: ProviderScope(
      overrides: [
        dbKeyManagerProvider.overrideWithValue(
            DbKeyManager(store: store, params: testKdfParams)),
        firebaseAppProvider.overrideWith((ref) => Future.value(null)),
      ],
      child: const JwProgramApp(),
    ),
  ));
  // _init (prefs + keychain) y animaciones de entrada de la portada.
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('portada muestra las 3 acciones (nube configurada o no)',
      (tester) async {
    await pumpApp(tester, MapKeyStore());

    expect(find.text('Agora'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Continuar sin cuenta'), findsOneWidget);
    expect(find.text('Solo en este dispositivo'), findsOneWidget);
  });

  testWidgets('portada → nube: login y registro completos, aviso sin config',
      (tester) async {
    await pumpApp(tester, MapKeyStore());

    await tester.tap(find.text('Iniciar sesión'));
    // pumpAndSettle: un pump fijo deja la pantalla saliente del
    // AnimatedSwitcher a mitad de transición (y duplicaría los finders).
    await tester.pumpAndSettle();

    expect(find.text('Modo nube'.toUpperCase()), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Correo'.toUpperCase()), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);

    // Cambia a registro: aparecen nombre y confirmación.
    await tester.tap(find.text('Regístrate'));
    await tester.pump();
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Tu nombre'.toUpperCase()), findsOneWidget);
    expect(find.text('Confirmar contraseña'.toUpperCase()), findsOneWidget);

    // Sin Firebase configurado, Google explica en lugar de fallar mudo.
    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    expect(
        find.text(
            'Esta instalación no tiene proyecto de Firebase; el modo nube no está disponible.'),
        findsOneWidget);

    await tester.tap(find.text('Elegir otro modo'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar sin cuenta'), findsOneWidget);
  });

  testWidgets('portada → perfil local: navegación y validaciones',
      (tester) async {
    await pumpApp(tester, MapKeyStore());

    await tester.tap(find.text('Continuar sin cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu perfil local'), findsOneWidget);
    expect(find.text('Modo local'.toUpperCase()), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana Pérez');
    await tester.enterText(fields.at(1), 'corta');
    await tester.enterText(fields.at(2), 'corta');
    // Sin este pump el botón sigue construido como deshabilitado (el
    // setState de onChanged aún no re-construyó) y el tap no hace nada.
    await tester.pump();
    await tester.tap(find.text('Crear perfil y empezar'));
    await tester.pump();
    expect(find.text('La contraseña debe tener al menos 8 caracteres.'),
        findsOneWidget);

    await tester.enterText(fields.at(1), 'contraseña-larga');
    await tester.enterText(fields.at(2), 'otra-distinta');
    await tester.pump();
    await tester.tap(find.text('Crear perfil y empezar'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

    // Volver a la portada.
    await tester.tap(find.text('Elegir otro modo'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar sin cuenta'), findsOneWidget);
  });

  testWidgets('modo local bloqueado muestra el perfil en el unlock',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'account_mode': 'local', 'local_profile_name': 'Ana Pérez'});
    final store = MapKeyStore();
    // runAsync: createAccount deriva la KEK con Argon2 en un Isolate.run,
    // que nunca completa dentro de la zona fake-async de testWidgets.
    await tester.runAsync(() =>
        DbKeyManager(store: store, params: testKdfParams)
            .createAccount('pw-123456'));

    await pumpApp(tester, store);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget); // iniciales del avatar
    expect(find.text('Perfil local · este dispositivo'), findsOneWidget);
    expect(find.text('Desbloquear'), findsOneWidget);
    expect(find.text('¿Empezar de cero?'), findsOneWidget);
  });
}
