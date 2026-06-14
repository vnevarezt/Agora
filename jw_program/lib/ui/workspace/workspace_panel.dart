import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/program_row.dart';
import '../../models/week.dart';
import '../../state/assignment_ops.dart';
import '../../state/program_form.dart';
import '../../state/weeks_provider.dart';
import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/section_header.dart';
import 'part_card.dart';
import 'part_presentation.dart';

/// Columna de asignaciones: tarjeta del presidente + las cuatro secciones
/// del programa. Estado vacío con CTA de descarga cuando no hay cuaderno.
class WorkspacePanel extends ConsumerWidget {
  const WorkspacePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sched = ref.watch(scheduleProvider);
    if (sched == null) return const _EmptyState();

    final aux = ref.watch(formProvider.select((f) => f.aux));
    final isMobile = context.isMobile;
    final lado = isMobile ? 14.0 : 18.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(lado, lado, lado, isMobile ? 150 : 120),
      children: [
        PartCard(view: presidenteView()),
        const SizedBox(height: 22),
        _SectionBlock(title: 'Apertura', rows: sched.apertura, aux: aux),
        _SectionBlock(
          title: 'Tesoros de la Biblia',
          dotColor: kSectionColors[Section.treasures],
          rows: sched.tesoros,
          aux: aux,
        ),
        _SectionBlock(
          title: 'Seamos mejores maestros',
          dotColor: kSectionColors[Section.ministry],
          rows: sched.seamos,
          aux: aux,
        ),
        _SectionBlock(
          title: 'Nuestra vida cristiana',
          dotColor: kSectionColors[Section.christianLife],
          rows: sched.vida,
          aux: aux,
        ),
      ],
    );
  }
}

/// Una sección del programa: cabecera con contador propio + sus tarjetas.
class _SectionBlock extends ConsumerWidget {
  const _SectionBlock({
    required this.title,
    this.dotColor,
    required this.rows,
    required this.aux,
  });

  final String title;
  final Color? dotColor;
  final List<ProgramRow> rows;
  final bool aux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(formProvider);
    var total = 0;
    var done = 0;
    for (final row in rows) {
      total += row.slots;
      done += filledNames(f.principal[row.id], row.slots);
      if (aux && row.auxSlots > 0) {
        total += row.auxSlots;
        done += filledNames(f.auxiliar[row.id], row.auxSlots);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
              title: title, dotColor: dotColor, done: done, total: total),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            PartCard(view: mapRow(rows[i], auxActivo: aux)),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final weeks = ref.watch(weeksProvider);
    final issue = ref.watch(formProvider.select((f) => f.issue));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 40, color: t.textMute),
            const SizedBox(height: 14),
            Text(
              'Descarga un cuaderno para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
            ),
            const SizedBox(height: 4),
            Text(
              'El programa de la semana se generará automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.textMute),
            ),
            const SizedBox(height: 18),
            AppButton(
              icon: Icons.file_download_outlined,
              label: 'Descargar cuaderno $issue',
              busy: weeks.isLoading,
              onPressed: weeks.isLoading
                  ? null
                  : () => ref
                      .read(weeksProvider.notifier)
                      .load(ref.read(formProvider).issue),
            ),
            if (weeks.hasError) ...[
              const SizedBox(height: 14),
              Text(
                '${weeks.error}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
