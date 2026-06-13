import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/program_form.dart';
import '../../state/progress_provider.dart';
import '../../state/ui_state.dart';
import '../../state/weeks_provider.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../personas/hermanos_view.dart';
import '../widgets/app_button.dart';
import '../widgets/export_button.dart';
import '../widgets/progress_ring.dart';
import 'config_panel.dart';

/// Barra de contexto (`.ctxbar`): marca, resumen de la semana, progreso y
/// acciones, con el panel de configuración colapsable debajo.
class ContextBar extends ConsumerWidget {
  const ContextBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final size = context.screenSize;
    final isMobile = size == ScreenSize.mobile;
    final expanded = ref.watch(configExpandedProvider);
    final progreso = ref.watch(progressProvider);
    final esOscuro = ref.watch(themeModeProvider) == ThemeMode.dark;
    final weeks = ref.watch(weeksProvider);

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 18, vertical: isMobile ? 8 : 10),
            child: Row(
              children: [
                // Cuando el editor se abre desde el dashboard, ofrecer volver.
                if (Navigator.of(context).canPop()) ...[
                  AppIconButton(
                    icon: Icons.arrow_back,
                    bordered: true,
                    tooltip: 'Volver',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                ],
                // En tablet la marca y el anillo van compactos para dejar
                // sitio a los chips (el mock los recorta por overflow).
                _Brand(compact: size != ScreenSize.desktop),
                const SizedBox(width: 14),
                if (!isMobile)
                  Expanded(
                    child: _SummaryChips(
                        maxChips: size == ScreenSize.tablet ? 3 : 4),
                  )
                else
                  const Spacer(),
                if (!isMobile) ...[
                  const SizedBox(width: 14),
                  ProgressRing(
                    done: progreso.done,
                    total: progreso.total,
                    showLabel: size == ScreenSize.desktop,
                  ),
                ],
                const SizedBox(width: 14),
                AppIconButton(
                  icon: Icons.people_outline,
                  bordered: true,
                  tooltip: 'Hermanos',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: SafeArea(child: HermanosView()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppIconButton(
                  icon: esOscuro
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  bordered: true,
                  tooltip: 'Claro / oscuro',
                  onPressed: () =>
                      ref.read(themeModeProvider.notifier).alternar(),
                ),
                const SizedBox(width: 8),
                AppIconButton(
                  icon: Icons.settings_outlined,
                  bordered: true,
                  tooltip: 'Configuración de la semana',
                  onPressed: () =>
                      ref.read(configExpandedProvider.notifier).alternar(),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  AppIconButton(
                    icon: Icons.file_download_outlined,
                    bordered: true,
                    tooltip: 'Descargar guía del cuaderno',
                    onPressed: weeks.isLoading
                        ? null
                        : () => ref
                            .read(weeksProvider.notifier)
                            .cargar(ref.read(formProvider).issue),
                  ),
                ],
                const SizedBox(width: 8),
                ExportButton(
                  variant:
                      isMobile ? ExportVariant.compact : ExportVariant.bar,
                ),
              ],
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: Dimens.dSlide,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? const ConfigPanel()
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marca "JW · Programa · Vida y Ministerio" (`.brand`).
class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            'JW',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.accentInk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            text: 'Programa',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: t.text,
            ),
            children: [
              if (!compact)
                TextSpan(
                  text: ' · Vida y Ministerio',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chips resumen Cuaderno/Semana/Inicio/Congregación; clic = abrir config.
class _SummaryChips extends ConsumerWidget {
  const _SummaryChips({required this.maxChips});

  final int maxChips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(formProvider);
    final semanas = ref.watch(weeksProvider).asData?.value ?? const [];
    final semana = semanas.isEmpty
        ? '—'
        : '${f.semanaIdx + 1}. ${semanas[f.semanaIdx.clamp(0, semanas.length - 1)].fecha}';

    final chips = [
      (k: 'Cuaderno', v: f.issue),
      (k: 'Semana', v: semana),
      (k: 'Inicio', v: f.inicio),
      (k: 'Congregación', v: f.cong),
    ].take(maxChips).toList();

    return Pressable(
      onTap: () => ref.read(configExpandedProvider.notifier).alternar(),
      tooltip: 'Editar configuración',
      builder: (context, _, _) => Row(
        children: [
          for (var i = 0; i < chips.length; i++)
            Flexible(
              child: _CtxChip(
                k: chips[i].k,
                v: chips[i].v,
                first: i == 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _CtxChip extends StatelessWidget {
  const _CtxChip({required this.k, required this.v, this.first = false});

  final String k;
  final String v;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(left: BorderSide(color: t.border2)),
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(color: t.textMute),
          ),
          const SizedBox(height: 1),
          Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
        ],
      ),
    );
  }
}
