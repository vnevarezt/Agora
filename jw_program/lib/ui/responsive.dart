import 'package:flutter/material.dart';

/// Breakpoints del rediseño (espejo de las container queries del mock).
const double kMobileBreakpoint = 720;
const double kTabletBreakpoint = 1080;

enum ScreenSize { mobile, tablet, desktop }

extension ResponsiveX on BuildContext {
  /// Tamaño de pantalla según el ancho de la ventana. Usa
  /// [MediaQuery.sizeOf] para reconstruir solo when cambia el tamaño.
  ScreenSize get screenSize {
    final w = MediaQuery.sizeOf(this).width;
    if (w <= kMobileBreakpoint) return ScreenSize.mobile;
    if (w <= kTabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
}
