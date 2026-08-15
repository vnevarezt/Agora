import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../../state/cloud_auth.dart';
import '../../state/sync_provider.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import 'auth_card_layout.dart';
import 'auth_error_mapping.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/auth_switch_line.dart';
import 'widgets/resend_cooldown.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> with ResendCooldown {
  bool _busy = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _check({bool manual = false}) async {
    if (manual && _busy) return;
    final tr = context.t;
    if (manual) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    final auth = await ref.read(cloudAuthProvider.future);
    if (!mounted) return;
    if (auth == null) {
      if (manual) {
        setState(() {
          _busy = false;
          _error = tr.auth.cloud.unavailableDesc;
        });
      }
      return;
    }
    final verified = await auth.refreshEmailVerified();
    if (!mounted) return;
    if (verified) {
      _pollTimer?.cancel();
      await ref.read(authSessionProvider.notifier).completeEmailVerification();
      return;
    }
    if (manual) {
      setState(() {
        _busy = false;
        _error = tr.auth.cloudVerify.notYetVerified;
      });
    }
  }

  Future<void> _resend() async {
    final tr = context.t;
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
      await auth.resendEmailVerification();
      if (!mounted) return;
      setState(() => _busy = false);
      startCooldown();
    } on CloudAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = cloudAuthErrorText(context, e.code);
      });
    } catch (e) {
      debugPrint('Resend verification unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = tr.account.errors.unknown;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await ref.read(cloudSignOutProvider)();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.t.account.errors.unknown;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final t = context.tokens;
    final email = ref.watch(cloudUserProvider).value?.email ?? '';

    return AuthCardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  Icons.mark_email_unread_outlined,
                  size: 26,
                  color: t.textMute,
                ),
              ),
              const SizedBox(height: 12),
              AuthTitle(tr.auth.cloudVerify.title),
              const SizedBox(height: 4),
              AuthSub(
                tr.auth.cloudVerify.caption(email: email),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppButton(
            label: tr.auth.cloudVerify.checkNow,
            height: 46,
            expand: true,
            busy: _busy,
            onPressed: _busy ? null : () => _check(manual: true),
          ),
          const SizedBox(height: 10),
          AppButton(
            variant: AppButtonVariant.ghost,
            label: cooldownLeft > 0
                ? tr.auth.cloudVerify.resendIn(seconds: cooldownLeft)
                : tr.auth.cloudVerify.resend,
            height: 46,
            expand: true,
            onPressed: cooldownLeft > 0 ? null : _resend,
          ),
          AuthErrorText(_error),
          const SizedBox(height: 16),
          AuthSwitchLine(
            text: tr.auth.cloudVerify.signOutQuestion,
            actionLabel: tr.auth.cloudVerify.signOut,
            onTap: _busy ? () {} : _signOut,
          ),
        ],
      ),
    );
  }
}
