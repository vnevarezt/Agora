import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config_sample.dart';
import '../../models/congregacion.dart';
import '../../state/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/dashed_border.dart';
import '../widgets/labeled_field.dart';
import 'invitar_usuario_modal.dart';
import 'nueva_congregacion_modal.dart';
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
  late String _congId;
  late String _nombre;
  late String _numero;
  late String _idioma;
  late String _diaEntre;
  late String _horaEntre;
  late String _diaFin;
  late String _horaFin;
  late bool _aux;
  final Map<String, String> _roles = {
    for (final u in usuariosEjemplo) u.id: u.rol,
  };

  @override
  void initState() {
    super.initState();
    final congs = ref.read(congregacionesDashProvider);
    _seleccionar(congs.first.id, congs, notificar: false);
  }

  void _seleccionar(String id, List<Congregacion> congs,
      {bool notificar = true}) {
    final cong = congs.firstWhere((c) => c.id == id);
    final cfg = congConfigEjemplo[id]!;
    void aplicar() {
      _congId = id;
      _nombre = cong.nombre;
      _numero = cong.numero;
      _idioma = cfg.idioma;
      _diaEntre = cfg.diaEntreSemana;
      _horaEntre = cfg.horaEntreSemana;
      _diaFin = cfg.diaFinSemana;
      _horaFin = cfg.horaFinSemana;
      _aux = cfg.salaAuxiliar;
    }

    if (notificar) {
      setState(aplicar);
    } else {
      aplicar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final congs = ref.watch(congregacionesDashProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectorCongregaciones(congs),
        const SizedBox(height: 16),
        SettingsColumns(
          left: [_datosCard(), _horariosCard()],
          right: [_usuariosCard()],
        ),
      ],
    );
  }

  Widget _selectorCongregaciones(List<Congregacion> congs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in congs)
          _CongChip(
            congregacion: c,
            acceso: accesoEjemplo[c.id] ?? '',
            active: _congId == c.id,
            onTap: () => _seleccionar(c.id, congs),
          ),
        _AddChip(onTap: () => mostrarNuevaCongregacion(context)),
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
                items: idiomasReunion,
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
                items: diasSemana,
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
                items: diasSemana,
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
    final usuarios =
        usuariosEjemplo.where((u) => u.congIds.contains(_congId)).toList();
    return SettingsCard(
      title: 'Usuarios con acceso',
      desc: 'Quién puede ver o editar los proyectos de esta congregación.',
      children: [
        for (var i = 0; i < usuarios.length; i++)
          UserRow(
            first: i == 0,
            nombre: usuarios[i].nombre,
            email: usuarios[i].email,
            trailing: _roles[usuarios[i].id] == 'Administrador'
                ? const RolePill(rol: 'Administrador')
                : SizedBox(
                    width: 130,
                    child: AppDropdown<String>(
                      value: _roles[usuarios[i].id],
                      items: rolesAcceso,
                      itemLabel: (s) => s,
                      onChanged: (v) =>
                          setState(() => _roles[usuarios[i].id] = v),
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
            onPressed: () => mostrarInvitarUsuario(context),
          ),
        ),
      ],
    );
  }
}

/// Chip selector de congregación: punto de color + nombre + pill de rol.
class _CongChip extends StatelessWidget {
  const _CongChip({
    required this.congregacion,
    required this.acceso,
    required this.active,
    required this.onTap,
  });

  final Congregacion congregacion;
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
                  color: congregacion.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                congregacion.nombre,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (acceso.isNotEmpty) ...[
                const SizedBox(width: 8),
                RolePill(rol: acceso),
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
