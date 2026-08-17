import 'package:flutter/material.dart';

import '../../models/week.dart';

/// The spacing scale: padding, gaps and insets. **A bare number for a gap is
/// drift**, the same rule the type and icon scales already carry.
///
/// Named by magnitude rather than by role, because spacing has no roles — only
/// distances. The nine steps are the values the UI already leaned on (6, 8, 10,
/// 12 and 14 alone covered 208 of 434 uses); what they replace is the 28-value
/// spread around them, half of it odd, where 9, 11 and 13 sat between the real
/// steps for no reason anyone could name.
///
/// 1px is deliberately absent: a hairline is a border, not a gap.
abstract final class Space {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s18 = 18;
  static const double s24 = 24;
}

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

  // Durations live in Motion (widgets/motion.dart), which is the single
  // duration scale. Dimens carries sizes only.

  // Control heights.
  static const double hControl = 38; // botones e icon-buttons de la barra
  static const double hField = 40; // inputs del panel de configuración
  static const double hAssignee = 44; // botón de asignación
  static const double hPreviewBar = 46;
  static const double hExportMobile = 48;

  /// Minimum tap-target side (48dp Android / 44pt iOS — 48 is the stricter
  /// floor). Controls that paint smaller than this still need a hit area at
  /// least this big; see [AppIconButton] and `AppSwitch`.
  static const double hTouchMin = 48;

  // Other sizes.
  static const double avatar = 30;
  static const double ring = 34; // anillo de progreso
  static const double pickerW = 340;
  static const double pickerMaxH = 460;
}

/// The complete elevation vocabulary. Surfaces are flat at rest and depth
/// normally comes from the bg → surface → surface2 layering plus borders;
/// these five shadows are the only exceptions, ordered by how far the surface
/// sits off the canvas. Anything that needs a shadow uses one of them — a
/// one-off `BoxShadow` is design drift.
abstract final class Elevation {
  /// Resting lift under a primary control, just enough to separate it.
  static const List<BoxShadow> control = [
    BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// A control that floats over content (preview zoom, small FAB).
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Menus, dropdowns and pickers anchored to a trigger.
  static const List<BoxShadow> popover = [
    BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Modal sheets and dialogs: a wide ambient pool plus a tighter contact
  /// shadow, so the surface reads as lifted rather than pasted on.
  static const List<BoxShadow> modal = [
    BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// The PDF page in the preview — physical paper lifted off the canvas.
  static const List<BoxShadow> page = [
    BoxShadow(color: Color(0x24000000), blurRadius: 30, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Halo around the card the editor is working on. Not a shadow — it has no
  /// blur, it is a ring — but it belongs here so it stops being a one-off
  /// `BoxShadow` at the call site. Takes the accent so it reads on both
  /// grounds: the accentSoft it used to use sits at 1.5:1 on the dark
  /// surface, which made the active card look no different from the rest.
  static List<BoxShadow> selectionHalo(Color accent) => [
        BoxShadow(color: accent.withValues(alpha: 0.30), spreadRadius: 3),
      ];

  /// Scrim behind an anchored panel.
  static const Color scrim = Color(0x47000000);

  /// Scrim behind a full modal, which must dim more of the app.
  static const Color scrimStrong = Color(0x52000000);

  /// For `Material.shadowColor`, which takes a single colour and derives the
  /// blur from its own `elevation` instead of a [BoxShadow] list.
  static const Color materialShadow = Color(0x40000000);
}

/// Identity colors for each program section (S-140 bands).
/// `apertura` has no color in the mock.
const Map<Section, Color> kSectionColors = {
  Section.treasures: Color(0xFF5C5C5C),
  Section.ministry: Color(0xFFB9890F),
  Section.christianLife: Color(0xFF8C1B2E),
};
