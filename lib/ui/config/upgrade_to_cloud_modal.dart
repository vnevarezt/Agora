import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../../state/cloud_auth.dart';
import '../../state/restore_provider.dart';
import '../../state/sync_controller.dart';
import '../../state/sync_provider.dart';
import '../auth/cloud_auth_screen.dart';
import '../auth/widgets/auth_error_text.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_spinner.dart';
import '../widgets/modal_shell.dart';
import '../widgets/segmented_control.dart';
import 'backup_actions.dart';

/// Local → cloud, in three steps: identify, consent, upload.
///
/// The key handover runs BEFORE the first byte leaves the device, because the
/// sync stack is gated on cloud mode ([syncUidProvider]) — which is what makes
/// "local mode uploads nothing" true no matter what this wizard does. Once the
/// mode flips, the existing auto-enable machinery does the upload on its own
/// and this modal only reports progress.
class UpgradeToCloudModal extends ConsumerStatefulWidget {
  const UpgradeToCloudModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<UpgradeToCloudModal> createState() =>
      _UpgradeToCloudModalState();
}

enum _Step { signIn, consent, upload }

class _UpgradeToCloudModalState extends ConsumerState<UpgradeToCloudModal> {
  _Step _step = _Step.signIn;
  CloudFormMode _mode = CloudFormMode.login;
  bool _busy = false;
  String? _error;

  /// Backing out after signing in but before the mode flips must not leave a
  /// Firebase session behind a local account: nothing would sync (the gate is
  /// the mode) but "local" would stop being literally true.
  void _cancel() {
    if (_step != _Step.upload) {
      final auth = ref.read(cloudAuthProvider.future);
      auth.then((a) => a?.signOut()).catchError((_) {});
    }
    widget.onClose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authSessionProvider.notifier).upgradeToCloud();
      if (mounted) setState(() => _step = _Step.upload);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.t.accountMode.errorUnknown;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final (label, onPrimary) = switch (_step) {
      _Step.signIn => (tr.common.close, _cancel),
      _Step.consent => (tr.accountMode.consentConfirm, _confirm),
      _Step.upload => (tr.common.close, widget.onClose),
    };

    return ModalShell(
      sheet: widget.sheet,
      onClose: _cancel,
      title: _step == _Step.consent
          ? tr.accountMode.consentTitle
          : tr.accountMode.toCloudTitle,
      desc: _step == _Step.signIn ? tr.accountMode.signInStep : null,
      primaryLabel: label,
      primaryBusy: _busy,
      onPrimary: _busy ? null : onPrimary,
      body: switch (_step) {
        _Step.signIn => _signIn(tr),
        _Step.consent => _consent(tr),
        _Step.upload => const _UploadProgress(),
      },
    );
  }

  Widget _signIn(Translations tr) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            segments: [
              (icon: null, label: tr.auth.cloud.loginTitle),
              (icon: null, label: tr.auth.cloud.registerTitle),
            ],
            index: _mode == CloudFormMode.login ? 0 : 1,
            onChanged: (i) => setState(() => _mode =
                i == 0 ? CloudFormMode.login : CloudFormMode.register),
          ),
          const SizedBox(height: 16),
          CloudAuthForm(
            mode: _mode,
            onSuccess: () => setState(() => _step = _Step.consent),
          ),
        ],
      );

  Widget _consent(Translations tr) {
    final t = context.tokens;
    final uid = ref.watch(cloudUserProvider).value?.uid;
    final existing = uid == null
        ? 0
        : (ref.watch(membershipsOnceProvider(uid)).value ?? const []).length;

    Widget line(String text, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppText.body,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: color ?? t.textMute,
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line(tr.accountMode.consentBody, color: t.text),
        line(tr.accountMode.consentCustody),
        if (existing > 0)
          line(tr.accountMode.existingData(count: existing),
              color: Theme.of(context).colorScheme.error),
        Row(
          children: [
            Expanded(child: line(tr.accountMode.backupHint)),
            const SizedBox(width: 10),
            AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.file_upload_outlined,
              label: tr.settings.export,
              onPressed: _busy ? null : () => exportBackup(context, ref),
            ),
          ],
        ),
        AuthErrorText(_error),
      ],
    );
  }
}

class _UploadProgress extends ConsumerWidget {
  const _UploadProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    final t = context.tokens;
    final progress = ref.watch(cloudUploadProgressProvider);
    final offline = ref.watch(
            syncControllerProvider.select((s) => s.phase)) ==
        SyncPhase.offline;

    final (title, subtitle) = switch ((progress, offline)) {
      (null, _) => (tr.accountMode.uploadDone, null),
      (_, true) => (tr.accountMode.uploadPending, null),
      (final p!, _) => (
          tr.accountMode.uploading,
          tr.accountMode.uploadingProgress(done: p.done, total: p.total),
        ),
    };

    return Row(
      children: [
        if (progress != null && !offline) ...[
          const AppSpinner(size: 18),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppText.body,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: t.text,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppText.small,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
