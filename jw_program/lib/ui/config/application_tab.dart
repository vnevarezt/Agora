import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/ui_state.dart';
import '../widgets/app_button.dart';
import '../widgets/labeled_field.dart';
import '../widgets/segmented_control.dart';
import 'settings_card.dart';

const _appLanguages = ['Español', 'English', 'Português'];
const _timeFormats = ['24 horas (18:00)', '12 horas (6:00 p. m.)'];
const _weekStarts = ['Lunes', 'Domingo'];
const _pdfNameFormats = ['Nombre y apellido', 'Apellido, nombre', 'Solo nombre'];

const _notifications = [
  (
    title: 'Partes sin asignar',
    desc: 'Avisar cuando falten asignaciones a 3 días de la reunión',
    inicial: true,
  ),
  (
    title: 'Carga de asignaciones',
    desc: 'Avisar si un participante acumula muchas asignaciones',
    inicial: true,
  ),
  (
    title: 'Nuevos cuadernos',
    desc: 'Avisar cuando haya un nuevo cuaderno disponible',
    inicial: true,
  ),
  (
    title: 'Exportaciones pendientes',
    desc: 'Recordar exportar el programa antes del fin de semana',
    inicial: false,
  ),
];

/// Settings "Aplicación" tab. Only the theme is functional; the rest are
/// UI controls with local state (no persistence).
class ApplicationTab extends ConsumerStatefulWidget {
  const ApplicationTab({super.key});

  @override
  ConsumerState<ApplicationTab> createState() => _ApplicationTabState();
}

class _ApplicationTabState extends ConsumerState<ApplicationTab> {
  String _language = _appLanguages.first;
  String _format = _timeFormats.first;
  String _weekStart = _weekStarts.first;
  String _pdfNameFormat = _pdfNameFormats.first;
  late final List<bool> _notif = [for (final n in _notifications) n.inicial];

  @override
  Widget build(BuildContext context) {
    return SettingsColumns(
      left: [_appearance(), _general(), _notificationsCard()],
      right: [_datos(), _sessionSection()],
    );
  }

  Widget _appearance() {
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
                value: _language,
                items: _appLanguages,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _language = v),
              ),
            ),
            LabeledField(
              label: 'Formato de hora',
              child: AppDropdown<String>(
                value: _format,
                items: _timeFormats,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _format = v),
              ),
            ),
            LabeledField(
              label: 'Inicio de semana',
              child: AppDropdown<String>(
                value: _weekStart,
                items: _weekStarts,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _weekStart = v),
              ),
            ),
            LabeledField(
              label: 'Nombre en los PDF',
              child: AppDropdown<String>(
                value: _pdfNameFormat,
                items: _pdfNameFormats,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _pdfNameFormat = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _notificationsCard() {
    return SettingsCard(
      title: 'Notificaciones',
      desc: 'Recordatorios que genera la app.',
      children: [
        for (var i = 0; i < _notifications.length; i++)
          SettingRow(
            first: i == 0,
            title: _notifications[i].title,
            subtitle: _notifications[i].desc,
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
      desc: 'Copia de seguridad de tus proyectos, participantes y congregaciones. '
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

  Widget _sessionSection() {
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
