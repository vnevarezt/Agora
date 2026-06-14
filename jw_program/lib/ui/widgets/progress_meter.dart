import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Linear progress bar (`.meter`): `border2` track and `accent` fill,
/// both fully rounded.
class ProgressMeter extends StatelessWidget {
  const ProgressMeter({super.key, required this.value, this.height = 5});

  /// Progress fraction 0..1.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: t.border2)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1).toDouble(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
