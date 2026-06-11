import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/preview_provider.dart';
import '../../state/program_form.dart';
import '../../state/ui_state.dart';
import '../theme/dimens.dart';
import 'app_button.dart';

enum ExportVariant {
  /// Barra de contexto en escritorio: icono + texto, 38px.
  bar,

  /// Barra de contexto en móvil: solo icono.
  compact,

  /// Bottom bar móvil: ancho completo, 48px.
  full,
}

/// Único punto de exportación del PDF. El estado ocupado se comparte vía
/// [exportBusyProvider] para que todas las instancias se deshabiliten juntas.
class ExportButton extends ConsumerWidget {
  const ExportButton({super.key, this.variant = ExportVariant.bar});

  final ExportVariant variant;

  Future<void> _exportar(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    ref.read(exportBusyProvider.notifier).set(true);
    try {
      final ruta = await ref.read(previewProvider.notifier).exportar();
      messenger.showSnackBar(SnackBar(content: Text('PDF exportado: $ruta')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
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
      label: variant == ExportVariant.compact ? null : 'Exportar PDF',
      height: variant == ExportVariant.full
          ? Dimens.hExportMobile
          : Dimens.hControl,
      busy: busy,
      expand: variant == ExportVariant.full,
    );
  }
}
