import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/assignment_ops.dart';
import '../../state/editor_session.dart';
import '../../state/people_provider.dart';
import '../../state/program_form.dart';
import '../../state/ui_state.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../picker/person_picker.dart';
import 'assignee_button.dart';
import 'part_presentation.dart';

/// An assignment slot: uppercase label + [AssigneeButton]. Opens the picker
/// and writes the result into the form via [writeAssignment].
class SlotField extends ConsumerWidget {
  const SlotField({super.key, required this.spec});

  final SlotSpec spec;

  Future<void> _openPicker(
      BuildContext anchorContext, WidgetRef ref, String current) async {
    ref.read(activeSlotProvider.notifier).set(spec.ref);
    try {
      final result = await showPersonPicker(
        anchorContext,
        roleLabel: spec.label,
        current: current,
        maxLength: spec.maxLength,
      );
      switch (result) {
        case PickName(:final name):
          writeAssignment(ref, spec.ref, name);
          // Fire-and-forget: the directory updates itself.
          unawaited(ref.read(personActionsProvider).recordUsage(name));
        case PickRemove():
          writeAssignment(ref, spec.ref, '');
        case null:
          break;
      }
    } finally {
      ref.read(activeSlotProvider.notifier).set(null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final name =
        ref.watch(formProvider.select((f) => slotName(f, spec.ref)));
    final canEdit = ref.watch(canEditOpenProgramProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            spec.label.toUpperCase(),
            style: AppText.label(
                color: spec.accent ? t.accentStrong : t.textMute),
          ),
        ),
        // Builder: popover anchor = the button only, not the label.
        Builder(
          builder: (anchorContext) => AssigneeButton(
            name: name.isEmpty ? null : name,
            alwaysShowClear: context.isMobile,
            onTap: canEdit
                ? () => _openPicker(anchorContext, ref, name)
                : null,
            onClear: (name.isEmpty || !canEdit)
                ? null
                : () => writeAssignment(ref, spec.ref, ''),
          ),
        ),
      ],
    );
  }
}
