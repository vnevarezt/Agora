import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/db_key_manager.dart';
import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/avatar.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import 'auth_card_layout.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/auth_switch_line.dart';

/// Local-mode unlock: existing profile header + password.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key, required this.profileName});

  final String? profileName;

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  String _password = '';
  bool _busy = false;
  String? _error;

  bool get _canSubmit => _password.isNotEmpty && !_busy;

  Future<void> _unlock() async {
    final tr = context.t;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authSessionProvider.notifier).unlock(_password);
      // Success: AuthGate swaps this screen out.
    } on WrongPasswordException {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = tr.auth.local.wrongPassword;
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
    final t = context.tokens;
    final name = widget.profileName?.trim();

    return AuthCardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              PersonAvatar(name: name, size: 62),
              const SizedBox(height: 10),
              if (name != null && name.isNotEmpty)
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                tr.auth.local.profileCaption,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textMute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: tr.auth.local.password,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _password = v;
                _error = null;
              }),
              hint: tr.auth.cloud.passwordHintLogin,
              obscureText: true,
              autofocus: true,
              onSubmitted: (_) => _canSubmit ? _unlock() : null,
            ),
          ),
          AuthErrorText(_error),
          const SizedBox(height: 13),
          AppButton(
            label: _busy ? tr.auth.local.unlocking : tr.auth.local.unlockButton,
            height: 46,
            expand: true,
            busy: _busy,
            onPressed: _canSubmit ? _unlock : null,
          ),
          const SizedBox(height: 16),
          AuthSwitchLine(
            text: tr.auth.local.startOver,
            actionLabel: tr.auth.local.createAnother,
            onTap: _busy ? () {} : () => _showResetModal(context),
          ),
        ],
      ),
    );
  }

  void _showResetModal(BuildContext context) {
    showAppModal<void>(
      context,
      builder: (ctx, sheet, close) =>
          _ResetDataModal(sheet: sheet, onClose: close),
    );
  }
}

/// "Start over" — the data is unrecoverable by design. Deleting everything is
/// the only way forward, gated by typing a confirm phrase.
class _ResetDataModal extends ConsumerStatefulWidget {
  const _ResetDataModal({required this.sheet, required this.onClose});

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<_ResetDataModal> createState() => _ResetDataModalState();
}

class _ResetDataModalState extends ConsumerState<_ResetDataModal> {
  String _typed = '';
  bool _busy = false;

  Future<void> _reset() async {
    setState(() => _busy = true);
    await ref.read(authSessionProvider.notifier).resetAllData();
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final phrase = tr.auth.reset.confirmPhrase;
    final confirmed = _typed.trim() == phrase;

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.auth.reset.title,
      desc: tr.auth.reset.warning,
      primaryLabel: tr.auth.reset.button,
      primaryBusy: _busy,
      onPrimary: confirmed && !_busy ? _reset : null,
      body: LabeledField(
        label: tr.auth.reset.confirmHint(phrase: phrase),
        child: BoundTextField(
          initial: '',
          onChanged: (v) => setState(() => _typed = v),
          autofocus: true,
        ),
      ),
    );
  }
}
