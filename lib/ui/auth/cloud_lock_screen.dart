import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../../state/cloud_auth.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import 'auth_card_layout.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/auth_switch_line.dart';

/// Cloud mode with the device-unlock gate armed: the Firebase session is
/// alive, but the app asks for Touch ID / Face ID / fingerprint before
/// showing anything. Signing out is the escape hatch (it routes to the
/// cloud sign-in screen).
class CloudLockScreen extends ConsumerStatefulWidget {
  const CloudLockScreen({super.key});

  @override
  ConsumerState<CloudLockScreen> createState() => _CloudLockScreenState();
}

class _CloudLockScreenState extends ConsumerState<CloudLockScreen> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Standard lock-screen UX: offer the OS prompt right away; cancelling it
    // leaves the unlock button to retry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _unlock();
    });
  }

  Future<void> _unlock() async {
    if (_busy) return;
    final tr = context.t;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(authSessionProvider.notifier)
          .unlockWithDeviceAuth(tr.security.unlockPrompt);
      // Success unmounts this screen; cancel just re-enables the button.
      if (!ok && mounted) setState(() => _busy = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = tr.account.errors.unknown;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await (await ref.read(cloudAuthProvider.future))?.signOut();
      // authStateChanges routes the session to CloudSignedOut.
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
                child: Icon(Icons.lock_outline, size: 26, color: t.textMute),
              ),
              const SizedBox(height: 12),
              AuthTitle(tr.auth.cloudLock.title),
              const SizedBox(height: 4),
              AuthSub(tr.auth.cloudLock.caption),
            ],
          ),
          const SizedBox(height: 18),
          AppButton(
            icon: Icons.fingerprint,
            label: tr.auth.cloudLock.unlock,
            height: 46,
            expand: true,
            busy: _busy,
            onPressed: _busy ? null : _unlock,
          ),
          AuthErrorText(_error),
          const SizedBox(height: 16),
          AuthSwitchLine(
            text: tr.auth.cloudLock.signOutQuestion,
            actionLabel: tr.auth.cloudLock.signOut,
            onTap: _busy ? () {} : _signOut,
          ),
        ],
      ),
    );
  }
}
