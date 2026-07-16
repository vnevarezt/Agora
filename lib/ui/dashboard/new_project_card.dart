import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/dashed_border.dart';
import '../widgets/ink_surface.dart';

/// "Nuevo proyecto" card (`.project--new`): dashed border and a "+" ring.
/// The creation modal comes in a later phase; for now [onTap] stays
/// como gancho opcional.
class NewProjectCard extends StatelessWidget {
  const NewProjectCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkSurface(
      onTap: onTap,
      borderRadius: 16,
      color: Colors.transparent,
      borderColor: Colors.transparent,
      hoverBorderColor: Colors.transparent,
      hoverElevation: 0,
      builder: (context, hovered) {
        final fg = hovered ? t.accentStrong : t.textMute;
        return DashedBorder(
          color: hovered ? t.accent : t.border,
          radius: 16,
          strokeWidth: 1.5,
          child: AnimatedContainer(
            duration: Dimens.dFast,
            constraints: const BoxConstraints(minHeight: 158),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hovered ? t.accentTint : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DashedBorder(
                  color: hovered ? t.accent : t.border,
                  radius: 20,
                  strokeWidth: 1.5,
                  child: AnimatedContainer(
                    duration: Dimens.dFast,
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hovered ? t.accentSoft : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, size: 18, color: fg),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  context.t.dashboard.newProject,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
