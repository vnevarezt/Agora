import 'package:flutter/material.dart';

import '../responsive.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/segmented_control.dart';
import 'application_tab.dart';
import 'congregation_tab.dart';

/// Vista de Configuración (`SettingsView` del mock): topbar + pestañas
/// Aplicación / Congregación. Vive dentro del shell.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final pad = isMobile ? 16.0 : 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
          child: _topBar(context, isMobile),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedTabs(
                    segments: const [
                      (icon: null, label: 'Aplicación'),
                      (icon: null, label: 'Congregación'),
                    ],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                const SizedBox(height: 18),
                _tab == 0 ? const ApplicationTab() : const CongregationTab(),
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
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 19 : 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.42,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Aplicación y congregaciones',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textMute,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppIconButton(
          icon: Icons.notifications_none_rounded,
          bordered: true,
          tooltip: 'Recordatorios',
          onPressed: () {},
        ),
      ],
    );
  }
}
