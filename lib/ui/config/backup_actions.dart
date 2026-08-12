import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/files/file_saver.dart';
import '../../i18n/strings.g.dart';
import '../../state/app_settings.dart';
import '../../state/backup_provider.dart';
import '../../state/preview_provider.dart' show fileSaverProvider;
import '../theme/app_theme.dart';

/// The `.agora` backup flows, shared between the Settings "Datos" card and the
/// cloud → local wizard, which offers one before destroying the cloud copy.

Future<String?> askBackupPassword(BuildContext context,
    {required bool confirm}) {
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
                decoration:
                    InputDecoration(hintText: tr.settings.backupPasswordRepeat),
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
                      fontSize: AppText.small),
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
                setState(() => error = tr.settings.backupPasswordMismatch);
                return;
              }
              Navigator.of(context).pop(password);
            },
            child: Text(confirm ? tr.settings.export : tr.settings.import),
          ),
        ],
      ),
    ),
  );
}

Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final tr = context.t;
  final messenger = ScaffoldMessenger.of(context);
  final password = await askBackupPassword(context, confirm: true);
  if (password == null || password.isEmpty) return;
  try {
    final bytes = await ref.read(backupServiceProvider).export(password);
    final date = DateTime.now().toIso8601String().substring(0, 10);
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
        messenger
            .showSnackBar(SnackBar(content: Text(tr.settings.backupSharedMsg)));
      case SaveCanceled():
        break;
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(tr.export.error(error: e))));
  }
}
