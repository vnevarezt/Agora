import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n/strings.g.dart';
import 'state/mwb_sync.dart';
import 'state/ui_state.dart';
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
      home: const _SyncBootstrap(child: AppShell()),
    );
  }
}

/// Kicks off the background notebook sync on startup without blocking or
/// rebuilding the [MaterialApp]. The sync runs once and only hits the network
/// when the cache lacks coverage for the next ~2 months.
class _SyncBootstrap extends ConsumerWidget {
  const _SyncBootstrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mwbSyncProvider);
    return child;
  }
}
