import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/ui_state.dart';
import '../widgets/app_button.dart';
import '../widgets/labeled_field.dart';
import '../widgets/segmented_control.dart';
import 'settings_card.dart';

// Decorative dropdown options (UI-only, not persisted). Getters so the labels
// follow the active app language.
List<String> get _timeFormats =>
    [t.options.timeFormat24, t.options.timeFormat12];
List<String> get _weekStarts => [t.days.monday, t.days.sunday];
List<String> get _pdfNameFormats => [
      t.options.pdfNameFull,
      t.options.pdfNameLastFirst,
      t.options.pdfNameFirstOnly,
    ];

// Default on/off state per notification row.
const _notifInitial = [true, true, true, false];
List<({String title, String desc})> _notifItems(Translations tr) => [
      (title: tr.settings.notif.unassignedTitle, desc: tr.settings.notif.unassignedDesc),
      (title: tr.settings.notif.loadTitle, desc: tr.settings.notif.loadDesc),
      (
        title: tr.settings.notif.newNotebooksTitle,
        desc: tr.settings.notif.newNotebooksDesc
      ),
      (title: tr.settings.notif.exportsTitle, desc: tr.settings.notif.exportsDesc),
    ];

/// Native language names for the app-language selector. New languages added as
/// a `<locale>.i18n.json` file appear automatically; add an entry here to show
/// their native name (otherwise the uppercased language code is shown).
const _localeNames = {'es': 'Español', 'en': 'English', 'pt': 'Português'};
String _localeName(AppLocale l) =>
    _localeNames[l.languageCode] ?? l.languageCode.toUpperCase();

/// Settings "Aplicación" tab. The theme and language are functional; the rest
/// are UI controls with local state (no persistence yet).
class ApplicationTab extends ConsumerStatefulWidget {
  const ApplicationTab({super.key});

  @override
  ConsumerState<ApplicationTab> createState() => _ApplicationTabState();
}

class _ApplicationTabState extends ConsumerState<ApplicationTab> {
  String _format = _timeFormats.first;
  String _weekStart = _weekStarts.first;
  String _pdfNameFormat = _pdfNameFormats.first;
  late final List<bool> _notif = [..._notifInitial];

  @override
  Widget build(BuildContext context) {
    return SettingsColumns(
      left: [_appearance(), _general(), _notificationsCard()],
      right: [_datos(), _sessionSection()],
    );
  }

  Widget _appearance() {
    final tr = context.t;
    final modo = ref.watch(themeModeProvider);
    final idx = switch (modo) {
      ThemeMode.light => 0,
      ThemeMode.dark => 1,
      ThemeMode.system => 2,
    };
    const modos = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

    return SettingsCard(
      title: tr.settings.appearance,
      desc: tr.settings.appearanceDesc,
      children: [
        SettingRow(
          first: true,
          title: tr.settings.theme,
          subtitle: tr.settings.themeDesc,
          trailing: SegmentedTabs(
            segments: [
              (icon: null, label: tr.settings.themeLight),
              (icon: null, label: tr.settings.themeDark),
              (icon: null, label: tr.settings.themeSystem),
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
    final tr = context.t;
    return SettingsCard(
      title: tr.settings.general,
      desc: tr.settings.generalDesc,
      children: [
        SettingsGrid(
          children: [
            LabeledField(
              label: tr.settings.appLanguage,
              child: AppDropdown<AppLocale>(
                value: ref.watch(localeProvider),
                items: AppLocale.values,
                itemLabel: _localeName,
                onChanged: (v) => ref.read(localeProvider.notifier).set(v),
              ),
            ),
            LabeledField(
              label: tr.settings.timeFormat,
              child: AppDropdown<String>(
                value: _timeFormats.contains(_format) ? _format : _timeFormats.first,
                items: _timeFormats,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _format = v),
              ),
            ),
            LabeledField(
              label: tr.settings.weekStart,
              child: AppDropdown<String>(
                value: _weekStarts.contains(_weekStart)
                    ? _weekStart
                    : _weekStarts.first,
                items: _weekStarts,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _weekStart = v),
              ),
            ),
            LabeledField(
              label: tr.settings.pdfName,
              child: AppDropdown<String>(
                value: _pdfNameFormats.contains(_pdfNameFormat)
                    ? _pdfNameFormat
                    : _pdfNameFormats.first,
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
    final tr = context.t;
    final items = _notifItems(tr);
    return SettingsCard(
      title: tr.settings.notificationsTitle,
      desc: tr.settings.notificationsDesc,
      children: [
        for (var i = 0; i < items.length; i++)
          SettingRow(
            first: i == 0,
            title: items[i].title,
            subtitle: items[i].desc,
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
    final tr = context.t;
    return SettingsCard(
      title: tr.settings.data,
      desc: tr.settings.dataDesc,
      children: [
        SettingRow(
          first: true,
          title: tr.settings.exportData,
          subtitle: tr.settings.exportDataDesc,
          trailing: AppButton(
            variant: AppButtonVariant.ghost,
            icon: Icons.file_upload_outlined,
            label: tr.settings.export,
            onPressed: () {},
          ),
        ),
        SettingRow(
          title: tr.settings.importData,
          subtitle: tr.settings.importDataDesc,
          trailing: AppButton(
            variant: AppButtonVariant.ghost,
            icon: Icons.file_open_outlined,
            label: tr.settings.import,
            onPressed: () {},
          ),
        ),
        SettingRow(
          title: tr.settings.lastBackup,
          subtitle: tr.settings.noBackupsYet,
        ),
      ],
    );
  }

  Widget _sessionSection() {
    final tr = context.t;
    return SettingsCard(
      title: tr.settings.session,
      desc: tr.settings.sessionDesc,
      children: [
        SettingRow(
          first: true,
          title: tr.settings.localMode,
          subtitle: tr.settings.localModeDesc,
        ),
      ],
    );
  }
}
