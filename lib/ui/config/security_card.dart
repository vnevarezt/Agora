import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/db_key_manager.dart';
import '../../data/device_auth.dart';
import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../auth/widgets/auth_error_text.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import 'settings_card.dart';

/// Settings card for session security. Local mode: change password (re-wraps
/// the DB key), device unlock and lock now. Cloud mode: device unlock as the
/// app gate (the Firebase password lives with Firebase), plus lock now while
/// the gate is on.
class SecurityCard extends ConsumerWidget {
  const SecurityCard({super.key});

  Future<void> _toggleDeviceUnlock(
      BuildContext context, WidgetRef ref, bool enable) async {
    final tr = context.t;
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Cancelling the OS prompt leaves the state (and the switch) as-is.
      await ref
          .read(authSessionProvider.notifier)
          .setDeviceUnlock(enable, tr.security.deviceUnlockPrompt);
    } on DbKeyException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger
          .showSnackBar(SnackBar(content: Text(tr.account.errors.unknown)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    final session = ref.watch(authSessionProvider);
    final unlocked = session is SessionUnlocked ? session : null;
    final localMode = unlocked?.mode == AccountMode.local;
    final deviceUnlockOn = unlocked?.deviceUnlockEnabled ?? false;
    final deviceAuthOk =
        ref.watch(deviceAuthSupportedProvider).value ?? false;

    return SettingsCard(
      title: tr.security.title,
      desc: localMode ? tr.security.desc : tr.security.descCloud,
      children: [
        if (localMode)
          SettingRow(
            first: true,
            title: tr.security.changePassword,
            subtitle: tr.security.changePasswordDesc,
            trailing: AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.key_outlined,
              label: tr.security.change,
              onPressed: () => showAppModal<void>(
                context,
                builder: (ctx, sheet, close) =>
                    _ChangePasswordModal(sheet: sheet, onClose: close),
              ),
            ),
          ),
        if (deviceAuthOk)
          SettingRow(
            first: !localMode,
            title: tr.security.deviceUnlock,
            subtitle: localMode
                ? tr.security.deviceUnlockDesc
                : tr.security.deviceUnlockDescCloud,
            trailing: Transform.scale(
              scale: 0.85,
              child: Switch(
                value: deviceUnlockOn,
                onChanged: (v) => _toggleDeviceUnlock(context, ref, v),
              ),
            ),
          ),
        // Locking a cloud session only means something while the gate is on;
        // without it there is nothing the lock screen could ask for.
        if (localMode || deviceUnlockOn)
          SettingRow(
            title: tr.security.lockNow,
            subtitle: localMode
                ? tr.security.lockNowDesc
                : tr.security.lockNowDescCloud,
            trailing: AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.lock_outline,
              label: tr.security.lock,
              onPressed: () => ref.read(authSessionProvider.notifier).lock(),
            ),
          ),
      ],
    );
  }
}

class _ChangePasswordModal extends ConsumerStatefulWidget {
  const _ChangePasswordModal({required this.sheet, required this.onClose});

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<_ChangePasswordModal> createState() =>
      _ChangePasswordModalState();
}

class _ChangePasswordModalState extends ConsumerState<_ChangePasswordModal> {
  static const _minLength = 8;

  String _current = '';
  String _next = '';
  String _confirm = '';
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final tr = context.t;
    final messenger = ScaffoldMessenger.of(context);
    if (_next.length < _minLength) {
      setState(() => _error = tr.auth.local.tooShort);
      return;
    }
    if (_next != _confirm) {
      setState(() => _error = tr.auth.local.mismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .changePassword(_current, _next);
      if (!mounted) return;
      widget.onClose();
      messenger.showSnackBar(SnackBar(content: Text(tr.security.changed)));
    } on WrongPasswordException {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = tr.security.wrongCurrent;
        });
      }
    } on DbKeyException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = tr.account.errors.unknown;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final canSubmit =
        _current.isNotEmpty &&
        _next.isNotEmpty &&
        _confirm.isNotEmpty &&
        !_busy;

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.security.changePassword,
      desc: tr.auth.local.note1 + tr.auth.local.noteBold + tr.auth.local.note2,
      primaryLabel: tr.security.change,
      primaryBusy: _busy,
      onPrimary: canSubmit ? _submit : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: tr.security.current,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _current = v;
                _error = null;
              }),
              obscureText: true,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: tr.security.newPassword,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _next = v;
                _error = null;
              }),
              obscureText: true,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: tr.security.confirmNew,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _confirm = v;
                _error = null;
              }),
              obscureText: true,
              onSubmitted: (_) => canSubmit ? _submit() : null,
            ),
          ),
          AuthErrorText(_error),
        ],
      ),
    );
  }
}
