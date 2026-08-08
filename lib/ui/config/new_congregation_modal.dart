import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config_options.dart';
import '../../i18n/strings.g.dart';
import '../../models/congregation_settings.dart';
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
  // Indexes, not localized labels — see the note in `congregation_tab.dart`.
  int _language = 0; // index into congregationLanguageCodes
  int _weekdayDay = 1; // Monday-first weekday index — Tuesday
  String _weekdayTime = '19:00';
  int _weekendDay = 6; // Sunday
  String _weekendTime = '10:00';

  /// Persists the congregation. The schedule/language go into settingsJson
  /// (weekday = index in the Monday-first list, stable across locales);
  /// the program templates read them in phase 2.
  Future<void> _crear() async {
    await ref.read(congregationActionsProvider).add(
          name: _name.trim(),
          number: _number.trim(),
          settings: CongregationSettings(
            meetingLanguage: congregationLanguageCodes[_language],
            midweekDay: _weekdayDay,
            midweekTime: _weekdayTime,
            weekendDay: _weekendDay,
            weekendTime: _weekendTime,
          ),
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
                child: AppDropdown<int>(
                  value: _language,
                  items: [for (var i = 0; i < meetingLanguages.length; i++) i],
                  itemLabel: (i) => meetingLanguages[i],
                  onChanged: (v) => setState(() => _language = v),
                ),
              ),
            ),
            box(
              colW,
              LabeledField(
                label: tr.congregation.weekdayDay,
                child: AppDropdown<int>(
                  value: _weekdayDay,
                  items: [for (var i = 0; i < daysOfWeek.length; i++) i],
                  itemLabel: (i) => daysOfWeek[i],
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
                child: AppDropdown<int>(
                  value: _weekendDay,
                  items: [for (var i = 0; i < daysOfWeek.length; i++) i],
                  itemLabel: (i) => daysOfWeek[i],
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
