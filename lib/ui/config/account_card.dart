import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../../state/cloud_auth.dart';
import '../../state/sync_provider.dart';
import '../auth/cloud_sign_in_modal.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import 'settings_card.dart';

/// Settings card for the optional Firebase identity. Degrades to a
/// "cloud not configured" row when firebase_options.dart is a placeholder or
/// initialization failed; the rest of the app never depends on it.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    final available = ref.watch(firebaseAvailableProvider);
    final cloudOk = ref.watch(cloudAuthSupportedProvider).value ?? true;
    final user = ref.watch(cloudUserProvider).value;
    final session = ref.watch(authSessionProvider);
    // In cloud mode signing out DOES close the session (it is the gate); the
    // "your local data stays open" note only applies to local-mode users.
    final localMode =
        session is SessionUnlocked && session.mode == AccountMode.local;

    return SettingsCard(
      title: tr.account.title,
      desc: available && user != null && localMode
          ? tr.account.localGateNote
          : tr.account.desc,
      children: [
        if (!available || !cloudOk)
          SettingRow(
            first: true,
            title: tr.account.notConfigured,
            subtitle: available
                ? tr.portada.cloudUnsupported
                : tr.account.notConfiguredDesc,
          )
        else if (user == null)
          SettingRow(
            first: true,
            title: tr.account.signIn,
            subtitle: tr.account.desc,
            trailing: AppButton(
              icon: Icons.cloud_outlined,
              label: tr.account.signIn,
              onPressed: () => showAppModal<void>(
                context,
                builder: (ctx, sheet, close) =>
                    CloudSignInModal(sheet: sheet, onClose: close),
              ),
            ),
          )
        else
          SettingRow(
            first: true,
            title: tr.account.signedInAs,
            subtitle: user.email ?? user.uid,
            trailing: AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.logout,
              label: tr.account.signOut,
              onPressed: () => ref.read(cloudSignOutProvider)(),
            ),
          ),
      ],
    );
  }
}
