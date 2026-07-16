// End-to-end local-auth flow against the REAL macOS keychain and encrypted
// database: create account → dashboard → cloud-not-configured card → lock →
// wrong password → unlock.
//
// SAFETY: it only runs on a machine with NO existing key material (fresh
// state) so it can never touch a real user's data, and it wipes everything
// it created when it finishes.
//
// Run with: flutter test integration_test/auth_flow_test.dart -d macos
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jw_program/data/db/connection.dart';
import 'package:jw_program/data/db/db_key_manager.dart';
import 'package:jw_program/main.dart' as app;
import 'package:jw_program/ui/widgets/app_button.dart';

const _password = 'integration-test-pass';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _wipe() async {
  await DbKeyManager().destroyAll();
  final db = await databaseFile();
  if (await db.exists()) await db.delete();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('local auth end-to-end on a fresh machine', (tester) async {
    // Refuse to run over existing key material: this suite manipulates the
    // real keychain and DB file.
    final status = await DbKeyManager().status();
    if (status != LocalKeyStatus.none) {
      fail('Key material already exists on this machine ($status); '
          'aborting so real data is never touched.');
    }
    // Machine is clean both on success and on failure of a previous run.
    addTearDown(_wipe);

    await app.main();

    // Fresh install → create-account wizard (base locale is Spanish).
    await _pumpUntilFound(tester, find.text('Crea tu cuenta local'));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), _password);
    await tester.enterText(fields.at(1), _password);
    await tester.tap(find.widgetWithText(AppButton, 'Crear cuenta'));

    // Argon2id runs in an isolate; give it time, then the dashboard shows.
    await _pumpUntilFound(tester, find.text('Tus proyectos y pendientes'),
        timeout: const Duration(seconds: 60));

    // Settings: placeholder Firebase config must degrade to "not configured".
    await tester.tap(find.text('Configuración'));
    await _pumpUntilFound(tester, find.text('Nube no configurada'));

    // Lock from the security card.
    await tester.tap(find.widgetWithText(AppButton, 'Bloquear'));
    await _pumpUntilFound(tester, find.widgetWithText(AppButton, 'Desbloquear'));

    // Wrong password is rejected with an inline error.
    await tester.enterText(find.byType(TextField), 'not-the-password');
    await tester.tap(find.widgetWithText(AppButton, 'Desbloquear'));
    await _pumpUntilFound(tester, find.text('Contraseña incorrecta.'),
        timeout: const Duration(seconds: 60));

    // Right password unlocks back into the shell.
    await tester.enterText(find.byType(TextField), _password);
    await tester.tap(find.widgetWithText(AppButton, 'Desbloquear'));
    await _pumpUntilFound(tester, find.text('Tus proyectos y pendientes'),
        timeout: const Duration(seconds: 60));
  });
}
