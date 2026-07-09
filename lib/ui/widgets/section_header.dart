import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Section header (`.section__head`): color dot, uppercase title and
/// assigned/total counter on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.dotColor,
    this.done,
    this.total,
  });

  final String title;
  final Color? dotColor;
  final int? done;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, bottom: 12),
      child: Row(
        children: [
          if (dotColor != null) ...[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.26,
                color: t.text,
              ),
            ),
          ),
          if (total != null && total! > 0)
            Text(
              '${done ?? 0}/$total',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: t.textMute,
              ),
            ),
        ],
      ),
    );
  }
}
