import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../../state/cloud_auth.dart';
import '../../state/sync_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/danger_button.dart';
import 'delete_account_modal.dart';
import 'downgrade_to_local_modal.dart';
import 'settings_card.dart';
import 'upgrade_to_cloud_modal.dart';

/// Settings card for the account mode. A local account has no cloud identity
/// at all — the only thing on offer is the migration wizard — and a cloud
/// account gets the identity, the way back to local and the danger zone.
/// Degrades to a "cloud not configured" row when firebase_options.dart is a
/// placeholder or initialization failed.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    final available = ref.watch(firebaseAvailableProvider);
    final cloudOk = ref.watch(cloudAuthSupportedProvider).value ?? true;
    final localMode = ref.watch(authSessionProvider
        .select((s) => s is SessionUnlocked && s.mode == AccountMode.local));
    final user = ref.watch(cloudUserProvider).value;

    return SettingsCard(
      title: tr.account.title,
      desc: tr.account.desc,
      children: [
        if (!available || !cloudOk)
          SettingRow(
            first: true,
            title: tr.account.notConfigured,
            subtitle: available
                ? tr.portada.cloudUnsupported
                : tr.account.notConfiguredDesc,
          )
        else if (localMode)
          SettingRow(
            first: true,
            title: tr.accountMode.toCloudTitle,
            subtitle: tr.accountMode.toCloudDesc,
            trailing: AppButton(
              icon: Icons.cloud_upload_outlined,
              label: tr.accountMode.toCloudAction,
              onPressed: () => showAppModal<void>(
                context,
                builder: (ctx, sheet, close) =>
                    UpgradeToCloudModal(sheet: sheet, onClose: close),
              ),
            ),
          )
        else ...[
          SettingRow(
            first: true,
            title: tr.account.signedInAs,
            subtitle: user?.email ?? user?.uid ?? '',
            trailing: AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.logout,
              label: tr.account.signOut,
              onPressed: () => ref.read(cloudSignOutProvider)(),
            ),
          ),
          // Local mode wraps the DB key with a password and leaves it in the OS
          // keychain, which a browser does not have.
          if (!kIsWeb)
            SettingRow(
              title: tr.accountMode.toLocalTitle,
              subtitle: tr.accountMode.toLocalDesc,
              trailing: AppButton(
                variant: AppButtonVariant.ghost,
                icon: Icons.smartphone,
                label: tr.accountMode.toLocalAction,
                onPressed: () => showAppModal<void>(
                  context,
                  builder: (ctx, sheet, close) =>
                      DowngradeToLocalModal(sheet: sheet, onClose: close),
                ),
              ),
            ),
          SettingRow(
            title: tr.account.deleteAccount,
            subtitle: tr.account.deleteAccountDesc,
            trailing: DangerButton(
              label: tr.account.deleteAccount,
              onTap: () => showAppModal<void>(
                context,
                builder: (ctx, sheet, close) =>
                    DeleteAccountModal(sheet: sheet, onClose: close),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
