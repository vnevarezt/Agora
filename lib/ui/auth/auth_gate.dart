import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/local_auth.dart';
import '../theme/tokens.dart';
import 'create_account_screen.dart';
import 'key_error_screen.dart';
import 'unlock_screen.dart';

/// Routes the local session: nothing below [child] builds (and therefore
/// nothing can read [dbProvider]) until the session is unlocked.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localAuthProvider);
    return switch (state) {
      LocalAuthLoading() => const _AuthSplash(),
      LocalAuthFreshSetup() => const CreateAccountScreen(migration: false),
      LocalAuthMigration() => const CreateAccountScreen(migration: true),
      LocalAuthLocked() => const UnlockScreen(),
      LocalAuthKeyError(:final message) => KeyErrorScreen(message: message),
      LocalAuthUnlocked() => child,
    };
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
