import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/dashboard_provider.dart' show relativeEditedLabel;
import '../../state/sync_controller.dart';
import '../../state/sync_keys.dart';
import '../widgets/app_button.dart';
import 'settings_card.dart';

/// Settings card for cloud sync. Nothing here needs setting up — the
/// encryption key is minted on first sign-in and travels with the account, so
/// any device of yours picks it up on its own.
///
/// It does carry one button, and only because syncing is otherwise entirely
/// driven by heartbeat deliveries: when one of those listeners is refused or
/// dies, its congregation stops arriving and there was no way for anyone to
/// ask again. [SyncController.syncNow] ignores heartbeats and pulls every
/// membership, which is the escape hatch that was written and never wired.
class SyncCard extends ConsumerWidget {
  const SyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    final keys = ref.watch(syncKeysProvider);

    return SettingsCard(
      title: tr.cloudSync.title,
      desc: tr.cloudSync.desc,
      children: [
        switch (keys) {
          SyncKeysUnavailable() =>
            SettingRow(first: true, title: tr.cloudSync.signedOut),
          SyncKeysLoading() => const SettingRow(first: true, title: '…'),
          SyncKeysStalled() => SettingRow(
              first: true,
              title: tr.cloudSync.statusOffline,
              subtitle: tr.cloudSync.errorOffline,
            ),
          SyncKeysError() => SettingRow(
              first: true,
              title: tr.cloudSync.statusError,
              subtitle: tr.cloudSync.unknownError,
            ),
          SyncKeysReady() =>
            _statusRow(tr, ref, ref.watch(syncControllerProvider)),
        },
      ],
    );
  }

  Widget _statusRow(Translations tr, WidgetRef ref, SyncStatus s) {
    final when = s.lastSyncAt == null
        ? tr.cloudSync.neverSynced
        : tr.cloudSync.lastSync(when: relativeEditedLabel(s.lastSyncAt!));
    final (title, subtitle) = switch (s.phase) {
      SyncPhase.syncing => (tr.cloudSync.statusSyncing, when),
      SyncPhase.offline => (tr.cloudSync.statusOffline, tr.cloudSync.errorOffline),
      SyncPhase.error => (
          tr.cloudSync.statusError,
          switch (s.errorKey) {
            'permissionDenied' => tr.cloudSync.errorPermission,
            'offline' => tr.cloudSync.errorOffline,
            _ => tr.cloudSync.errorUnknown,
          }
        ),
      _ => (tr.cloudSync.ready, when),
    };
    final busy = s.phase == SyncPhase.syncing;
    return SettingRow(
      first: true,
      title: title,
      subtitle: subtitle,
      trailing: AppButton(
        variant: AppButtonVariant.ghost,
        icon: Icons.sync,
        label: tr.cloudSync.syncNow,
        busy: busy,
        onPressed: busy
            ? null
            : () => ref.read(syncControllerProvider.notifier).syncNow(),
      ),
    );
  }
}
