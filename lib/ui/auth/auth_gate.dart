import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_session.dart';
import '../theme/tokens.dart';
import 'cloud_auth_screen.dart';
import 'key_error_screen.dart';
import 'local_create_screen.dart';
import 'portada_screen.dart';
import 'unlock_screen.dart';

/// Routes the session: nothing below [child] builds (and therefore nothing
/// can read `dbProvider`) until the session is unlocked.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authSessionProvider);
    return switch (state) {
      SessionLoading() => const _AuthSplash(),
      SessionFreshChoose() => const _AuthFlow(),
      SessionLocalCreate(:final migration) =>
        LocalCreateScreen(migration: migration),
      SessionLocalLocked(:final profileName) =>
        UnlockScreen(profileName: profileName),
      SessionCloudSignedOut() => const CloudAuthScreen(),
      SessionKeyError(:final message) => KeyErrorScreen(message: message),
      SessionUnlocked() => child,
    };
  }
}

enum _FlowStep { choose, local, cloud }

/// Portada + step navigation while no account mode exists yet; a successful
/// sign-up/sign-in flips the session state and unmounts the whole flow.
class _AuthFlow extends StatefulWidget {
  const _AuthFlow();

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow> {
  _FlowStep _step = _FlowStep.choose;
  CloudFormMode _cloudMode = CloudFormMode.login;

  void _go(_FlowStep step, [CloudFormMode? cloudMode]) {
    setState(() {
      _step = step;
      if (cloudMode != null) _cloudMode = cloudMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (_step) {
        _FlowStep.choose => PortadaScreen(
            key: const ValueKey('choose'),
            onCreateAccount: () =>
                _go(_FlowStep.cloud, CloudFormMode.register),
            onSignIn: () => _go(_FlowStep.cloud, CloudFormMode.login),
            onLocal: () => _go(_FlowStep.local),
          ),
        _FlowStep.local => LocalCreateScreen(
            key: const ValueKey('local'),
            migration: false,
            onBack: () => _go(_FlowStep.choose),
          ),
        _FlowStep.cloud => CloudAuthScreen(
            key: ValueKey('cloud-${_cloudMode.name}'),
            initialMode: _cloudMode,
            onBack: () => _go(_FlowStep.choose),
          ),
      },
    );
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: t.accent),
        ),
      ),
    );
  }
}
