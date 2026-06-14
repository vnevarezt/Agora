import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'dashed_border.dart';

/// Initials of a name ("Raúl Espinoza" -> "RE").
String inicialesDe(String name) {
  final partes = name.trim().split(RegExp(r'\s+'));
  final a = partes.isNotEmpty && partes[0].isNotEmpty ? partes[0][0] : '';
  final b = partes.length > 1 && partes[1].isNotEmpty ? partes[1][0] : '';
  return (a + b).toUpperCase();
}

/// Avatar circular (`.avatar`): iniciales sobre fondo accent-soft, o el
/// empty state with a dashed border and a person icon.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, this.name, this.size = Dimens.avatar});

  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final empty = name == null || name!.trim().isEmpty;

    if (empty) {
      return DashedBorder(
        color: t.border,
        radius: size / 2,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.person_outline, size: size / 2, color: t.textMute),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.accentSoft, shape: BoxShape.circle),
      child: Text(
        inicialesDe(name!),
        style: TextStyle(
          fontSize: size * 11.5 / Dimens.avatar,
          fontWeight: FontWeight.w800,
          color: t.accentStrong,
        ),
      ),
    );
  }
}
