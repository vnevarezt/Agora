import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_session.dart';
import '../../state/cloud_auth.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/agora_mark.dart';
import '../widgets/app_spinner.dart';
import '../widgets/motion.dart';
import 'cloud_auth_screen.dart';
import 'cloud_lock_screen.dart';
import 'email_verification_screen.dart';
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
    // Warm Firebase up front: init is lazy, and a button tapped mid-init
    // would otherwise read null and report the cloud as unconfigured.
    ref.watch(firebaseAppProvider);
    final state = ref.watch(authSessionProvider);
    return FadeThroughSwitcher(
      child: KeyedSubtree(
        key: ValueKey(state.runtimeType),
        child: switch (state) {
          SessionLoading() => const _AuthSplash(),
          SessionFreshChoose() => const _AuthFlow(),
          SessionLocalCreate(:final migration) => LocalCreateScreen(
            migration: migration,
          ),
          SessionLocalLocked(:final profileName, :final deviceUnlock) =>
            UnlockScreen(profileName: profileName, deviceUnlock: deviceUnlock),
          SessionCloudSignedOut() => const CloudAuthScreen(),
          SessionCloudLocked() => const CloudLockScreen(),
          SessionCloudUnverified() => const EmailVerificationScreen(),
          SessionKeyError(:final message) => KeyErrorScreen(message: message),
          SessionUnlocked() => child,
        },
      ),
    );
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
  bool _popping = false;

  void _go(_FlowStep step, [CloudFormMode? cloudMode]) {
    setState(() {
      _popping = step == _FlowStep.choose;
      _step = step;
      if (cloudMode != null) _cloudMode = cloudMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideSwitcher(
      reverse: _popping,
      child: switch (_step) {
        _FlowStep.choose => PortadaScreen(
          key: const ValueKey('choose'),
          onCreateAccount: () => _go(_FlowStep.cloud, CloudFormMode.register),
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

/// The mark plays its entrance, and the spinner only joins it once that has
/// finished. Most boots resolve inside the animation, and a spinner that
/// flashes for a fifth of a second reads as a stutter rather than as progress
/// — but a boot that outlasts the mark still has to say it is working.
class _AuthSplash extends StatefulWidget {
  const _AuthSplash();

  @override
  State<_AuthSplash> createState() => _AuthSplashState();
}

class _AuthSplashState extends State<_AuthSplash> {
  bool _settled = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Well above AppIcon.hero: this is the one surface where the mark
            // carries the screen on its own.
            AgoraMarkEntrance(
              size: Dimens.markSplash,
              onEnd: () => setState(() => _settled = true),
            ),
            // The spinner keeps its space from the first frame, so arriving
            // does not shunt the mark upwards.
            const SizedBox(height: Space.s24),
            AnimatedOpacity(
              opacity: _settled ? 1 : 0,
              duration: Motion.of(context, Motion.med),
              curve: Motion.curve,
              child: const AppSpinner(size: Dimens.spinnerLarge),
            ),
          ],
        ),
      ),
    );
  }
}
