import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/ui_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/mini_chip.dart';
import 'part_presentation.dart';
import 'slot_field.dart';

/// Tarjeta de una parte del programa (`.part`). Un único widget: el tipo de
/// cuerpo (línea fija o tarjeta de rol) lo decide [PartView.kind] y la
/// tarjeta del presidente es el mismo widget con una vista sintética.
class PartCard extends ConsumerWidget {
  const PartCard({super.key, required this.view});

  final PartView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    // Resalta la tarjeta dueña del picker abierto (ring accent del mock).
    final activa = ref.watch(activeSlotProvider.select(
      (s) => s != null && view.slots.any((spec) => spec.ref == s),
    ));

    return AnimatedContainer(
      duration: Dimens.dFast,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(Dimens.rCard),
        border: Border.all(color: activa ? t.accent : t.border),
        boxShadow: activa
            ? [BoxShadow(color: t.accentSoft, spreadRadius: 3)]
            : null,
      ),
      child: view.kind == PartKind.fixedLine
          ? _FixedLineBody(view: view)
          : _RoleBody(view: view),
    );
  }
}

/// Canción media / palabras de introducción y conclusión: una sola línea
/// con hora, título y label a la derecha.
class _FixedLineBody extends StatelessWidget {
  const _FixedLineBody({required this.view});

  final PartView view;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              view.time,
              textAlign: TextAlign.right,
              style: AppText.mono(size: 13, color: t.textMute),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: view.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.textDim,
                ),
                children: [
                  if (view.durationLabel != null)
                    TextSpan(
                      // Sin espacios partibles: "· 1 min" salta de línea
                      // como unidad en anchos estrechos.
                      text:
                          '  · ${view.durationLabel!.replaceAll(' ', ' ')}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: t.textMute,
                      ),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (view.fixedTag != null) ...[
            const SizedBox(width: 13),
            MiniChip.tag(view.fixedTag!),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta con cabecera de chips, título y huecos de asignación.
class _RoleBody extends StatelessWidget {
  const _RoleBody({required this.view});

  final PartView view;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (view.allMeetingBadge)
                const MiniChip.allMeeting('Toda la reunión')
              else
                MiniChip.time(view.time),
              if (view.durationLabel != null)
                MiniChip.duration(view.durationLabel!),
              if (view.fixedTag != null) MiniChip.tag(view.fixedTag!),
              if (view.auxFlag) const MiniChip.aux('Sala auxiliar'),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            view.title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
              color: t.text,
            ),
          ),
          const SizedBox(height: 11),
          _Slots(slots: view.slots),
        ],
      ),
    );
  }
}

/// Huecos en fila (se reparten el ancho); a ancho muy estrecho (≤460 del
/// mock) caen a columna, uno por línea.
class _Slots extends StatelessWidget {
  const _Slots({required this.slots});

  final List<SlotSpec> slots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final porFila = c.maxWidth < 340 ? 1 : 2;
        if (slots.length == 1 || porFila == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < slots.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SlotField(spec: slots[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var fila = 0; fila * porFila < slots.length; fila++) ...[
              if (fila > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < porFila; j++) ...[
                    if (j > 0) const SizedBox(width: 8),
                    Expanded(
                      child: fila * porFila + j < slots.length
                          ? SlotField(spec: slots[fila * porFila + j])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
