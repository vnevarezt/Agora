import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/cloud_auth.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import 'auth_card_layout.dart';
import 'auth_error_mapping.dart';
import 'auth_validation.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/back_link.dart';
import 'widgets/resend_cooldown.dart';

class PasswordResetPanel extends ConsumerStatefulWidget {
  const PasswordResetPanel({
    super.key,
    required this.onBack,
    this.initialEmail = '',
  });

  final ValueChanged<String> onBack;
  final String initialEmail;

  @override
  ConsumerState<PasswordResetPanel> createState() =>
      _PasswordResetPanelState();
}

class _PasswordResetPanelState extends ConsumerState<PasswordResetPanel>
    with ResendCooldown {
  late String _email = widget.initialEmail;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  Future<void> _submit() async {
    final tr = context.t;
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
      setState(() {
        _busy = false;
        _sent = true;
      });
      startCooldown();
    } on CloudAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = cloudAuthErrorText(context, e.code);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackLink(
          label: tr.auth.cloud.backToLogin,
          onTap: () => widget.onBack(_email.trim()),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.surface,
                shape: BoxShape.circle,
                border: Border.all(color: t.border),
              ),
              child: Icon(
                _sent ? Icons.mark_email_read_outlined : Icons.lock_reset,
                size: 26,
                color: t.textMute,
              ),
            ),
            const SizedBox(height: 12),
            AuthTitle(
              _sent ? tr.auth.cloud.resetSentTitle : tr.auth.cloud.resetTitle,
            ),
            const SizedBox(height: 4),
            AuthSub(
              _sent
                  ? tr.auth.cloud.resetSentDesc(email: _email.trim())
                  : tr.auth.cloud.resetSub,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (_sent) ...[
          AppButton(
            label: tr.auth.cloud.loginButton,
            height: 46,
            expand: true,
            onPressed: () => widget.onBack(_email.trim()),
          ),
          const SizedBox(height: 10),
          AppButton(
            variant: AppButtonVariant.ghost,
            label: cooldownLeft > 0
                ? tr.auth.cloud.resetResendIn(seconds: cooldownLeft)
                : tr.auth.cloud.resetResend,
            height: 46,
            expand: true,
            busy: _busy,
            onPressed: _busy || cooldownLeft > 0 ? null : _submit,
          ),
        ] else ...[
          LabeledField(
            label: tr.auth.cloud.email,
            child: BoundTextField(
              initial: _email,
              onChanged: (v) => setState(() {
                _email = v;
                _error = null;
              }),
              hint: tr.auth.cloud.emailHint,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              onSubmitted: (_) => _busy ? null : _submit(),
            ),
          ),
          const SizedBox(height: 13),
          AppButton(
            label: tr.auth.cloud.resetButton,
            height: 46,
            expand: true,
            busy: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
        AuthErrorText(_error),
      ],
    );
  }
}
