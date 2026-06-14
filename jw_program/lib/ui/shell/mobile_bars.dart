import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/progress_provider.dart';
import '../../state/ui_state.dart';
import '../theme/tokens.dart';
import '../widgets/export_button.dart';
import '../widgets/progress_ring.dart';
import '../widgets/segmented_control.dart';

/// Pestañas Asignar / Vista previa (`.mobile-tabs`).
class MobileTabs extends ConsumerWidget {
  const MobileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tab = ref.watch(mobileTabProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: SegmentedTabs(
        expand: true,
        index: tab.index,
        segments: const [
          (icon: Icons.edit_outlined, label: 'Asignar'),
          (icon: Icons.description_outlined, label: 'Vista previa'),
        ],
        onChanged: (i) => ref
            .read(mobileTabProvider.notifier)
            .select(MobileTab.values[i]),
      ),
    );
  }
}

/// Barra inferior fija de móvil (`.bottom-bar`): vidrio esmerilado con el
/// anillo de progreso y el botón Exportar a lo ancho.
class MobileBottomBar extends ConsumerWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final progreso = ref.watch(progressProvider);
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + safeBottom),
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.88),
            border: Border(top: BorderSide(color: t.border)),
          ),
          child: Row(
            children: [
              ProgressRing(done: progreso.done, total: progreso.total),
              const SizedBox(width: 12),
              const Expanded(
                child: ExportButton(variant: ExportVariant.full),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
