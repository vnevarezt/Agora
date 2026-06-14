import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import 'app_button.dart';

/// Destructive-action button in the error color (no danger variant in
/// [AppButton]). Used by the project and participant modal footers.
class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.onTap, this.label = 'Eliminar'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final err = Theme.of(context).colorScheme.error;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => AnimatedContainer(
        duration: Dimens.dFast,
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
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: err,
          ),
        ),
      ),
    );
  }
}
