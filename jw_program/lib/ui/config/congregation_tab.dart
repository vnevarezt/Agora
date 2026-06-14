import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config_options.dart';
import '../../models/congregation.dart';
import '../../state/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/dashed_border.dart';
import '../widgets/labeled_field.dart';
import 'invite_user_modal.dart';
import 'new_congregation_modal.dart';
import 'settings_card.dart';
import 'user_row.dart';

/// Pestaña "Congregación" de Configuración. Selector de congregación + datos,
/// horarios y usuarios. Solo-UI: estado local sembrado de datos de ejemplo.
class CongregationTab extends ConsumerStatefulWidget {
  const CongregationTab({super.key});

  @override
  ConsumerState<CongregationTab> createState() => _CongregationTabState();
}

class _CongregationTabState extends ConsumerState<CongregationTab> {
  String? _congregationId;
  String _name = '';
  String _number = '';
  String _language = meetingLanguages.first;
  String _weekdayDay = 'Martes';
  String _weekdayTime = '19:00';
  String _weekendDay = 'Domingo';
  String _weekendTime = '10:00';
  bool _auxRoom = false;

  /// Selecciona una congregación y siembra los campos. Los horarios aún no se
  /// persisten (sin backend): se muestran con valores por defecto.
  void _select(Congregation congregation, {bool notify = true}) {
    void apply() {
      _congregationId = congregation.id;
      _name = congregation.name;
      _number = congregation.number;
      _language = meetingLanguages.first;
      _weekdayDay = 'Martes';
      _weekdayTime = '19:00';
      _weekendDay = 'Domingo';
      _weekendTime = '10:00';
      _auxRoom = false;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  @override
  Widget build(BuildContext context) {
    final congregations = ref.watch(congregationsProvider);

    // Mantener una selección válida (la list cambia en memoria).
    if (congregations.isEmpty) {
      _congregationId = null;
    } else if (_congregationId == null || !congregations.any((c) => c.id == _congregationId)) {
      _select(congregations.first, notify: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _congregationSelector(congregations),
        const SizedBox(height: 16),
        if (congregations.isEmpty)
          _empty(context)
        else
          SettingsColumns(
            left: [_dataCard(), _scheduleCard()],
            right: [_usersCard()],
          ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return const EmptyState(
      icon: Icons.apartment_outlined,
      message: 'Aún no hay congregaciones.\n'
          'Crea la primera con "Nueva congregación".',
    );
  }

  Widget _congregationSelector(List<Congregation> congregations) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in congregations)
          _CongregationChip(
            congregation: c,
            acceso: '',
            active: _congregationId == c.id,
            onTap: () => _select(c),
          ),
        _AddChip(onTap: () => showNewCongregation(context)),
      ],
    );
  }

  Widget _dataCard() {
    final t = context.tokens;
    return SettingsCard(
      title: 'Datos de la congregación',
      desc: 'Se usan en el encabezado de los programas.',
      children: [
        SettingsGrid(
          children: [
            LabeledField(
              label: 'Nombre',
              child: BoundTextField(
                key: ValueKey('$_congregationId-name'),
                initial: _name,
                onChanged: (v) => _name = v,
              ),
            ),
            LabeledField(
              label: 'Número',
              child: BoundTextField(
                key: ValueKey('$_congregationId-number'),
                initial: _number,
                style: AppText.mono(size: 13.5, color: t.text),
                onChanged: (v) => _number = v,
              ),
            ),
            LabeledField(
              label: 'Idioma de la reunión',
              child: AppDropdown<String>(
                value: _language,
                items: meetingLanguages,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _language = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scheduleCard() {
    final t = context.tokens;
    final mono = AppText.mono(size: 13.5, color: t.text);
    return SettingsCard(
      title: 'Horarios de reunión',
      desc: 'Las horas de cada parte se calculan a partir de aquí.',
      children: [
        SettingsGrid(
          children: [
            LabeledField(
              label: 'Entre semana · día',
              child: AppDropdown<String>(
                value: _weekdayDay,
                items: daysOfWeek,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _weekdayDay = v),
              ),
            ),
            LabeledField(
              label: 'Entre semana · hora',
              child: BoundTextField(
                key: ValueKey('$_congregationId-he'),
                initial: _weekdayTime,
                style: mono,
                onChanged: (v) => _weekdayTime = v,
              ),
            ),
            LabeledField(
              label: 'Fin de semana · día',
              child: AppDropdown<String>(
                value: _weekendDay,
                items: daysOfWeek,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _weekendDay = v),
              ),
            ),
            LabeledField(
              label: 'Fin de semana · hora',
              child: BoundTextField(
                key: ValueKey('$_congregationId-hf'),
                initial: _weekendTime,
                style: mono,
                onChanged: (v) => _weekendTime = v,
              ),
            ),
          ],
        ),
        SettingRow(
          title: 'Sala auxiliar',
          subtitle: 'Activa una segunda sala para estudiantes por defecto',
          trailing: Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _auxRoom,
              onChanged: (v) => setState(() => _auxRoom = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _usersCard() {
    final t = context.tokens;
    return SettingsCard(
      title: 'Usuarios con acceso',
      desc: 'Quién puede ver o editar los proyectos de esta congregación.',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Aún no hay usuarios invitados.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.textMute,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            variant: AppButtonVariant.ghost,
            icon: Icons.person_add_alt,
            label: 'Invitar usuario',
            onPressed: () => showInviteUser(context),
          ),
        ),
      ],
    );
  }
}

/// Chip selector de congregación: punto de color + name + pill de rol.
class _CongregationChip extends StatelessWidget {
  const _CongregationChip({
    required this.congregation,
    required this.acceso,
    required this.active,
    required this.onTap,
  });

  final Congregation congregation;
  final String acceso;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        final fg = active ? t.accentInk : (hovered ? t.text : t.textDim);
        return AnimatedContainer(
          duration: Dimens.dFast,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: active ? t.accent : t.surface,
            borderRadius: BorderRadius.circular(Dimens.rPill),
            border: Border.all(
              color: active ? t.accent : (hovered ? t.accent : t.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(congregation.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                congregation.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (acceso.isNotEmpty) ...[
                const SizedBox(width: 8),
                RolePill(role: acceso),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Chip punteado "Nueva congregación" (`.chip--add`).
class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        final fg = t.accentStrong;
        return DashedBorder(
          color: hovered ? t.accent : t.border,
          radius: Dimens.rPill,
          child: AnimatedContainer(
            duration: Dimens.dFast,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: hovered ? t.accentTint : Colors.transparent,
              borderRadius: BorderRadius.circular(Dimens.rPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  'Nueva congregación',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
