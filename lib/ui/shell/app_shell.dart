import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/ui_state.dart';
import '../config/settings_view.dart';
import '../dashboard/dashboard_view.dart';
import '../participants/participants_view.dart';
import '../responsive.dart';
import '../widgets/motion.dart';
import 'sidebar_nav.dart';

/// App root shell: side navigation + content area that switches between
/// Home (dashboard), Participants and Settings. On mobile the side bar is
/// replaced by a bottom bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = context.screenSize;
    final section = ref.watch(appSectionProvider);

    // Motion.fast: the 300 ms default cross-fade made every nav tap feel
    // sluggish — the old section stays on screen for the whole fade.
    final body = FadeThroughSwitcher(
      duration: Motion.fast,
      child: KeyedSubtree(
        key: ValueKey(section),
        child: switch (section) {
          AppSection.home => const DashboardView(),
          AppSection.participants => const ParticipantsView(),
          AppSection.settings => const SettingsView(),
        },
      ),
    );

    if (size == ScreenSize.mobile) {
      return Scaffold(
        body: SafeArea(bottom: false, child: body),
        bottomNavigationBar: const BottomNav(),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Sidebar(compact: size == ScreenSize.tablet),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
