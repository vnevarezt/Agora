import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/cck_service.dart' show SharingException;
import '../../i18n/strings.g.dart';
import '../../state/sync_provider.dart';
import '../auth/widgets/auth_error_text.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_spinner.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import 'backup_actions.dart';
import 'delete_account_modal.dart' show BlockedCongregationsNotice;

/// Cloud → local: pull everything down, delete the cloud copy, and put the
/// session behind a local password. The download comes first on purpose, so
/// the device is complete before anything is destroyed.
class DowngradeToLocalModal extends ConsumerStatefulWidget {
  const DowngradeToLocalModal({
    super.key,
    required this.sheet,
    required this.onClose,
  });

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<DowngradeToLocalModal> createState() =>
      _DowngradeToLocalModalState();
}

class _DowngradeToLocalModalState extends ConsumerState<DowngradeToLocalModal> {
  static const _minLength = 8;

  String _name = '';
  String _password = '';
  String _confirm = '';
  bool _busy = false;
  String? _error;

  /// The drain could not be confirmed for a reason that retrying won't fix, so
  /// the modal offers to go ahead without it rather than stranding the user in
  /// cloud mode forever.
  bool _forceable = false;

  Future<void> _submit({bool force = false}) async {
    final tr = context.t;
    if (_password.length < _minLength) {
      setState(() => _error = tr.auth.local.tooShort);
      return;
    }
    if (_password != _confirm) {
      setState(() => _error = tr.auth.local.mismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(downgradeToLocalProvider)(_name.trim(), _password,
          force: force);
      if (mounted) widget.onClose();
    } on AccountDeletionBlocked {
      ref.invalidate(accountDeletionBlockersProvider);
      if (mounted) setState(() => _busy = false);
    } on SharingException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _forceable = e.reason == 'syncIncomplete';
          _error = switch (e.reason) {
            'offline' => tr.accountMode.errorOffline,
            'syncBusy' => tr.accountMode.errorSyncBusy,
            'syncIncomplete' => tr.accountMode.errorIncomplete,
            _ => tr.accountMode.errorUnknown,
          };
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = tr.accountMode.errorUnknown;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final t = context.tokens;
    final blockers = ref.watch(accountDeletionBlockersProvider);
    final blocked = blockers.value ?? const <String>[];

    final canSubmit = !_busy &&
        !blockers.isLoading &&
        blocked.isEmpty &&
        _name.trim().isNotEmpty &&
        _password.isNotEmpty &&
        _confirm.isNotEmpty;

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.accountMode.toLocalTitle,
      desc: _busy ? tr.accountMode.draining : tr.accountMode.toLocalWarning,
      primaryLabel: tr.accountMode.toLocalConfirm,
      primaryBusy: _busy,
      onPrimary: canSubmit ? _submit : null,
      dangerLabel: _forceable ? tr.accountMode.forceConfirm : null,
      onDanger: _forceable && canSubmit ? () => _submit(force: true) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reading the blockers needs Firestore: offline it never resolves,
          // and without this the modal is a disabled button with no reason.
          if (blockers.isLoading) ...[
            Row(
              children: [
                const AppSpinner(size: 16),
                const SizedBox(width: 10),
                Text(
                  tr.accountMode.checking,
                  style: TextStyle(
                    fontSize: AppText.small,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (blockers.hasError) ...[
            Text(
              tr.accountMode.errorOffline,
              style: TextStyle(
                fontSize: AppText.small,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (blocked.isNotEmpty) ...[
            BlockedCongregationsNotice(congregationIds: blocked),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  tr.accountMode.backupHint,
                  style: TextStyle(
                    fontSize: AppText.small,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: t.textMute,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                variant: AppButtonVariant.ghost,
                icon: Icons.file_upload_outlined,
                label: tr.settings.export,
                onPressed: _busy ? null : () => exportBackup(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tr.accountMode.toLocalPassword,
            style: TextStyle(
              fontSize: AppText.small,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: t.textMute,
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: tr.auth.local.name,
            child: BoundTextField(
              initial: '',
              enabled: !_busy,
              autofocus: true,
              hint: tr.auth.local.nameHint,
              onChanged: (v) => setState(() {
                _name = v;
                _error = null;
              }),
            ),
          ),
          const SizedBox(height: 13),
          LabeledField(
            label: tr.auth.local.password,
            child: BoundTextField(
              initial: '',
              enabled: !_busy,
              obscureText: true,
              hint: tr.auth.local.passwordHint,
              onChanged: (v) => setState(() {
                _password = v;
                _error = null;
              }),
            ),
          ),
          const SizedBox(height: 13),
          LabeledField(
            label: tr.auth.local.confirm,
            child: BoundTextField(
              initial: '',
              enabled: !_busy,
              obscureText: true,
              hint: tr.auth.local.confirmHint,
              onChanged: (v) => setState(() {
                _confirm = v;
                _error = null;
              }),
              onSubmitted: (_) => canSubmit ? _submit() : null,
            ),
          ),
          AuthErrorText(_error),
        ],
      ),
    );
  }
}
