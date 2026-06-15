import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config_options.dart';
import '../../i18n/strings.g.dart';
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
  String _weekdayDay = daysOfWeek[1]; // Tuesday
  String _weekdayTime = '19:00';
  String _weekendDay = daysOfWeek[6]; // Sunday
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
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.newCongregation.title,
      desc: tr.newCongregation.desc,
      primaryLabel: tr.newCongregation.create,
      onPrimary: _name.trim().isEmpty ? null : _crear,
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
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
                label: tr.newCongregation.name,
                child: BoundTextField(
                  initial: _name,
                  hint: tr.newCongregation.nameHint,
                  onChanged: (v) => setState(() => _name = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: tr.newCongregation.number,
                child: BoundTextField(
                  initial: _number,
                  hint: tr.newCongregation.numberHint,
                  style: mono,
                  onChanged: (v) => _number = v,
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: tr.congregation.meetingLanguage,
                child: AppDropdown<String>(
                  value: meetingLanguages.contains(_language)
                      ? _language
                      : meetingLanguages.first,
                  items: meetingLanguages,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _language = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: tr.congregation.weekdayDay,
                child: AppDropdown<String>(
                  value: daysOfWeek.contains(_weekdayDay)
                      ? _weekdayDay
                      : daysOfWeek[1],
                  items: daysOfWeek,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _weekdayDay = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: tr.congregation.weekdayTime,
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
                label: tr.congregation.weekendDay,
                child: AppDropdown<String>(
                  value: daysOfWeek.contains(_weekendDay)
                      ? _weekendDay
                      : daysOfWeek[6],
                  items: daysOfWeek,
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _weekendDay = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: tr.congregation.weekendTime,
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
