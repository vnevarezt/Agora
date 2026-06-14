import 'package:flutter/material.dart';

/// Breakpoints (mirror of the mock container queries).
const double kMobileBreakpoint = 720;
const double kTabletBreakpoint = 1080;

enum ScreenSize { mobile, tablet, desktop }

extension ResponsiveX on BuildContext {
  /// Screen size based on the window width. Uses [MediaQuery.sizeOf] to
  /// rebuild only when the size changes.
  ScreenSize get screenSize {
    final w = MediaQuery.sizeOf(this).width;
    if (w <= kMobileBreakpoint) return ScreenSize.mobile;
    if (w <= kTabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
}
