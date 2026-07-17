// Smoke test básico de la app JW Program: arranca en el dashboard (Inicio).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/app.dart';
import 'package:jw_program/i18n/strings.g.dart';
import 'package:jw_program/models/congregation.dart';
import 'package:jw_program/models/project.dart';
import 'package:jw_program/state/auth_session.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/mwb_sync.dart';

/// Sync de arranque sin red ni disco: evita que el smoke test toque
/// path_provider/jw.org y que el I/O real cuelgue en la zona fake-async.
class _NoopSyncController extends MwbSyncController {
  @override
  Future<SyncReport> build() async => const SyncReport();
}

/// Sesión ya desbloqueada: salta el AuthGate sin tocar el llavero real.
class _UnlockedSessionController extends SessionController {
  @override
  SessionState build() => SessionUnlocked('00' * 32, AccountMode.local);
}

void main() {
  testWidgets('La app arranca en el dashboard (Inicio)',
      (WidgetTester tester) async {
    // Superficie de escritorio: la fuente Ahem de los tests es mucho más
    // ancha que Manrope y desborda en el tamaño por defecto (800).
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // TranslationProvider igual que en main.dart (slang_flutter lo exige).
    await tester.pumpWidget(TranslationProvider(
      child: ProviderScope(
        overrides: [
          mwbSyncProvider.overrideWith(_NoopSyncController.new),
          authSessionProvider.overrideWith(_UnlockedSessionController.new),
          // Directorio y dashboard sin BD: los providers síncronos se
          // sobreescriben para no abrir la BD cifrada real en el test.
          congregationsProvider.overrideWithValue(const <Congregation>[]),
          projectsProvider.overrideWithValue(const <Project>[]),
        ],
        child: const JwProgramApp(),
      ),
    ));
    await tester.pump();

    expect(find.text('Agora'), findsOneWidget); // marca de la barra lateral
    expect(find.text('Inicio'), findsOneWidget); // navegación
    expect(find.text('Tus proyectos y pendientes'), findsOneWidget); // subtítulo
  });
}
