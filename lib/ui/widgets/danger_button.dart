import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import 'app_button.dart';
import 'motion.dart';

/// Destructive action: [AppButton] has no danger variant.
class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.onTap, this.label});

  final VoidCallback onTap;

  /// Defaults to the localized "Delete" when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final err = Theme.of(context).colorScheme.error;
    final label = this.label ?? context.t.common.delete;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => AnimatedContainer(
        duration: Motion.instant,
        height: Dimens.hControl,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered ? err.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimens.rControl),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppText.body,
            fontWeight: FontWeight.w700,
            color: err,
          ),
        ),
      ),
    );
  }
}
