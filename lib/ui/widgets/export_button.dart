import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/app_settings.dart';
import '../../state/preview_provider.dart';
import '../../state/program_form.dart';
import '../../state/ui_state.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'app_modal.dart';
import 'export_actions.dart';
import 'export_panel.dart';

enum ExportVariant {
  /// Desktop project bar: icon + text, 38px.
  bar,

  /// Mobile project bar: icon only.
  compact,

  /// Mobile bottom bar: full width, 48px.
  full,
}

/// Mobile export entry point: opens a sheet to pick format (PDF / image) and
/// action (save / share). The busy state is shared via [exportBusyProvider] so
/// all instances disable together. (Desktop uses the popover menu in the
/// project bar instead.)
class ExportButton extends ConsumerWidget {
  const ExportButton({super.key, this.variant = ExportVariant.bar});

  final ExportVariant variant;

  void _openSheet(BuildContext context, WidgetRef ref) {
    final haySemana = ref.read(scheduleProvider) != null;
    final twoUp = ref.read(twoPerSheetProvider);
    showAppModal(
      context,
      builder: (ctx, sheet, close) => _ExportSheet(
        haySemana: haySemana,
        twoPerSheet: twoUp,
        onExport: (format, action, origin) {
          close();
          runExport(context, ref,
              format: format, action: action, shareOrigin: origin);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(exportBusyProvider);
    final haySemana = ref.watch(scheduleProvider) != null;

    return AppButton(
      onPressed: haySemana && !busy ? () => _openSheet(context, ref) : null,
      icon: Icons.ios_share,
      label:
          variant == ExportVariant.compact ? null : context.t.export.export,
      height: variant == ExportVariant.full
          ? Dimens.hExportMobile
          : Dimens.hControl,
      busy: busy,
      expand: variant == ExportVariant.full,
    );
  }
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({
    required this.haySemana,
    required this.twoPerSheet,
    required this.onExport,
  });

  final bool haySemana;
  final bool twoPerSheet;
  final void Function(ExportFormat, ExportAction, Rect?) onExport;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                    twoPerSheet
                        ? Icons.splitscreen_outlined
                        : Icons.description_outlined,
                    size: 20,
                    color: t.textMute),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          twoPerSheet
                              ? tr.export.currentSheet
                              : tr.export.currentWeek,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: t.text)),
                      Text(
                          twoPerSheet
                              ? tr.export.currentSheetSub
                              : tr.export.currentWeekSub,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: t.textMute)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ExportPanel(enabled: haySemana, onExport: onExport),
          ],
        ),
      ),
    );
  }
}
