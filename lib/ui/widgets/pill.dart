import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
    this.fontSize = AppText.micro,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s8,
        vertical: Space.s2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Dimens.rPill),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        label.toUpperCase(),
        // A badge is one line by construction. Given a width it cannot fit —
        // a long privilege at 2x text, inside a row with a fixed avatar at the
        // other end — it has to give in width, not in height: the participant
        // grid lays out on one tile extent and a card a line taller than its
        // neighbours clips.
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
