import 'package:flutter/material.dart';

import '../../models/week.dart';

/// Dimensiones y constantes visuales del rediseño (espejo del CSS del mock).
abstract final class Dimens {
  // Radios de borde.
  static const double rChip = 7;
  static const double rControl = 10;
  static const double rAssignee = 11;
  static const double rCard = 14;
  static const double rPicker = 16;
  static const double rSheet = 22; // bottom sheet móvil (esquinas superiores)
  static const double rPill = 999;

  // Duraciones de transición.
  static const Duration dFast = Duration(milliseconds: 150);
  static const Duration dPop = Duration(milliseconds: 160);
  static const Duration dSlide = Duration(milliseconds: 180);
  static const Duration dSheet = Duration(milliseconds: 220);

  // Alturas de control.
  static const double hControl = 38; // botones e icon-buttons de la barra
  static const double hField = 40; // inputs del panel de configuración
  static const double hAssignee = 44; // botón de asignación
  static const double hPreviewBar = 46;
  static const double hExportMobile = 48;

  // Otros tamaños.
  static const double avatar = 30;
  static const double ring = 34; // anillo de progreso
  static const double pickerW = 340;
  static const double pickerMaxH = 460;
}

/// Colores identitarios de cada sección del programa (bandas del S-140).
/// `apertura` no lleva color en el mock.
const Map<Seccion, Color> kSectionColors = {
  Seccion.tesoros: Color(0xFF5C5C5C),
  Seccion.seamos: Color(0xFFB9890F),
  Seccion.vida: Color(0xFF8C1B2E),
};
