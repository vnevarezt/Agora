import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/app_settings.dart';
import '../../state/auth_session.dart';
import '../../state/ui_state.dart';
import '../widgets/labeled_field.dart';
import '../widgets/segmented_control.dart';
import 'account_card.dart';
import 'security_card.dart';
import 'settings_card.dart';

// Dropdown option labels, index-aligned with the persisted values in
// app_settings.dart. Getters so the labels follow the active app language.
List<String> get _timeFormats =>
    [t.options.timeFormat24, t.options.timeFormat12];
List<String> get _weekStarts => [t.days.monday, t.days.sunday];
List<String> get _pdfNameFormats => [
      t.options.pdfNameFull,
      t.options.pdfNameLastFirst,
      t.options.pdfNameFirstOnly,
    ];

/// Row copy per notification preference, in display order.
List<({NotifPref pref, String title, String desc})> _notifItems(
        Translations tr) =>
    [
      (
        pref: NotifPref.unassigned,
        title: tr.settings.notif.unassignedTitle,
        desc: tr.settings.notif.unassignedDesc
      ),
      (
        pref: NotifPref.load,
        title: tr.settings.notif.loadTitle,
        desc: tr.settings.notif.loadDesc
      ),
      (
        pref: NotifPref.newNotebooks,
        title: tr.settings.notif.newNotebooksTitle,
        desc: tr.settings.notif.newNotebooksDesc
      ),
      (
        pref: NotifPref.exports,
        title: tr.settings.notif.exportsTitle,
        desc: tr.settings.notif.exportsDesc
      ),
    ];

/// Native language names for the app-language selector. New languages added as
/// a `<locale>.i18n.json` file appear automatically; add an entry here to show
/// their native name (otherwise the uppercased language code is shown).
const _localeNames = {'es': 'Español', 'en': 'English', 'pt': 'Português'};
String _localeName(AppLocale l) =>
    _localeNames[l.languageCode] ?? l.languageCode.toUpperCase();

/// Settings "Aplicación" tab. Everything shown here persists: theme and
/// preferences via SharedPreferences (app_settings.dart), language via
/// locale_boot.dart.
class ApplicationTab extends ConsumerStatefulWidget {
  const ApplicationTab({super.key});

  @override
  ConsumerState<ApplicationTab> createState() => _ApplicationTabState();
}

class _ApplicationTabState extends ConsumerState<ApplicationTab> {
  @override
  Widget build(BuildContext context) {
    // SecurityCard is local-mode only: in cloud mode there is no local
    // password to change and "lock" would strand the session on an unlock
    // screen that no password can open (the gate is the Firebase session).
    final localMode = ref.watch(authSessionProvider.select(
        (s) => s is SessionUnlocked && s.mode == AccountMode.local));
    return SettingsColumns(
      left: [_appearance(), _general(), _notificationsCard()],
      right: [
        if (localMode) const SecurityCard(),
        const AccountCard(),
      ],
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
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
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
                value: _timeFormats[settings.timeFormat24 ? 0 : 1],
                items: _timeFormats,
                itemLabel: (s) => s,
                onChanged: (v) =>
                    controller.setTimeFormat24(_timeFormats.indexOf(v) == 0),
              ),
            ),
            LabeledField(
              label: tr.settings.weekStart,
              child: AppDropdown<String>(
                value: _weekStarts[settings.weekStartMonday ? 0 : 1],
                items: _weekStarts,
                itemLabel: (s) => s,
                onChanged: (v) => controller
                    .setWeekStartMonday(_weekStarts.indexOf(v) == 0),
              ),
            ),
            LabeledField(
              label: tr.settings.pdfName,
              child: AppDropdown<String>(
                value: _pdfNameFormats[settings.pdfNameFormat.index],
                items: _pdfNameFormats,
                itemLabel: (s) => s,
                onChanged: (v) {
                  final i = _pdfNameFormats.indexOf(v);
                  controller.setPdfNameFormat(
                      PdfNameFormat.values[i < 0 ? 0 : i]);
                },
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
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
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
                value: settings.notifications[items[i].pref] ?? true,
                onChanged: (v) => controller.setNotification(items[i].pref, v),
              ),
            ),
          ),
      ],
    );
  }
}
