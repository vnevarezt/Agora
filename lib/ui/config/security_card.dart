import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/db_key_manager.dart';
import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../auth/widgets/auth_error_text.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import 'settings_card.dart';

/// Settings card for the local account: change password (re-wraps the DB key)
/// and lock the session immediately.
class SecurityCard extends ConsumerWidget {
  const SecurityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    return SettingsCard(
      title: tr.security.title,
      desc: tr.security.desc,
      children: [
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
        SettingRow(
          title: tr.security.lockNow,
          subtitle: tr.security.lockNowDesc,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final canSubmit =
        _current.isNotEmpty && _next.isNotEmpty && _confirm.isNotEmpty && !_busy;

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
              onChanged: (v) => setState(() => _current = v),
              obscureText: true,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: tr.security.newPassword,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() => _next = v),
              obscureText: true,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: tr.security.confirmNew,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() => _confirm = v),
              obscureText: true,
              onSubmitted: (_) => canSubmit ? _submit() : null,
            ),
          ),
          if (_error != null) AuthErrorText(_error!),
        ],
      ),
    );
  }
}
