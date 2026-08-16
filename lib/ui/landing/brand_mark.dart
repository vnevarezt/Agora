import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.accent,
        borderRadius: BorderRadius.circular(size * 8 / 26),
        boxShadow: Elevation.control,
      ),
      child: Text(
        'A',
        style: TextStyle(
          fontSize: size * 14 / 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1,
          color: t.accentInk,
        ),
      ),
    );
  }
}
