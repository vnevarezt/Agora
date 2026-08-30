import 'package:flutter/material.dart';

import '../theme/dimens.dart';

/// Label pill/badge: uppercase text with background/foreground colors.
/// Shared base for StatusBadge, PrivBadge and the "Incompleto" badge.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    // 10, not [AppText.micro]'s 10.5, and the one place in the app under the
    // floor the type scale calls a floor. Raising it overflows the privilege
    // row on the participant card by 5px at 2x text — the card is the thing
    // that has to give, and that is a density decision on that screen rather
    // than a token change here. See DESIGN_SYSTEM.md §13.
    this.fontSize = 10,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s8, vertical: Space.s2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Dimens.rPill),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: foreground,
        ),
      ),
    );
  }
}
