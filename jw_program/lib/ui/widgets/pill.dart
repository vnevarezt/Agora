import 'package:flutter/material.dart';

import '../theme/dimens.dart';

/// Píldora/insignia con label en mayúsculas y colores de fondo/texto.
/// Base compartida por StatusBadge, PrivBadge y la insignia "Incompleto".
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    this.fontSize = 10,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Dimens.rPill),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: foreground,
        ),
      ),
    );
  }
}
