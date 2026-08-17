import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The landing's translucent chrome.
///
/// Real glass, not a tinted panel: the page travels *underneath* it and is
/// blurred and re-saturated in place, so the colour of whatever is passing
/// behind still reads through. That distinction is the whole effect, and it is
/// structural rather than cosmetic — with nothing behind it a [BackdropFilter]
/// is an expensive way to draw a rectangle. It is why the header overlays the
/// scroll view instead of sitting above it in a column.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  /// Wide enough that the backdrop averages into a wash rather than a
  /// recognisable smear of the content behind it. That is what keeps text on
  /// the glass legible over anything the page happens to scroll under it, and
  /// it is the number to raise if a section ever reads through too strongly.
  ///
  /// It also has a ceiling, which is why this is 12 and not the 28 it wants to
  /// be. A [BackdropFilter] re-rasterises everything behind it on every frame
  /// and cannot be cached — `BackdropFilterLayer` has no RasterCache, open
  /// since flutter#71246 — so its cost is paid 60 times a second while the
  /// page scrolls, and that cost scales with this number. Past roughly 10 it
  /// is the single most expensive thing on the page. In CSS this would be one
  /// hardware-composited declaration and the ceiling would not exist; here the
  /// effect is drawn by hand into a canvas.
  static const double _blur = 12;

  /// Blur desaturates as it averages, which is what makes a naive frosted
  /// panel look like grey plastic. Pushing saturation back past 1 is the step
  /// that keeps an accent-coloured tile still reading as coloured while it
  /// passes beneath the bar.
  static const double _saturation = 1.7;

  /// Tint opacity: high enough to hold body text at AA over any backdrop this
  /// page can put behind it, low enough that the movement is still visible.
  static const double _tint = 0.72;

  /// Rec. 709 luminance weights — the same ones CSS `saturate()` uses, so the
  /// bar matches the effect this was asked to look like rather than an
  /// approximation of it.
  static List<double> _saturate(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    return <double>[
      r * (1 - s) + s, g * (1 - s), b * (1 - s), 0, 0, //
      r * (1 - s), g * (1 - s) + s, b * (1 - s), 0, 0, //
      r * (1 - s), g * (1 - s), b * (1 - s) + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    // Translucency trades contrast for depth by construction, and this product
    // is read by people who have already told the OS they want more contrast.
    // They get the flat opaque bar, and the BackdropFilter is not built at all
    // rather than being built with a zero blur.
    final opaque = MediaQuery.highContrastOf(context);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: opaque ? t.bg : t.bg.withValues(alpha: _tint),
        borderRadius: borderRadius,
        border: border,
      ),
      child: child,
    );

    if (!opaque) {
      surface = BackdropFilter(
        filter: ui.ImageFilter.compose(
          outer: ui.ColorFilter.matrix(_saturate(_saturation)),
          inner: ui.ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        ),
        child: surface,
      );
    }

    return DecoratedBox(
      // Outside the clip: a shadow drawn inside the ClipRRect is clipped away
      // by the very rectangle it is meant to sit under.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: surface),
    );
  }
}
