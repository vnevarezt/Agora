import 'package:flutter/material.dart';

import '../../data/config_sample.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';

/// Abre el modal de alta de congregación (solo UI en esta fase).
Future<void> mostrarNuevaCongregacion(BuildContext context) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        NuevaCongregacionModal(sheet: sheet, onClose: close),
  );
}

class NuevaCongregacionModal extends StatefulWidget {
  const NuevaCongregacionModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  State<NuevaCongregacionModal> createState() => _NuevaCongregacionModalState();
}

class _NuevaCongregacionModalState extends State<NuevaCongregacionModal> {
  String _nombre = '';
  String _numero = '';
  String _idioma = idiomasReunion.first;
  String _diaEntre = 'Martes';
  String _horaEntre = '19:00';
  String _diaFin = 'Domingo';
  String _horaFin = '10:00';

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: 'Nueva congregación',
      desc: 'Serás su administrador. Después podrás invitar usuarios.',
      primaryLabel: 'Crear congregación',
      onPrimary: widget.onClose, // UI-only: solo cierra
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final t = context.tokens;
    final mono = AppText.mono(size: 13.5, color: t.text);

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 16.0;
        final colW = widget.sheet ? c.maxWidth : (c.maxWidth - gap) / 2;
        Widget box(double w, Widget child) => SizedBox(width: w, child: child);

        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: [
            box(
              c.maxWidth,
              LabeledField(
                label: 'Nombre',
                child: BoundTextField(
                  initial: _nombre,
                  hint: 'Ej. Jardines del Norte',
                  onChanged: (v) => _nombre = v,
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Número',
                child: BoundTextField(
                  initial: _numero,
                  hint: 'Ej. 152423',
                  style: mono,
                  onChanged: (v) => _numero = v,
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Idioma de la reunión',
                child: AppDropdown<String>(
                  value: _idioma,
                  items: idiomasReunion,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _idioma = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Entre semana · día',
                child: AppDropdown<String>(
                  value: _diaEntre,
                  items: diasSemana,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _diaEntre = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Entre semana · hora',
                child: BoundTextField(
                  initial: _horaEntre,
                  style: mono,
                  onChanged: (v) => _horaEntre = v,
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Fin de semana · día',
                child: AppDropdown<String>(
                  value: _diaFin,
                  items: diasSemana,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _diaFin = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Fin de semana · hora',
                child: BoundTextField(
                  initial: _horaFin,
                  style: mono,
                  onChanged: (v) => _horaFin = v,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
