import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/db_key_manager.dart';
import '../../i18n/strings.g.dart';
import '../../state/local_auth.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import 'auth_scaffold.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  String _password = '';
  bool _busy = false;
  String? _error;

  Future<void> _unlock() async {
    final tr = context.t;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(localAuthProvider.notifier).unlock(_password);
      // Success: AuthGate swaps this screen out.
    } on WrongPasswordException {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = tr.auth.unlock.wrongPassword;
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
    final t = context.tokens;
    final canSubmit = _password.isNotEmpty && !_busy;

    return AuthScaffold(
      icon: Icons.lock_outline,
      title: tr.auth.unlock.title,
      subtitle: tr.auth.unlock.subtitle,
      children: [
        LabeledField(
          label: tr.auth.unlock.password,
          child: BoundTextField(
            initial: '',
            onChanged: (v) => setState(() => _password = v),
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => canSubmit ? _unlock() : null,
          ),
        ),
        if (_error != null) AuthErrorText(_error!),
        const SizedBox(height: 18),
        AppButton(
          label: _busy ? tr.auth.unlock.working : tr.auth.unlock.button,
          expand: true,
          busy: _busy,
          onPressed: canSubmit ? _unlock : null,
        ),
        const SizedBox(height: 10),
        Center(
          child: Pressable(
            onTap: _busy ? null : () => _showResetModal(context),
            builder: (context, hovered, _) => Text(
              tr.auth.unlock.forgot,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: hovered ? t.text : t.textMute,
                decoration: hovered ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
      ],
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

/// "Forgot password" — the data is unrecoverable by design. Deleting
/// everything is the only way forward, gated by typing a confirm phrase.
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
    await ref.read(localAuthProvider.notifier).resetAllData();
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
