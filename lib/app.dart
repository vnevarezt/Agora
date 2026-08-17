import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'i18n/strings.g.dart';
import 'state/app_settings.dart';
import 'state/locale_boot.dart';
import 'state/mwb_sync.dart';
import 'state/sync_controller.dart';
import 'ui/auth/auth_gate.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/tokens.dart';

/// Both entry points land on the app itself. The marketing page that used to
/// answer `/` on the web is now static HTML served ahead of this bundle — see
/// site/ and tool/build_site.sh — so nothing here has to decide whether a
/// visitor wants the product or the pitch. `/login` stays a distinct URL
/// because the landing's "sign in" links straight at it.
final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const _AppRoot()),
    GoRoute(path: '/login', builder: (context, state) => const _AppRoot()),
  ],
);

class AgoraApp extends ConsumerWidget {
  const AgoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Agora',
      debugShowCheckedModeBanner: false,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: [for (final l in shippedLocales) l.flutterLocale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(pizarra.light, Brightness.light),
      darkTheme: buildAppTheme(pizarra.dark, Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: _router,
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return const AuthGate(child: _SyncBootstrap(child: AppShell()));
  }
}

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
