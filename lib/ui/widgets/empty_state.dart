import '../theme/dimens.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Reusable empty state: icon + (optional title) + message + (optional
/// action) + (optional error text). Centers its content.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.action,
    this.error,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Widget? action;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIcon.hero, color: t.textMute),
            const SizedBox(height: Space.s12),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: AppText.bodyLarge, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: Space.s4),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: AppText.body, fontWeight: FontWeight.w600, color: t.textMute),
            ),
            if (action != null) ...[
              const SizedBox(height: Space.s18),
              action!,
            ],
            if (error != null) ...[
              const SizedBox(height: Space.s14),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppText.small,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
