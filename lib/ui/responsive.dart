import 'package:flutter/material.dart';

/// Window breakpoints. These describe the app window, so anything deciding
/// what the *screen* looks like belongs here — use [ResponsiveX.screenSize]
/// or [ResponsiveX.isMobile] rather than reading `MediaQuery` width directly,
/// which is how a stray `>= 1100` ended up disagreeing with
/// [kTabletBreakpoint] by 20px.
///
/// A component deciding how to lay out inside its own box is a different
/// question: that is a container query, it belongs in a `LayoutBuilder`, and
/// its threshold belongs in [ContainerWidth] below.
const double kMobileBreakpoint = 720;
const double kTabletBreakpoint = 1080;

/// Large external displays. Deliberately not a fourth [ScreenSize]: the app's
/// own screens have nothing more to do with the extra width — a working window
/// is a working window — and adding a value would force every switch over the
/// enum to answer a question only the landing page is asking.
const double kWideBreakpoint = 1600;

/// Container-query thresholds: the width a component needs *in its own box*
/// before it can afford a wider arrangement. Deliberately separate from the
/// window breakpoints above — a card can be narrow on a wide screen.
abstract final class ContainerWidth {
  /// Settings pane splits into two columns.
  static const double settingsTwoColumn = 760;

  /// A settings column is wide enough to pair fields side by side.
  static const double fieldPair = 300;

  /// Assignment slots fit two per row.
  static const double slotPair = 340;

  /// The continue card can put the ring, body and CTA on one line.
  static const double continueRow = 560;
}

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

  /// Past the widest laptop. [ScreenSize.desktop] is everything from 1081px
  /// up with no ceiling, so a 1200px window and a 1700px display were being
  /// handed the same type and the same measure — which on the wider one reads
  /// as a small island with the screen showing through on both sides.
  bool get isWide => MediaQuery.sizeOf(this).width > kWideBreakpoint;
}
