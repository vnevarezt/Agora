import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

/// Dashboard block title (`.block-title`): uppercase title, "· N" counter
/// and an optional right-aligned link ("Ver todo").
class BlockTitle extends StatelessWidget {
  const BlockTitle({
    super.key,
    required this.title,
    this.count,
    this.linkLabel,
    this.onLink,
  });

  final String title;
  final int? count;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.26,
                color: t.text,
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 7),
            Text(
              '· $count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: t.textMute,
              ),
            ),
          ],
          if (linkLabel != null) ...[
            const Spacer(),
            Pressable(
              onTap: onLink,
              builder: (context, hovered, _) => Text(
                linkLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.accentStrong,
                  decoration: hovered ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
