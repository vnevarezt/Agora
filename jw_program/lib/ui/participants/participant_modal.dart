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
import '../widgets/danger_button.dart';
import '../widgets/labeled_field.dart';
import '../widgets/mini_chip.dart';
import '../widgets/segmented_control.dart';

/// Descripción de cada privilegio en las radio-cards del modal.
const _roleDesc = {
  Role.publicador:
      'Participa en "Seamos mejores maestros" (hermanos y hermanas)',
  Role.siervoMinisterial:
      'Publicador + lectura, oración y algunas partes asignables',
  Role.anciano: 'Puede recibir cualquier asignación del programa',
};

/// Abre el modal de alta/edición de hermano. [original] null = alta nueva.
Future<void> showParticipantModal(BuildContext context, {Participant? original}) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        PersonModal(original: original, sheet: sheet, onClose: close),
  );
}

/// Contenido del modal de hermano. Lee/escribe vía Riverpod.
class PersonModal extends ConsumerStatefulWidget {
  const PersonModal({
    super.key,
    this.original,
    required this.onClose,
    this.sheet = false,
  });

  /// null = alta nueva.
  final Participant? original;
  final VoidCallback onClose;
  final bool sheet;

  @override
  ConsumerState<PersonModal> createState() => _PersonModalState();
}

class _PersonModalState extends ConsumerState<PersonModal> {
  late String _nombre = widget.original?.nombre ?? '';
  late Gender _sexo = widget.original?.sexo ?? Gender.hombre;
  late Role _privilegio =
      widget.original?.privilegio ?? Role.publicador;
  late String _congregacion;
  late bool _activo = widget.original?.activo ?? true;
  bool _guardando = false;

  /// Bump para re-sembrar el campo de congregación al tocar un chip.
  int _congVersion = 0;

  bool get _isCreating => widget.original == null;

  @override
  void initState() {
    super.initState();
    _congregacion = widget.original?.congregacion ?? ref.read(formProvider).cong;
  }

  void _setGender(Gender s) => setState(() {
        _sexo = s;
        // Las hermanas solo participan como publicadoras.
        if (s == Gender.mujer) _privilegio = Role.publicador;
      });

  Future<void> _save() async {
    setState(() => _guardando = true);
    try {
      final ahora = DateTime.now().toUtc();
      final h = _isCreating
          ? Participant(
              id: const Uuid().v4(),
              nombre: _nombre.trim(),
              sexo: _sexo,
              privilegio: _privilegio,
              congregacion: _congregacion.trim(),
              activo: _activo,
              notas: '',
              createdAt: ahora,
              updatedAt: ahora,
            )
          : widget.original!.copyWith(
              nombre: _nombre.trim(),
              sexo: _sexo,
              privilegio: _privilegio,
              congregacion: _congregacion.trim(),
              activo: _activo,
            );
      await ref.read(participantActionsProvider).guardar(h);
      widget.onClose();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _delete() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar definitivamente?'),
        content: Text(
          'Se eliminará a ${widget.original!.nombre} del directorio. '
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
    if (confirmado != true || !mounted) return;
    await ref.read(participantActionsProvider).eliminar(widget.original!.id);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.sheet) _handle(t),
        _header(t),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: _body(t),
          ),
        ),
        _footer(t),
      ],
    );

    if (widget.sheet) return card;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 12)),
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: card,
    );
  }

  Widget _handle(AppTokens t) => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      );

  Widget _header(AppTokens t) => Padding(
        padding: EdgeInsets.fromLTRB(18, widget.sheet ? 12 : 18, 12, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCreating ? 'Añadir hermano' : 'Editar hermano',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'El privilegio define qué partes se le pueden asignar.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: t.textMute,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppIconButton(
              icon: Icons.close,
              bordered: true,
              tooltip: 'Cerrar',
              size: 32,
              onPressed: widget.onClose,
            ),
          ],
        ),
      );

  Widget _body(AppTokens t) {
    final sugerencias = ref
        .watch(participantCongregationsProvider)
        .where((c) => c != _congregacion.trim())
        .take(3)
        .toList();
    final sexoIdx =
        switch (_sexo) { Gender.hombre => 0, Gender.mujer => 1, _ => -1 };
    final privsDisponibles = _sexo == Gender.mujer
        ? const [Role.publicador]
        : Role.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Nombre completo',
          child: BoundTextField(
            initial: _nombre,
            maxLength: Limites.nombre,
            hint: 'Ej. Martín Salas',
            onChanged: (v) => setState(() => _nombre = v),
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Congregación',
          child: BoundTextField(
            key: ValueKey('cong-$_congVersion'),
            initial: _congregacion,
            maxLength: Limites.cong,
            onChanged: (v) => setState(() => _congregacion = v),
          ),
        ),
        if (sugerencias.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in sugerencias)
                  Pressable(
                    onTap: () => setState(() {
                      _congregacion = c;
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
            index: sexoIdx,
            expand: true,
            onChanged: (i) => _setGender(i == 0 ? Gender.hombre : Gender.mujer),
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Privilegio',
          child: Column(
            children: [
              for (final p in privsDisponibles) ...[
                if (p != privsDisponibles.first) const SizedBox(height: 8),
                _RoleOption(
                  privilegio: p,
                  selected: _privilegio == p,
                  onTap: () => setState(() => _privilegio = p),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AvailableRow(
          activo: _activo,
          onChanged: (v) => setState(() => _activo = v),
        ),
      ],
    );
  }

  Widget _footer(AppTokens t) {
    final puedeGuardar = _nombre.trim().isNotEmpty && !_guardando;
    final primary = _isCreating ? 'Añadir hermano' : 'Guardar cambios';

    final children = widget.sheet
        ? [
            AppButton(
              label: primary,
              expand: true,
              busy: _guardando,
              height: Dimens.hExportMobile,
              onPressed: puedeGuardar ? _save : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    variant: AppButtonVariant.ghost,
                    label: 'Cancelar',
                    expand: true,
                    onPressed: widget.onClose,
                  ),
                ),
                if (!_isCreating) ...[
                  const SizedBox(width: 8),
                  DangerButton(onTap: _delete),
                ],
              ],
            ),
          ]
        : [
            Row(
              children: [
                if (!_isCreating) DangerButton(onTap: _delete),
                const Spacer(),
                AppButton(
                  variant: AppButtonVariant.ghost,
                  label: 'Cancelar',
                  onPressed: widget.onClose,
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: primary,
                  busy: _guardando,
                  onPressed: puedeGuardar ? _save : null,
                ),
              ],
            ),
          ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        widget.sheet ? 12 + MediaQuery.paddingOf(context).bottom : 12,
      ),
      decoration: BoxDecoration(
        color: t.surface2,
        border: Border(top: BorderSide(color: t.border2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Radio-card de privilegio (`.priv-option`): círculo + título + descripción.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.privilegio,
    required this.selected,
    required this.onTap,
  });

  final Role privilegio;
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
                      privilegio.etiqueta,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _roleDesc[privilegio]!,
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

/// Fila "Disponible" con switch (`.set-row`): mapea a `activo`.
class _AvailableRow extends StatelessWidget {
  const _AvailableRow({required this.activo, required this.onChanged});

  final bool activo;
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
          child: Switch(value: activo, onChanged: onChanged),
        ),
      ],
    );
  }
}
