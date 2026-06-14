import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config_options.dart';
import '../../state/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';

/// Opens the new-congregation modal (UI-only at this phase).
Future<void> showNewCongregation(BuildContext context) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        NewCongregationModal(sheet: sheet, onClose: close),
  );
}

class NewCongregationModal extends ConsumerStatefulWidget {
  const NewCongregationModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<NewCongregationModal> createState() =>
      _NewCongregationModalState();
}

class _NewCongregationModalState
    extends ConsumerState<NewCongregationModal> {
  String _name = '';
  String _number = '';
  String _language = meetingLanguages.first;
  String _weekdayDay = 'Martes';
  String _weekdayTime = '19:00';
  String _weekendDay = 'Domingo';
  String _weekendTime = '10:00';

  /// Adds the congregation to in-memory state and closes. Schedule/language
  /// are not persisted yet (no backend); only name and number are saved.
  void _crear() {
    ref.read(congregationsProvider.notifier).add(
          name: _name.trim(),
          number: _number.trim(),
        );
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: 'Nueva congregación',
      desc: 'Serás su administrador. Después podrás invitar usuarios.',
      primaryLabel: 'Crear congregación',
      onPrimary: _name.trim().isEmpty ? null : _crear,
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
                  initial: _name,
                  hint: 'Ej. Jardines del Norte',
                  onChanged: (v) => setState(() => _name = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Número',
                child: BoundTextField(
                  initial: _number,
                  hint: 'Ej. 152423',
                  style: mono,
                  onChanged: (v) => _number = v,
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Idioma de la reunión',
                child: AppDropdown<String>(
                  value: _language,
                  items: meetingLanguages,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _language = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Entre semana · día',
                child: AppDropdown<String>(
                  value: _weekdayDay,
                  items: daysOfWeek,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _weekdayDay = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Entre semana · hora',
                child: BoundTextField(
                  initial: _weekdayTime,
                  style: mono,
                  onChanged: (v) => _weekdayTime = v,
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Fin de semana · día',
                child: AppDropdown<String>(
                  value: _weekendDay,
                  items: daysOfWeek,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _weekendDay = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: 'Fin de semana · hora',
                child: BoundTextField(
                  initial: _weekendTime,
                  style: mono,
                  onChanged: (v) => _weekendTime = v,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
