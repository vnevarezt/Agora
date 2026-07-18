import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n/strings.g.dart';
import 'state/app_settings.dart';
import 'state/mwb_sync.dart';
import 'state/sync_controller.dart';
import 'ui/auth/auth_gate.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/tokens.dart';

class JwProgramApp extends ConsumerWidget {
  const JwProgramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Agora',
      debugShowCheckedModeBanner: false,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(pizarra.light, Brightness.light),
      darkTheme: buildAppTheme(pizarra.dark, Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      // Nothing DB-related builds until AuthGate unlocks (see dbProvider's
      // invariant); the background sync also waits behind it.
      home: const AuthGate(child: _SyncBootstrap(child: AppShell())),
    );
  }
}

/// Kicks off the background syncs on startup without blocking or rebuilding
/// the [MaterialApp]: the notebook catalog sync (runs once, network only when
/// the cache lacks the next ~2 months) and the cloud sync engine (arms its
/// push/pull triggers once the cloud is configured, signed in and keys are
/// ready — otherwise it stays disabled).
class _SyncBootstrap extends ConsumerWidget {
  const _SyncBootstrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mwbSyncProvider);
    ref.watch(syncControllerProvider);
    return child;
  }
}
