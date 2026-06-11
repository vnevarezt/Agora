import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/program_form.dart';
import '../../state/progress_provider.dart';
import '../../state/ui_state.dart';
import '../../state/weeks_provider.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/export_button.dart';
import '../widgets/progress_ring.dart';
import '../widgets/segmented_control.dart';

/// Resumen compacto de la semana en móvil (`.ctx-mobile-summary`);
/// tocar abre/cierra el panel de configuración.
class MobileSummaryButton extends ConsumerWidget {
  const MobileSummaryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final f = ref.watch(formProvider);
    final semanas = ref.watch(weeksProvider).asData?.value ?? const [];
    final expanded = ref.watch(configExpandedProvider);
    final semana = semanas.isEmpty
        ? 'Sin cuaderno'
        : '${f.semanaIdx + 1}. ${semanas[f.semanaIdx.clamp(0, semanas.length - 1)].fecha}';

    return Pressable(
      onTap: () => ref.read(configExpandedProvider.notifier).alternar(),
      builder: (context, _, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border(bottom: BorderSide(color: t.border)),
        ),
        child: Row(
          children: [
            Icon(Icons.format_list_bulleted, size: 16, color: t.textMute),
            const SizedBox(width: 8),
            Text(
              semana,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '· ${f.cong}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.textMute,
                ),
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: Dimens.dSlide,
              child: Icon(Icons.expand_more, size: 16, color: t.textMute),
            ),
          ],
        ),
      ),
    );
  }
}

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
            .seleccionar(MobileTab.values[i]),
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
