import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/editor_session.dart';
import '../../state/program_form.dart';
import '../../state/ui_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/modal_shell.dart';
import '../widgets/mini_chip.dart';
import 'part_presentation.dart';
import 'slot_field.dart';

/// Card for a program part (`.part`). A single widget: the body kind (fixed
/// line or role card) is decided by [PartView.kind], and the chairman card is
/// the same widget with a synthetic view.
class PartCard extends ConsumerWidget {
  const PartCard({super.key, required this.view});

  final PartView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    // Highlight the card that owns the open picker (accent ring).
    final active = ref.watch(activeSlotProvider.select(
      (s) => s != null && view.slots.any((spec) => spec.ref == s),
    ));

    return AnimatedContainer(
      duration: Dimens.dFast,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(Dimens.rCard),
        border: Border.all(color: active ? t.accent : t.border),
        boxShadow: active
            ? [BoxShadow(color: t.accentSoft, spreadRadius: 3)]
            : null,
      ),
      child: view.kind == PartKind.fixedLine
          ? _FixedLineBody(view: view)
          : _RoleBody(view: view),
    );
  }
}

/// Middle song / intro and conclusion words: a single line with time, title
/// and a right-hand label.
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
                      // Non-breaking spaces: "· 1 min" wraps as a unit on
                      // narrow widths.
                      text:
                          '  · ${view.durationLabel!.replaceAll(' ', ' ')}',
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

/// Card with a chip header, title and assignment slots.
class _RoleBody extends ConsumerWidget {
  const _RoleBody({required this.view});

  final PartView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    // The chairman card has no real row id, so its title isn't editable.
    // A title override is a `program` write, so it also needs the program
    // capability for this project's type.
    final editable = view.id != 'presidente' &&
        ref.watch(canEditOpenProgramProvider);
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
                MiniChip.allMeeting(context.t.workspace.allMeeting)
              else
                MiniChip.time(view.time),
              if (view.durationLabel != null)
                MiniChip.duration(view.durationLabel!),
              if (view.fixedTag != null) MiniChip.tag(view.fixedTag!),
              if (view.auxFlag) MiniChip.aux(context.t.workspace.auxRoom),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  view.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                    color: t.text,
                  ),
                ),
              ),
              if (editable) ...[
                const SizedBox(width: 8),
                _EditTitleButton(
                  onTap: () => _showEditTitleDialog(context, ref, view),
                ),
              ],
            ],
          ),
          const SizedBox(height: 11),
          _Slots(slots: view.slots),
        ],
      ),
    );
  }
}

/// Small pencil button to rename an assignment's title.
class _EditTitleButton extends StatelessWidget {
  const _EditTitleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: hovered ? t.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Tooltip(
          message: context.t.workspace.editTitle,
          child: Icon(Icons.edit_outlined,
              size: 15, color: hovered ? t.accentStrong : t.textMute),
        ),
      ),
    );
  }
}

/// Opens a compact dialog to edit (or restore) the assignment's title.
void _showEditTitleDialog(BuildContext context, WidgetRef ref, PartView view) {
  var text = view.title;
  final hasOverride =
      ref.read(formProvider).titleOverrides.containsKey(view.id);
  showAppModal<void>(
    context,
    maxWidth: 420,
    builder: (ctx, sheet, close) => ModalShell(
      sheet: sheet,
      onClose: close,
      title: ctx.t.workspace.editTitle,
      body: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: BoundTextField(
          initial: view.title,
          label: ctx.t.workspace.editTitleHint,
          maxLines: 2,
          maxLength: 140,
          onChanged: (v) => text = v,
          onSubmitted: (v) {
            ref.read(formProvider.notifier).setTitleOverride(view.id, v);
            close();
          },
        ),
      ),
      primaryLabel: ctx.t.common.saveChanges,
      onPrimary: () {
        ref.read(formProvider.notifier).setTitleOverride(view.id, text);
        close();
      },
      dangerLabel: ctx.t.workspace.restoreTitle,
      onDanger: hasOverride
          ? () {
              ref.read(formProvider.notifier).setTitleOverride(view.id, null);
              close();
            }
          : null,
    ),
  );
}

/// Slots in a row (sharing the width); on very narrow widths (≤460 in the
/// mock) they collapse to a column, one per line.
class _Slots extends StatelessWidget {
  const _Slots({required this.slots});

  final List<SlotSpec> slots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth < 340 ? 1 : 2;
        if (slots.length == 1 || perRow == 1) {
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
            for (var row = 0; row * perRow < slots.length; row++) ...[
              if (row > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < perRow; j++) ...[
                    if (j > 0) const SizedBox(width: 8),
                    Expanded(
                      child: row * perRow + j < slots.length
                          ? SlotField(spec: slots[row * perRow + j])
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
