import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../../state/cloud_auth.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/motion.dart';
import 'auth_card_layout.dart';
import 'auth_validation.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/auth_switch_line.dart';
import 'widgets/back_link.dart';
import 'widgets/google_button.dart';
import 'widgets/mode_pill.dart';

enum CloudFormMode { login, register }

/// Cloud-mode gate: Firebase sign-in IS the session. Reached from the
/// Portada ([onBack] set) or when a cloud-mode install has no Firebase
/// session ([onBack] null).
class CloudAuthScreen extends ConsumerStatefulWidget {
  const CloudAuthScreen({
    super.key,
    this.initialMode = CloudFormMode.login,
    this.onBack,
  });

  final CloudFormMode initialMode;
  final VoidCallback? onBack;

  @override
  ConsumerState<CloudAuthScreen> createState() => _CloudAuthScreenState();
}

class _CloudAuthScreenState extends ConsumerState<CloudAuthScreen> {
  late CloudFormMode _mode = widget.initialMode;

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final login = _mode == CloudFormMode.login;

    return AuthCardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onBack != null) ...[
            BackLink(label: tr.auth.chooseOther, onTap: widget.onBack!),
            const SizedBox(height: 16),
          ],
          ModePill(icon: Icons.cloud_outlined, label: tr.auth.cloud.pill),
          const SizedBox(height: 14),
          FadeThroughSwitcher(
            duration: Motion.fast,
            child: Column(
              key: ValueKey(_mode),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthTitle(
                  login
                      ? tr.auth.cloud.loginTitle
                      : tr.auth.cloud.registerTitle,
                ),
                const SizedBox(height: 6),
                AuthSub(
                  login ? tr.auth.cloud.loginSub : tr.auth.cloud.registerSub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          CloudAuthForm(
            mode: _mode,
            onSuccess: () =>
                ref.read(authSessionProvider.notifier).completeCloudSignIn(),
          ),
          const SizedBox(height: 16),
          AuthSwitchLine(
            text: login ? tr.auth.cloud.noAccount : tr.auth.cloud.hasAccount,
            actionLabel: login ? tr.auth.cloud.register : tr.auth.cloud.login,
            onTap: () => setState(
              () =>
                  _mode = login ? CloudFormMode.register : CloudFormMode.login,
            ),
          ),
        ],
      ),
    );
  }
}

/// Google + email form, shared between the gate screen and the Settings
/// modal. [onSuccess] runs after Firebase confirms the sign-in.
class CloudAuthForm extends ConsumerStatefulWidget {
  const CloudAuthForm({super.key, required this.mode, required this.onSuccess});

  final CloudFormMode mode;
  final VoidCallback onSuccess;

  @override
  ConsumerState<CloudAuthForm> createState() => _CloudAuthFormState();
}

class _CloudAuthFormState extends ConsumerState<CloudAuthForm> {
  static const _minLength = 8;

  String _name = '';
  String _email = '';
  String _password = '';
  String _confirm = '';
  bool _busy = false;
  bool _googleBusy = false; // which control shows the spinner
  String? _error;

  bool get _login => widget.mode == CloudFormMode.login;

  bool get _canSubmit {
    if (_busy || _email.trim().isEmpty || _password.isEmpty) return false;
    if (_login) return true;
    return _name.trim().isNotEmpty && _confirm.isNotEmpty;
  }

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

  Future<void> _run(
    Future<void> Function(CloudAuthService auth) action, {
    bool google = false,
  }) async {
    setState(() {
      _busy = true;
      _googleBusy = google;
      _error = null;
    });
    final auth = await ref.read(cloudAuthProvider.future);
    if (!mounted) return;
    if (auth == null) {
      // UI is always shown; without a Firebase config the attempt explains
      // itself instead of hiding the whole cloud mode.
      setState(() {
        _busy = false;
        _googleBusy = false;
        _error = context.t.auth.cloud.unavailableDesc;
      });
      return;
    }
    try {
      await action(auth);
      if (mounted) widget.onSuccess();
    } on CloudAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _googleBusy = false;
        // A canceled Google flow is not an error the user needs explained.
        _error = e.code == CloudAuthErrorCode.canceled
            ? null
            : _errorText(e.code);
      });
    } catch (e) {
      // Never strand the form busy on an unexpected (non-Firebase) failure.
      debugPrint('Cloud auth unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _googleBusy = false;
        _error = context.t.account.errors.unknown;
      });
    }
  }

  Future<void> _submit() async {
    final tr = context.t;
    if (!isValidEmail(_email)) {
      setState(() => _error = tr.account.errors.invalidEmail);
      return;
    }
    if (!_login) {
      if (_password.length < _minLength) {
        setState(() => _error = tr.auth.cloud.passwordHintRegister);
        return;
      }
      if (_password != _confirm) {
        setState(() => _error = tr.auth.local.mismatch);
        return;
      }
    }
    await _run(
      (auth) => _login
          ? auth.signInWithEmail(_email.trim(), _password)
          : auth.registerWithEmail(
              _email.trim(),
              _password,
              displayName: _name.trim(),
            ),
    );
  }

  Future<void> _sendReset() async {
    final tr = context.t;
    final messenger = ScaffoldMessenger.of(context);
    if (!isValidEmail(_email)) {
      setState(() => _error = tr.account.errors.invalidEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = await ref.read(cloudAuthProvider.future);
    if (!mounted) return;
    if (auth == null) {
      setState(() {
        _busy = false;
        _error = tr.auth.cloud.unavailableDesc;
      });
      return;
    }
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
    } catch (e) {
      debugPrint('Password reset unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = tr.account.errors.unknown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final t = context.tokens;
    // Windows has no google_sign_in implementation. On macOS the Google SDK
    // stores its session in the data-protection keychain, which requires a
    // provisioning profile — unavailable on free Apple accounts; hidden until
    // the app is signed with a paid team profile.
    final googleAvailable = defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.macOS;

    return AnimatedSize(
      duration: Motion.med,
      curve: Motion.curve,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (googleAvailable) ...[
            GoogleButton(
              label: tr.auth.cloud.google,
              busy: _googleBusy,
              onPressed: _busy
                  ? null
                  : () =>
                      _run((auth) => auth.signInWithGoogle(), google: true),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(child: Divider(color: t.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    tr.auth.cloud.orEmail.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.58,
                      color: t.textMute,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: t.border)),
              ],
            ),
            const SizedBox(height: 13),
          ],
          if (!_login) ...[
            LabeledField(
              label: tr.auth.cloud.name,
              child: BoundTextField(
                initial: '',
                onChanged: (v) => setState(() {
                  _name = v;
                  _error = null;
                }),
                hint: tr.auth.cloud.nameHint,
              ),
            ),
            const SizedBox(height: 13),
          ],
          LabeledField(
            label: tr.auth.cloud.email,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _email = v;
                _error = null;
              }),
              hint: tr.auth.cloud.emailHint,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 13),
          LabeledField(
            label: tr.auth.cloud.password,
            child: BoundTextField(
              initial: '',
              onChanged: (v) => setState(() {
                _password = v;
                _error = null;
              }),
              hint: _login
                  ? tr.auth.cloud.passwordHintLogin
                  : tr.auth.cloud.passwordHintRegister,
              obscureText: true,
              onSubmitted: (_) => _canSubmit ? _submit() : null,
            ),
          ),
          if (_login)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Pressable(
                  onTap: _busy ? null : _sendReset,
                  builder: (context, hovered, _) => Text(
                    tr.auth.cloud.forgot,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: t.accentStrong,
                      decoration: hovered ? TextDecoration.underline : null,
                      decorationColor: t.accentStrong,
                    ),
                  ),
                ),
              ),
            ),
          if (!_login) ...[
            const SizedBox(height: 13),
            LabeledField(
              label: tr.auth.cloud.confirm,
              child: BoundTextField(
                initial: '',
                onChanged: (v) => setState(() {
                  _confirm = v;
                  _error = null;
                }),
                hint: tr.auth.cloud.confirmHint,
                obscureText: true,
                onSubmitted: (_) => _canSubmit ? _submit() : null,
              ),
            ),
          ],
          AuthErrorText(_error),
          const SizedBox(height: 13),
          AppButton(
            label: _login
                ? tr.auth.cloud.loginButton
                : tr.auth.cloud.registerButton,
            height: 46,
            expand: true,
            busy: _busy && !_googleBusy,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
