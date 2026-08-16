import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'i18n/strings.g.dart';
import 'state/app_settings.dart';
import 'state/auth_session.dart';
import 'state/locale_boot.dart';
import 'state/mwb_sync.dart';
import 'state/sync_controller.dart';
import 'ui/auth/auth_gate.dart';
import 'ui/landing/landing_page.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/tokens.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const _RootRoute()),
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

class _RootRoute extends ConsumerWidget {
  const _RootRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return const _AppRoot();
    final session = ref.watch(authSessionProvider);
    if (session is SessionFreshChoose) {
      return LandingPage(onEnterApp: () => context.go('/login'));
    }
    return const _AppRoot();
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
