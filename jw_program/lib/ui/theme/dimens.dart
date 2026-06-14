import 'package:flutter/material.dart';

import '../../models/week.dart';

/// Visual dimensions and constants (mirror of the mock CSS).
abstract final class Dimens {
  // Border radii.
  static const double rChip = 7;
  static const double rControl = 10;
  static const double rAssignee = 11;
  static const double rCard = 14;
  static const double rPicker = 16;
  static const double rSheet = 22; // bottom sheet móvil (esquinas superiores)
  static const double rPill = 999;

  // Transition durations.
  static const Duration dFast = Duration(milliseconds: 150);
  static const Duration dPop = Duration(milliseconds: 160);
  static const Duration dSlide = Duration(milliseconds: 180);
  static const Duration dSheet = Duration(milliseconds: 220);

  // Control heights.
  static const double hControl = 38; // botones e icon-buttons de la barra
  static const double hField = 40; // inputs del panel de configuración
  static const double hAssignee = 44; // botón de asignación
  static const double hPreviewBar = 46;
  static const double hExportMobile = 48;

  // Other sizes.
  static const double avatar = 30;
  static const double ring = 34; // anillo de progreso
  static const double pickerW = 340;
  static const double pickerMaxH = 460;
}

/// Identity colors for each program section (S-140 bands).
/// `apertura` has no color in the mock.
const Map<Section, Color> kSectionColors = {
  Section.treasures: Color(0xFF5C5C5C),
  Section.ministry: Color(0xFFB9890F),
  Section.christianLife: Color(0xFF8C1B2E),
};
