import '../theme/dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/ui_state.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/segmented_control.dart';
import 'application_tab.dart';
import 'congregation_tab.dart';

/// Settings view (`SettingsView`): topbar + Application / Congregation
/// tabs. Lives inside the shell.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(settingsTabProvider);
    final isMobile = context.isMobile;
    final pad = isMobile ? 16.0 : 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, Space.s14, pad, 0),
          child: _topBar(context, isMobile),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, Space.s18, pad, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedTabs(
                    segments: [
                      (icon: null, label: context.t.settings.tabApp),
                      (icon: null, label: context.t.settings.tabCongregation),
                    ],
                    index: tab.index,
                    onChanged: (i) => ref
                        .read(settingsTabProvider.notifier)
                        .select(SettingsTab.values[i]),
                  ),
                ),
                const SizedBox(height: Space.s18),
                tab == SettingsTab.app
                    ? const ApplicationTab()
                    : const CongregationTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, bool isMobile) {
    final t = context.tokens;
    return Row(
      children: [
        if (Navigator.of(context).canPop()) ...[
          AppIconButton(
            icon: Icons.arrow_back,
            bordered: true,
            tooltip: context.t.common.back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: Space.s12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.settings.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? AppText.display : AppText.displayLarge,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.42,
                  color: t.text,
                ),
              ),
              const SizedBox(height: Space.s2),
              Text(
                context.t.settings.subtitle,
                style: TextStyle(
                  fontSize: AppText.body,
                  fontWeight: FontWeight.w600,
                  color: t.textMute,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Space.s12),
        AppIconButton(
          icon: Icons.notifications_none_rounded,
          bordered: true,
          tooltip: context.t.common.reminders,
          onPressed: () {},
        ),
      ],
    );
  }
}
