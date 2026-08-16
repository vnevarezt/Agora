import '../../theme/dimens.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';

/// Inline error line under a form field. Accepts null so call sites can keep
/// it mounted; appearing/disappearing animates instead of jumping.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return MotionSize(
      duration: Motion.fast,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: Space.s10),
              child: Text(
                message!,
                style: TextStyle(
                  fontSize: AppText.small,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
    );
  }
}
