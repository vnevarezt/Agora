import 'package:flutter/painting.dart';

/// Congregación a la que pertenece un proyecto. El [color] identifica su punto
/// en los filtros y tarjetas (espejo de `congregations[].color` del mock).
class Congregacion {
  final String id;
  final String nombre;
  final String numero;
  final Color color;

  const Congregacion({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.color,
  });
}
