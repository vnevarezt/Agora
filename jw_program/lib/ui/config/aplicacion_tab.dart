import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/ui_state.dart';
import '../widgets/app_button.dart';
import '../widgets/labeled_field.dart';
import '../widgets/segmented_control.dart';
import 'settings_card.dart';

const _idiomasApp = ['Español', 'English', 'Português'];
const _formatosHora = ['24 horas (18:00)', '12 horas (6:00 p. m.)'];
const _iniciosSemana = ['Lunes', 'Domingo'];
const _nombresPdf = ['Nombre y apellido', 'Apellido, nombre', 'Solo nombre'];

const _notificaciones = [
  (
    titulo: 'Partes sin asignar',
    desc: 'Avisar cuando falten asignaciones a 3 días de la reunión',
    inicial: true,
  ),
  (
    titulo: 'Carga de asignaciones',
    desc: 'Avisar si un hermano acumula muchas asignaciones',
    inicial: true,
  ),
  (
    titulo: 'Nuevos cuadernos',
    desc: 'Avisar cuando haya un nuevo cuaderno disponible',
    inicial: true,
  ),
  (
    titulo: 'Exportaciones pendientes',
    desc: 'Recordar exportar el programa antes del fin de semana',
    inicial: false,
  ),
];

/// Pestaña "Aplicación" de Configuración. Solo el tema es funcional; el resto
/// son controles de UI con estado local (sin persistencia).
class AplicacionTab extends ConsumerStatefulWidget {
  const AplicacionTab({super.key});

  @override
  ConsumerState<AplicacionTab> createState() => _AplicacionTabState();
}

class _AplicacionTabState extends ConsumerState<AplicacionTab> {
  String _idioma = _idiomasApp.first;
  String _formato = _formatosHora.first;
  String _inicio = _iniciosSemana.first;
  String _nombrePdf = _nombresPdf.first;
  late final List<bool> _notif = [for (final n in _notificaciones) n.inicial];

  @override
  Widget build(BuildContext context) {
    return SettingsColumns(
      left: [_apariencia(), _general(), _notificacionesCard()],
      right: [_datos(), _sesion()],
    );
  }

  Widget _apariencia() {
    final modo = ref.watch(themeModeProvider);
    final idx = switch (modo) {
      ThemeMode.light => 0,
      ThemeMode.dark => 1,
      ThemeMode.system => 2,
    };
    const modos = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

    return SettingsCard(
      title: 'Apariencia',
      desc: 'Cómo se ve la aplicación en este dispositivo.',
      children: [
        SettingRow(
          first: true,
          title: 'Tema',
          subtitle: 'Claro, oscuro o según el sistema',
          trailing: SegmentedTabs(
            segments: const [
              (icon: null, label: 'Claro'),
              (icon: null, label: 'Oscuro'),
              (icon: null, label: 'Sistema'),
            ],
            index: idx,
            onChanged: (i) =>
                ref.read(themeModeProvider.notifier).set(modos[i]),
          ),
        ),
      ],
    );
  }

  Widget _general() {
    return SettingsCard(
      title: 'General',
      desc: 'Idioma y formato.',
      children: [
        SettingsGrid(
          children: [
            LabeledField(
              label: 'Idioma de la app',
              child: AppDropdown<String>(
                value: _idioma,
                items: _idiomasApp,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _idioma = v),
              ),
            ),
            LabeledField(
              label: 'Formato de hora',
              child: AppDropdown<String>(
                value: _formato,
                items: _formatosHora,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _formato = v),
              ),
            ),
            LabeledField(
              label: 'Inicio de semana',
              child: AppDropdown<String>(
                value: _inicio,
                items: _iniciosSemana,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _inicio = v),
              ),
            ),
            LabeledField(
              label: 'Nombre en los PDF',
              child: AppDropdown<String>(
                value: _nombrePdf,
                items: _nombresPdf,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _nombrePdf = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _notificacionesCard() {
    return SettingsCard(
      title: 'Notificaciones',
      desc: 'Recordatorios que genera la app.',
      children: [
        for (var i = 0; i < _notificaciones.length; i++)
          SettingRow(
            first: i == 0,
            title: _notificaciones[i].titulo,
            subtitle: _notificaciones[i].desc,
            trailing: Transform.scale(
              scale: 0.85,
              child: Switch(
                value: _notif[i],
                onChanged: (v) => setState(() => _notif[i] = v),
              ),
            ),
          ),
      ],
    );
  }

  Widget _datos() {
    return SettingsCard(
      title: 'Datos',
      desc: 'Copia de seguridad de tus proyectos, hermanos y congregaciones. '
          'Útil también para mover datos entre el modo local y la nube.',
      children: [
        SettingRow(
          first: true,
          title: 'Exportar datos',
          subtitle: 'Genera un archivo .jwbackup con todo',
          trailing: AppButton(
            variant: AppButtonVariant.ghost,
            icon: Icons.file_upload_outlined,
            label: 'Exportar',
            onPressed: () {},
          ),
        ),
        SettingRow(
          title: 'Importar datos',
          subtitle: 'Restaura desde un archivo .jwbackup',
          trailing: AppButton(
            variant: AppButtonVariant.ghost,
            icon: Icons.file_open_outlined,
            label: 'Importar',
            onPressed: () {},
          ),
        ),
        const SettingRow(
          title: 'Última copia',
          subtitle: 'Sin copias todavía',
        ),
      ],
    );
  }

  Widget _sesion() {
    return SettingsCard(
      title: 'Sesión',
      desc: 'Estás usando la app en modo local en este dispositivo.',
      children: const [
        SettingRow(
          first: true,
          title: 'Modo local',
          subtitle: 'Los datos viven solo en este dispositivo',
        ),
      ],
    );
  }
}
