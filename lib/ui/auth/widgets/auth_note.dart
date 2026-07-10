import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// `.auth-note`: informative note on an accent-tint card. [spans] lets the
/// copy mix regular and bold runs (e.g. the no-recovery warning).
class AuthNote extends StatelessWidget {
  const AuthNote({super.key, required this.icon, required this.spans});

  final IconData icon;
  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: t.accentTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: t.accentStrong),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: spans),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: t.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
