import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'dashed_border.dart';

/// Iniciales de un nombre ("Raúl Espinoza" → "RE").
String inicialesDe(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+'));
  final a = partes.isNotEmpty && partes[0].isNotEmpty ? partes[0][0] : '';
  final b = partes.length > 1 && partes[1].isNotEmpty ? partes[1][0] : '';
  return (a + b).toUpperCase();
}

/// Avatar circular (`.avatar`): iniciales sobre fondo accent-soft, o el
/// estado vacío con borde discontinuo e icono de persona.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, this.nombre, this.size = Dimens.avatar});

  final String? nombre;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final vacio = nombre == null || nombre!.trim().isEmpty;

    if (vacio) {
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
        inicialesDe(nombre!),
        style: TextStyle(
          fontSize: size * 11.5 / Dimens.avatar,
          fontWeight: FontWeight.w800,
          color: t.accentStrong,
        ),
      ),
    );
  }
}
