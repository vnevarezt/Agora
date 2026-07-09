import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/cloud_auth.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/modal_shell.dart';
import '../widgets/segmented_control.dart';
import 'auth_scaffold.dart';

/// Email/password sign-in / registration against Firebase, plus Google.
/// Only reachable when the cloud is configured ([cloudAuthProvider] != null).
class CloudSignInModal extends ConsumerStatefulWidget {
  const CloudSignInModal({super.key, required this.sheet, required this.onClose});

  final bool sheet;
  final VoidCallback onClose;

  @override
  ConsumerState<CloudSignInModal> createState() => _CloudSignInModalState();
}

class _CloudSignInModalState extends ConsumerState<CloudSignInModal> {
  int _mode = 0; // 0 = sign in, 1 = register
  String _email = '';
  String _password = '';
  bool _busy = false;
  String? _error;

  String _errorText(CloudAuthErrorCode code) {
    final e = context.t.account.errors;
    return switch (code) {
      CloudAuthErrorCode.invalidEmail => e.invalidEmail,
      CloudAuthErrorCode.userNotFound => e.userNotFound,
      CloudAuthErrorCode.wrongPassword => e.wrongPassword,
      CloudAuthErrorCode.emailInUse => e.emailInUse,
      CloudAuthErrorCode.weakPassword => e.weakPassword,
      CloudAuthErrorCode.network => e.network,
      CloudAuthErrorCode.canceled || CloudAuthErrorCode.unknown => e.unknown,
    };
  }

  Future<void> _run(Future<void> Function(CloudAuthService auth) action) async {
    final auth = ref.read(cloudAuthProvider);
    if (auth == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(auth);
      if (mounted) widget.onClose();
    } on CloudAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // A canceled Google flow is not an error the user needs explained.
        _error = e.code == CloudAuthErrorCode.canceled ? null : _errorText(e.code);
      });
    }
  }

  Future<void> _submit() => _run((auth) => _mode == 0
      ? auth.signInWithEmail(_email.trim(), _password)
      : auth.registerWithEmail(_email.trim(), _password));

  Future<void> _sendReset() async {
    final tr = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final auth = ref.read(cloudAuthProvider);
    if (auth == null) return;
    if (_email.trim().isEmpty) {
      setState(() => _error = tr.account.errors.invalidEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.sendPasswordReset(_email.trim());
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(tr.account.resetSent)));
    } on CloudAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _errorText(e.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final t = context.tokens;
    final googleAvailable = ref.watch(googleSignInAvailableProvider);
    final canSubmit = _email.trim().isNotEmpty && _password.isNotEmpty && !_busy;

    return ModalShell(
      sheet: widget.sheet,
      onClose: widget.onClose,
      title: tr.account.title,
      desc: tr.account.desc,
      primaryLabel: _mode == 0 ? tr.account.signIn : tr.account.register,
      primaryBusy: _busy,
      onPrimary: canSubmit ? _submit : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            segments: [
              (icon: null, label: tr.account.signIn),
              (icon: null, label: tr.account.register),
            ],
            index: _mode,
            onChanged: (i) => setState(() {
              _mode = i;
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: tr.account.email,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() => _email = v),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: tr.account.password,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() => _password = v),
              obscureText: true,
              onSubmitted: (_) => canSubmit ? _submit() : null,
            ),
          ),
          if (_error != null) AuthErrorText(_error!),
          if (_mode == 0) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Pressable(
                onTap: _busy ? null : _sendReset,
                builder: (context, hovered, _) => Text(
                  tr.account.forgotPassword,
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
          if (googleAvailable) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: t.border2)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    tr.account.or,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: t.textMute,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: t.border2)),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              variant: AppButtonVariant.ghost,
              icon: Icons.g_mobiledata,
              label: tr.account.google,
              expand: true,
              onPressed:
                  _busy ? null : () => _run((auth) => auth.signInWithGoogle()),
            ),
          ],
        ],
      ),
    );
  }
}
