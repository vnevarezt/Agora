import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/app.dart';
import 'package:jw_program/i18n/strings.g.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/state/auth_session.dart';
import 'package:jw_program/state/mwb_sync.dart';
import 'package:jw_program/state/people_provider.dart';

/// Startup sync stubbed out (no network/disk), the session forced unlocked
/// and the people directory overridden (so no drift stream touches the real
/// encrypted DB), so the shell renders straight into the dashboard — same
/// pattern as widget_test.
class _NoopSyncController extends MwbSyncController {
  @override
  Future<SyncReport> build() async => const SyncReport();
}

class _UnlockedSessionController extends SessionController {
  @override
  SessionState build() => SessionUnlocked('00' * 32, AccountMode.local);
}

Future<void> _pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(TranslationProvider(
    child: ProviderScope(
      overrides: [
        mwbSyncProvider.overrideWith(_NoopSyncController.new),
        authSessionProvider.overrideWith(_UnlockedSessionController.new),
        peopleProvider.overrideWithValue(const <Person>[]),
      ],
      child: const JwProgramApp(),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('móvil: la barra inferior es un NavigationBar MD3 y navega',
      (tester) async {
    await _pumpShell(tester, const Size(430, 920));

    // El shell móvil usa el NavigationBar de Material 3 (no el riel lateral).
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Participantes'), findsOneWidget);
    expect(find.text('Configuración'), findsOneWidget);
    // Arranca en Inicio.
    expect(find.text('Tus proyectos y pendientes'), findsOneWidget);

    // Tocar un destino cambia la sección.
    await tester.tap(find.text('Participantes'));
    await tester.pumpAndSettle();
    expect(find.text('Tus proyectos y pendientes'), findsNothing);
  });

  testWidgets('escritorio: usa el riel lateral, no el NavigationBar',
      (tester) async {
    await _pumpShell(tester, const Size(1440, 900));

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Agora'), findsOneWidget); // marca del riel
    expect(find.text('Inicio'), findsOneWidget);
  });
}
