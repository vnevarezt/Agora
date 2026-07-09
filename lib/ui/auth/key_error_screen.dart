import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/local_auth.dart';
import '../widgets/app_button.dart';
import 'auth_scaffold.dart';

/// The OS keychain failed (not a wrong password): the encrypted DB cannot be
/// opened at all. Shows the technical detail and offers a retry.
class KeyErrorScreen extends ConsumerWidget {
  const KeyErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.t;
    return AuthScaffold(
      icon: Icons.error_outline,
      title: tr.auth.keyError.title,
      subtitle: message,
      children: [
        AppButton(
          label: tr.auth.keyError.retry,
          expand: true,
          onPressed: () => ref.read(localAuthProvider.notifier).retryInit(),
        ),
      ],
    );
  }
}
