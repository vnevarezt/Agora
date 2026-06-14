import 'package:flutter/material.dart';
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
class CongregacionTab extends ConsumerStatefulWidget {
  const CongregacionTab({super.key});

  @override
  ConsumerState<CongregacionTab> createState() => _CongregacionTabState();
}

class _CongregacionTabState extends ConsumerState<CongregacionTab> {
  String? _congId;
  String _nombre = '';
  String _numero = '';
  String _idioma = meetingLanguages.first;
  String _diaEntre = 'Martes';
  String _horaEntre = '19:00';
  String _diaFin = 'Domingo';
  String _horaFin = '10:00';
  bool _aux = false;

  /// Selecciona una congregación y siembra los campos. Los horarios aún no se
  /// persisten (sin backend): se muestran con valores por defecto.
  void _select(Congregation cong, {bool notificar = true}) {
    void aplicar() {
      _congId = cong.id;
      _nombre = cong.name;
      _numero = cong.number;
      _idioma = meetingLanguages.first;
      _diaEntre = 'Martes';
      _horaEntre = '19:00';
      _diaFin = 'Domingo';
      _horaFin = '10:00';
      _aux = false;
    }

    if (notificar) {
      setState(aplicar);
    } else {
      aplicar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final congs = ref.watch(congregationsProvider);

    // Mantener una selección válida (la lista cambia en memoria).
    if (congs.isEmpty) {
      _congId = null;
    } else if (_congId == null || !congs.any((c) => c.id == _congId)) {
      _select(congs.first, notificar: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectorCongregaciones(congs),
        const SizedBox(height: 16),
        if (congs.isEmpty)
          _vacio(context)
        else
          SettingsColumns(
            left: [_datosCard(), _horariosCard()],
            right: [_usuariosCard()],
          ),
      ],
    );
  }

  Widget _vacio(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment_outlined, size: 40, color: t.textMute),
            const SizedBox(height: 12),
            Text(
              'Aún no hay congregaciones.\n'
              'Crea la primera con "Nueva congregación".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: t.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorCongregaciones(List<Congregation> congs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in congs)
          _CongChip(
            congregation: c,
            acceso: '',
            active: _congId == c.id,
            onTap: () => _select(c),
          ),
        _AddChip(onTap: () => showNewCongregation(context)),
      ],
    );
  }

  Widget _datosCard() {
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
                key: ValueKey('$_congId-nombre'),
                initial: _nombre,
                onChanged: (v) => _nombre = v,
              ),
            ),
            LabeledField(
              label: 'Número',
              child: BoundTextField(
                key: ValueKey('$_congId-numero'),
                initial: _numero,
                style: AppText.mono(size: 13.5, color: t.text),
                onChanged: (v) => _numero = v,
              ),
            ),
            LabeledField(
              label: 'Idioma de la reunión',
              child: AppDropdown<String>(
                value: _idioma,
                items: meetingLanguages,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _idioma = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _horariosCard() {
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
                value: _diaEntre,
                items: daysOfWeek,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _diaEntre = v),
              ),
            ),
            LabeledField(
              label: 'Entre semana · hora',
              child: BoundTextField(
                key: ValueKey('$_congId-he'),
                initial: _horaEntre,
                style: mono,
                onChanged: (v) => _horaEntre = v,
              ),
            ),
            LabeledField(
              label: 'Fin de semana · día',
              child: AppDropdown<String>(
                value: _diaFin,
                items: daysOfWeek,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _diaFin = v),
              ),
            ),
            LabeledField(
              label: 'Fin de semana · hora',
              child: BoundTextField(
                key: ValueKey('$_congId-hf'),
                initial: _horaFin,
                style: mono,
                onChanged: (v) => _horaFin = v,
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
              value: _aux,
              onChanged: (v) => setState(() => _aux = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _usuariosCard() {
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

/// Chip selector de congregación: punto de color + nombre + pill de rol.
class _CongChip extends StatelessWidget {
  const _CongChip({
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
