import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/preview_provider.dart';
import '../../state/program_form.dart';
import '../../state/ui_state.dart';
import '../theme/dimens.dart';
import 'app_button.dart';

enum ExportVariant {
  /// Desktop project bar: icon + text, 38px.
  bar,

  /// Mobile project bar: icon only.
  compact,

  /// Mobile bottom bar: full width, 48px.
  full,
}

/// Single PDF export entry point. The busy state is shared via
/// [exportBusyProvider] so all instances disable together.
class ExportButton extends ConsumerWidget {
  const ExportButton({super.key, this.variant = ExportVariant.bar});

  final ExportVariant variant;

  Future<void> _exportar(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = context.t;
    ref.read(exportBusyProvider.notifier).set(true);
    try {
      final ruta = await ref.read(previewProvider.notifier).export();
      messenger
          .showSnackBar(SnackBar(content: Text(tr.export.success(path: ruta))));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(tr.export.error(error: e))));
    } finally {
      ref.read(exportBusyProvider.notifier).set(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(exportBusyProvider);
    final haySemana = ref.watch(scheduleProvider) != null;

    return AppButton(
      onPressed:
          haySemana && !busy ? () => _exportar(context, ref) : null,
      icon: Icons.ios_share,
      label: variant == ExportVariant.compact ? null : context.t.export.exportPdf,
      height: variant == ExportVariant.full
          ? Dimens.hExportMobile
          : Dimens.hControl,
      busy: busy,
      expand: variant == ExportVariant.full,
    );
  }
}
