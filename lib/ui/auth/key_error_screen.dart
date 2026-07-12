import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/auth_session.dart';
import '../widgets/app_button.dart';
import 'auth_card_layout.dart';

/// The OS keychain failed (not a wrong password): the encrypted DB cannot be
/// opened at all. Shows the technical detail and offers a retry.
class KeyErrorScreen extends ConsumerWidget {
  const KeyErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    return AuthCardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.error_outline,
            size: 34,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 14),
          Center(child: AuthTitle(tr.auth.keyError.title)),
          const SizedBox(height: 6),
          Center(child: AuthSub(message)),
          const SizedBox(height: 22),
          AppButton(
            label: tr.auth.keyError.retry,
            height: 46,
            expand: true,
            onPressed: () => ref.read(authSessionProvider.notifier).retryInit(),
          ),
        ],
      ),
    );
  }
}
