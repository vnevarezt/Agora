import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/program_form.dart';
import '../../state/weeks_provider.dart';
import '../limites.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';

/// "1 h 45 min" a partir de minutos.
String formatoDuracion(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

/// Panel de configuración colapsable bajo la barra de contexto (`.config`):
/// cuaderno, semana, inicio, duración calculada, congregación, sala
/// auxiliar y descarga del cuaderno. Grid fluida según el ancho.
class ConfigPanel extends ConsumerWidget {
  const ConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final form = ref.read(formProvider); // siembra inicial de los inputs
    final notifier = ref.read(formProvider.notifier);
    final weeks = ref.watch(weeksProvider);
    final semanas = weeks.asData?.value ?? const [];
    final semanaIdx = ref.watch(formProvider.select((f) => f.semanaIdx));
    final auxOn = ref.watch(formProvider.select((f) => f.aux));
    final sched = ref.watch(scheduleProvider);

    final mono = AppText.mono(size: 13.5, color: t.text);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border2)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          const gapX = 20.0;
          final cols = (c.maxWidth / 210).floor().clamp(1, 5);
          final colW = (c.maxWidth - (cols - 1) * gapX) / cols;
          final dobleW = cols >= 2 ? colW * 2 + gapX : colW;

          return Wrap(
            spacing: gapX,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: colW,
                child: LabeledField(
                  label: 'Cuaderno (issue)',
                  child: BoundTextField(
                    initial: form.issue,
                    style: mono,
                    onChanged: notifier.setIssue,
                  ),
                ),
              ),
              SizedBox(
                width: colW,
                child: LabeledField(
                  label: 'Semana',
                  child: AppDropdown<int>(
                    value: semanas.isEmpty
                        ? null
                        : semanaIdx.clamp(0, semanas.length - 1),
                    items: [for (var i = 0; i < semanas.length; i++) i],
                    itemLabel: (i) => '${i + 1}. ${semanas[i].fecha}',
                    onChanged:
                        semanas.isEmpty ? null : notifier.seleccionarSemana,
                  ),
                ),
              ),
              SizedBox(
                width: colW,
                child: LabeledField(
                  label: 'Inicio',
                  child: BoundTextField(
                    initial: form.inicio,
                    style: mono,
                    hint: '18:00',
                    onChanged: notifier.setInicio,
                  ),
                ),
              ),
              SizedBox(
                width: colW,
                child: LabeledField(
                  label: 'Duración total',
                  child: ReadonlyField(
                    texto:
                        sched != null ? formatoDuracion(sched.realMin) : '—',
                  ),
                ),
              ),
              SizedBox(
                width: dobleW,
                child: LabeledField(
                  label: 'Congregación',
                  child: BoundTextField(
                    initial: form.cong,
                    maxLength: Limites.cong,
                    onChanged: notifier.setCong,
                  ),
                ),
              ),
              SizedBox(
                width: colW,
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(value: auxOn, onChanged: notifier.setAux),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Sala Auxiliar',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: auxOn ? t.text : t.textDim,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: colW,
                child: AppButton(
                  variant: AppButtonVariant.ghost,
                  icon: Icons.file_download_outlined,
                  label: 'Descargar',
                  busy: weeks.isLoading,
                  onPressed: weeks.isLoading
                      ? null
                      : () => ref
                          .read(weeksProvider.notifier)
                          .cargar(ref.read(formProvider).issue),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
