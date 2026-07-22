import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_crypto.dart';
import '../../data/device_auth.dart';
import '../../data/files/file_saver.dart';
import '../../i18n/strings.g.dart';
import '../../state/app_settings.dart';
import '../../state/auth_session.dart';
import '../../state/backup_provider.dart';
import '../../state/cloud_auth.dart' show cloudUserProvider;
import '../../state/preview_provider.dart' show fileSaverProvider;
import '../../state/ui_state.dart';
import '../widgets/app_button.dart';
import '../widgets/labeled_field.dart';
import '../widgets/segmented_control.dart';
import 'account_card.dart';
import 'security_card.dart';
import 'settings_card.dart';
import 'sync_card.dart';

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
  bool _backupBusy = false;

  @override
  Widget build(BuildContext context) {
    // SecurityCard adapts to the mode (password rows are local-only; device
    // unlock exists in both). In cloud mode it only appears when the device
    // can actually authenticate its owner — otherwise it would be empty.
    final localMode = ref.watch(authSessionProvider.select(
        (s) => s is SessionUnlocked && s.mode == AccountMode.local));
    final deviceAuthOk =
        ref.watch(deviceAuthSupportedProvider).value ?? false;
    // Cloud sync card: only once the cloud is configured and signed in.
    final signedIn = ref.watch(cloudUserProvider).value != null;
    return SettingsColumns(
      left: [_appearance(), _general(), _notificationsCard()],
      right: [
        _datos(),
        if (localMode || deviceAuthOk) const SecurityCard(),
        const AccountCard(),
        if (signedIn) const SyncCard(),
      ],
    );
  }

  /// Password prompt for export (with confirmation) / import.
  Future<String?> _askBackupPassword({required bool confirm}) {
    final tr = context.t;
    var password = '';
    var repeat = '';
    String? error;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tr.settings.backupPasswordTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                confirm
                    ? tr.settings.backupPasswordDesc
                    : tr.settings.backupImportPasswordDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                obscureText: true,
                onChanged: (v) => password = v,
              ),
              if (confirm) ...[
                const SizedBox(height: 10),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                      hintText: tr.settings.backupPasswordRepeat),
                  onChanged: (v) => repeat = v,
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(tr.common.cancel),
            ),
            TextButton(
              onPressed: () {
                if (password.isEmpty) return;
                if (confirm && password != repeat) {
                  setState(
                      () => error = tr.settings.backupPasswordMismatch);
                  return;
                }
                Navigator.of(context).pop(password);
              },
              child: Text(
                  confirm ? tr.settings.export : tr.settings.import),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    final tr = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final password = await _askBackupPassword(confirm: true);
    if (password == null || password.isEmpty) return;
    setState(() => _backupBusy = true);
    try {
      final bytes = await ref.read(backupServiceProvider).export(password);
      final date =
          DateTime.now().toIso8601String().substring(0, 10);
      final outcome = await ref.read(fileSaverProvider).saveAs(
            bytes: bytes,
            suggestedName: 'agora-$date.agora',
            extension: 'agora',
            mimeType: 'application/octet-stream',
            typeLabel: 'Agora',
          );
      switch (outcome) {
        case SaveDone(:final path):
          ref.read(appSettingsProvider.notifier).markBackupNow();
          messenger.showSnackBar(
              SnackBar(content: Text(tr.settings.backupSaved(path: path))));
        case SaveShared():
          // saveAs never shares, but the sealed switch must stay exhaustive.
          ref.read(appSettingsProvider.notifier).markBackupNow();
          messenger.showSnackBar(
              SnackBar(content: Text(tr.settings.backupSharedMsg)));
        case SaveCanceled():
          break;
      }
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(tr.export.error(error: e))));
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importBackup() async {
    final tr = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'Agora', extensions: ['agora']),
    ]);
    if (file == null || !mounted) return;
    final password = await _askBackupPassword(confirm: false);
    if (password == null || password.isEmpty) return;
    setState(() => _backupBusy = true);
    try {
      final bytes = await file.readAsBytes();
      final applied =
          await ref.read(backupServiceProvider).import(bytes, password);
      messenger.showSnackBar(
          SnackBar(content: Text(tr.settings.backupRestored(n: applied))));
    } on WrongBackupPasswordException {
      messenger.showSnackBar(
          SnackBar(content: Text(tr.settings.backupWrongPassword)));
    } on MalformedBackupException {
      messenger.showSnackBar(
          SnackBar(content: Text(tr.settings.backupMalformed)));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(tr.export.error(error: e))));
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Widget _datos() {
    final tr = context.t;
    final last = ref.watch(appSettingsProvider).lastBackupAt?.toLocal();
    final lastLabel = last == null
        ? tr.settings.noBackupsYet
        : '${last.day.toString().padLeft(2, '0')}/'
            '${last.month.toString().padLeft(2, '0')}/${last.year} '
            '${last.hour.toString().padLeft(2, '0')}:'
            '${last.minute.toString().padLeft(2, '0')}';
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
            busy: _backupBusy,
            onPressed: _backupBusy ? null : _exportBackup,
          ),
        ),
        SettingRow(
          title: tr.settings.importData,
          subtitle: tr.settings.importDataDesc,
          trailing: AppButton(
            variant: AppButtonVariant.ghost,
            icon: Icons.file_open_outlined,
            label: tr.settings.import,
            onPressed: _backupBusy ? null : _importBackup,
          ),
        ),
        SettingRow(title: tr.settings.lastBackup, subtitle: lastLabel),
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
