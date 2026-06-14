import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/participant.dart';
import '../../state/participants_provider.dart';
import '../../state/program_form.dart';
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

/// Description of each role in the modal radio cards.
const _roleDesc = {
  Role.publisher:
      'Participa en "Seamos mejores maestros" (todos)',
  Role.ministerialServant:
      'Publicador + lectura, oración y algunas partes asignables',
  Role.elder: 'Puede recibir cualquier asignación del programa',
};

/// Opens the create/edit participant modal. [original] null = new.
Future<void> showParticipantModal(BuildContext context, {Participant? original}) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        PersonModal(original: original, sheet: sheet, onClose: close),
  );
}

/// Participant modal content. Reads/writes via Riverpod.
class PersonModal extends ConsumerStatefulWidget {
  const PersonModal({
    super.key,
    this.original,
    required this.onClose,
    this.sheet = false,
  });

  /// null = new.
  final Participant? original;
  final VoidCallback onClose;
  final bool sheet;

  @override
  ConsumerState<PersonModal> createState() => _PersonModalState();
}

class _PersonModalState extends ConsumerState<PersonModal> {
  late String _name = widget.original?.name ?? '';
  late Gender _gender = widget.original?.gender ?? Gender.male;
  late Role _role =
      widget.original?.role ?? Role.publisher;
  late String _congregation;
  late bool _active = widget.original?.active ?? true;
  bool _saving = false;

  /// Bump to re-seed the congregation field when tapping a chip.
  int _congVersion = 0;

  bool get _isCreating => widget.original == null;

  @override
  void initState() {
    super.initState();
    _congregation = widget.original?.congregation ?? ref.read(formProvider).congregationId;
  }

  void _setGender(Gender s) => setState(() {
        _gender = s;
        // Women only participate as publishers.
        if (s == Gender.female) _role = Role.publisher;
      });

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc();
      final h = _isCreating
          ? Participant(
              id: const Uuid().v4(),
              name: _name.trim(),
              gender: _gender,
              role: _role,
              congregation: _congregation.trim(),
              active: _active,
              notes: '',
              createdAt: now,
              updatedAt: now,
            )
          : widget.original!.copyWith(
              name: _name.trim(),
              gender: _gender,
              role: _role,
              congregation: _congregation.trim(),
              active: _active,
            );
      await ref.read(participantActionsProvider).save(h);
      widget.onClose();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar definitivamente?'),
        content: Text(
          'Se eliminará a ${widget.original!.name} del directorio. '
          'Esta acción no se puede deshacer. Las asignaciones ya escritas '
          'en programas no se ven afectadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(participantActionsProvider).delete(widget.original!.id);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: _isCreating ? 'Añadir participante' : 'Editar participante',
      desc: 'El privilegio define qué partes se le pueden asignar.',
      body: _body(context.tokens),
      primaryLabel: _isCreating ? 'Añadir participante' : 'Guardar cambios',
      primaryBusy: _saving,
      onPrimary: (_name.trim().isNotEmpty && !_saving) ? _save : null,
      onDanger: _isCreating ? null : _delete,
    );
  }

  Widget _body(AppTokens t) {
    final suggestions = ref
        .watch(participantCongregationsProvider)
        .where((c) => c != _congregation.trim())
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
          label: 'Nombre completo',
          child: BoundTextField(
            initial: _name,
            maxLength: Limits.name,
            hint: 'Ej. Martín Salas',
            onChanged: (v) => setState(() => _name = v),
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Congregación',
          child: BoundTextField(
            key: ValueKey('cong-$_congVersion'),
            initial: _congregation,
            maxLength: Limits.congregation,
            onChanged: (v) => setState(() => _congregation = v),
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
                      _congregation = c;
                      _congVersion++;
                    }),
                    builder: (context, _, _) => MiniChip.tag(c),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Es',
          child: SegmentedTabs(
            segments: const [
              (icon: null, label: 'Hombre'),
              (icon: null, label: 'Mujer'),
            ],
            index: genderIndex,
            expand: true,
            onChanged: (i) => _setGender(i == 0 ? Gender.male : Gender.female),
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Privilegio',
          child: Column(
            children: [
              for (final p in availableRoles) ...[
                if (p != availableRoles.first) const SizedBox(height: 8),
                _RoleOption(
                  role: p,
                  selected: _role == p,
                  onTap: () => setState(() => _role = p),
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

/// Role radio card (`.priv-option`): circle + title + description.
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
                      _roleDesc[role]!,
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
                'Disponible',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              Text(
                'Puede recibir asignaciones ahora mismo',
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
