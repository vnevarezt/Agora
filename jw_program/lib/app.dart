import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/ui_state.dart';
import 'ui/shell/program_shell.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/tokens.dart';

class JwProgramApp extends ConsumerWidget {
  const JwProgramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'JW Program',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(pizarra.light, Brightness.light),
      darkTheme: buildAppTheme(pizarra.dark, Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      home: const ProgramShell(),
    );
  }
}
