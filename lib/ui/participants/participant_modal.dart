import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../i18n/strings.g.dart';
import '../../models/person.dart';
import '../../state/people_provider.dart';
import '../limits.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import '../widgets/mini_chip.dart';
import '../widgets/segmented_control.dart';

/// Description of each privilege in the modal radio cards.
String _roleDesc(Role role) => switch (role) {
      Role.publisher => t.participantModal.roleDescPublisher,
      Role.ministerialServant => t.participantModal.roleDescServant,
      Role.elder => t.participantModal.roleDescElder,
    };

/// Opens the create/edit person modal. [original] null = new.
Future<void> showParticipantModal(BuildContext context, {Person? original}) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        PersonModal(original: original, sheet: sheet, onClose: close),
  );
}

/// Person modal content. Reads/writes via Riverpod.
class PersonModal extends ConsumerStatefulWidget {
  const PersonModal({
    super.key,
    this.original,
    required this.onClose,
    this.sheet = false,
  });

  /// null = new.
  final Person? original;
  final VoidCallback onClose;
  final bool sheet;

  @override
  ConsumerState<PersonModal> createState() => _PersonModalState();
}

class _PersonModalState extends ConsumerState<PersonModal> {
  late String _displayName = widget.original?.displayName ?? '';
  late String _firstName = widget.original?.firstName ?? '';
  late String _lastName = widget.original?.lastName ?? '';
  late Gender _gender = widget.original?.gender ?? Gender.male;
  late Role _privilege = widget.original?.privilege ?? Role.publisher;

  /// Origin congregation: only for visitors, '' = local member.
  late String _origin = widget.original?.originCongregation ?? '';
  late bool _active = widget.original?.active ?? true;
  bool _saving = false;

  /// Bump to re-seed the congregation field when tapping a chip.
  int _congVersion = 0;

  bool get _isCreating => widget.original == null;

  void _setGender(Gender s) => setState(() {
        _gender = s;
        // Women only participate as publishers.
        if (s == Gender.female) _privilege = Role.publisher;
      });

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc();
      final h = _isCreating
          ? Person(
              id: const Uuid().v4(),
              // Resolved to the default congregation by the repository.
              congregationId: '',
              firstName: _firstName.trim(),
              lastName: _lastName.trim(),
              displayName: _displayName.trim(),
              gender: _gender,
              privilege: _privilege,
              qualifications: const [],
              originCongregation: _origin.trim(),
              active: _active,
              notes: '',
              createdAt: now,
              updatedAt: now,
            )
          : widget.original!.copyWith(
              firstName: _firstName.trim(),
              lastName: _lastName.trim(),
              displayName: _displayName.trim(),
              gender: _gender,
              privilege: _privilege,
              originCongregation: _origin.trim(),
              active: _active,
            );
      await ref.read(personActionsProvider).save(h);
      widget.onClose();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.participantModal.deleteTitle),
        content: Text(
          context.t.participantModal
              .deleteConfirm(name: widget.original!.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.t.common.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(personActionsProvider).delete(widget.original!.id);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: _isCreating
          ? tr.participantModal.addTitle
          : tr.participantModal.editTitle,
      desc: tr.participantModal.desc,
      body: _body(context.tokens, tr),
      primaryLabel:
          _isCreating ? tr.participantModal.addTitle : tr.common.saveChanges,
      primaryBusy: _saving,
      onPrimary: (_displayName.trim().isNotEmpty && !_saving) ? _save : null,
      onDanger: _isCreating ? null : _delete,
    );
  }

  Widget _body(AppTokens t, Translations tr) {
    final suggestions = ref
        .watch(originCongregationsProvider)
        .where((c) => c != _origin.trim())
        .take(3)
        .toList();
    final genderIndex =
        switch (_gender) { Gender.male => 0, Gender.female => 1, _ => -1 };
    final availableRoles = _gender == Gender.female
        ? const [Role.publisher]
        : Role.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: tr.participantModal.fullName,
          child: BoundTextField(
            initial: _displayName,
            maxLength: Limits.name,
            hint: tr.participantModal.nameHint,
            onChanged: (v) => setState(() => _displayName = v),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledField(
                label: tr.participantModal.firstName,
                child: BoundTextField(
                  initial: _firstName,
                  maxLength: Limits.name,
                  onChanged: (v) => setState(() => _firstName = v),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LabeledField(
                label: tr.participantModal.lastName,
                child: BoundTextField(
                  initial: _lastName,
                  maxLength: Limits.name,
                  onChanged: (v) => setState(() => _lastName = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: tr.participantModal.congregation,
          child: BoundTextField(
            key: ValueKey('cong-$_congVersion'),
            initial: _origin,
            maxLength: Limits.congregation,
            hint: tr.participantModal.originHint,
            onChanged: (v) => setState(() => _origin = v),
          ),
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in suggestions)
                  Pressable(
                    onTap: () => setState(() {
                      _origin = c;
                      _congVersion++;
                    }),
                    builder: (context, _, _) => MiniChip.tag(c),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        LabeledField(
          label: tr.participantModal.isLabel,
          child: SegmentedTabs(
            segments: [
              (icon: null, label: tr.participantModal.male),
              (icon: null, label: tr.participantModal.female),
            ],
            index: genderIndex,
            expand: true,
            onChanged: (i) => _setGender(i == 0 ? Gender.male : Gender.female),
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: tr.participantModal.privilege,
          child: Column(
            children: [
              for (final p in availableRoles) ...[
                if (p != availableRoles.first) const SizedBox(height: 8),
                _RoleOption(
                  role: p,
                  selected: _privilege == p,
                  onTap: () => setState(() => _privilege = p),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AvailableRow(
          active: _active,
          onChanged: (v) => setState(() => _active = v),
        ),
      ],
    );
  }

}

/// Privilege radio card (`.priv-option`): circle + title + description.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final Role role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        return AnimatedContainer(
          duration: Dimens.dFast,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? t.accentTint : t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? t.accent : (hovered ? t.accent : t.border),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? t.accent : t.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: t.accent,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _roleDesc(role),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: t.textMute,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Disponible" row with a switch (`.set-row`): maps to `active`.
class _AvailableRow extends StatelessWidget {
  const _AvailableRow({required this.active, required this.onChanged});

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.participantModal.available,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              Text(
                context.t.participantModal.availableDesc,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textMute,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Transform.scale(
          scale: 0.85,
          child: Switch(value: active, onChanged: onChanged),
        ),
      ],
    );
  }
}
