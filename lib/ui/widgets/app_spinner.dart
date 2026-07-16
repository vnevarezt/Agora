import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Circular loading indicator with consistent proportions; [color] defaults
/// to the accent token.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: (size * 0.13).clamp(2.0, 3.0),
        color: color ?? context.tokens.accent,
      ),
    );
  }
}
