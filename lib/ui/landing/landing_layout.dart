import 'package:flutter/material.dart';

import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';

abstract final class LandingText {
  /// The scale carries a fourth step the app's own screens do not, because
  /// [ScreenSize.desktop] has no ceiling: everything from 1081px up got the
  /// same 66px hero inside the same measure, and past roughly a laptop's width
  /// that stops reading as a page and starts reading as an island. The wide
  /// column in [LandingSection.maxWidth] grows with these, so the number of
  /// characters on a line stays where it was.
  static double _scale(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    required double wide,
  }) => context.isWide
      ? wide
      : switch (context.screenSize) {
          ScreenSize.mobile => mobile,
          ScreenSize.tablet => tablet,
          ScreenSize.desktop => desktop,
        };

  static double hero(BuildContext context) =>
      _scale(context, mobile: 40, tablet: 54, desktop: 66, wide: 78);

  static double section(BuildContext context) =>
      _scale(context, mobile: 28, tablet: 36, desktop: 42, wide: 50);

  static double lead(BuildContext context) =>
      _scale(context, mobile: 17, tablet: 19, desktop: 19, wide: 21);

  static double tile(BuildContext context) =>
      _scale(context, mobile: 19, tablet: 21, desktop: 21, wide: 23);

  /// Supporting text under a tile title. One step above the app's dense
  /// default on purpose: the app's [AppText.body] is tuned for a working
  /// screen full of rows, and this page is read once, at leisure, often by
  /// people for whom legibility is not a preference.
  static double tileBody(BuildContext context) => _scale(
    context,
    mobile: AppText.bodyLarge,
    tablet: AppText.bodyLarge,
    desktop: AppText.bodyLarge,
    wide: AppText.title,
  );

  /// Display tracking as a ratio of the size, not a fixed number of pixels.
  /// A single value cannot serve both ends of a scale that runs 28→66: the
  /// -2 that reads as confident at 66 is -0.05em at 40, past the point where
  /// letters start touching.
  static double tracking(double size) => size * -0.028;
}

abstract final class LandingSpace {
  // ---- spacing scale ------------------------------------------------------
  // Every padding, gap and inset on the landing comes from here. A bare
  // number at a call site is drift — the same drift that had this page
  // running 4, 5, 6, 7, 13, 18, 22, 26, 36 and 44 with no rule for choosing
  // among them, which is why equivalent elements in different sections did
  // not line up.

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;

  // ---- structural roles ---------------------------------------------------

  /// Between bento cells.
  static const double gap = s12;

  /// Inside a bento tile, on every edge.
  static const double tilePad = s24;

  /// Added to [gap] on a bare heading column standing beside a tile. The tile
  /// holds its content [tilePad] back from its own border; the heading has no
  /// border to hold back from, so matching the optical gap takes real padding.
  static const double headingInset = s20;

  /// Above a section's first element. Sections carry no bottom padding, so
  /// this alone is the gap between any two of them.
  /// Air between sections. Grows with the type it separates: held at 120 while
  /// the headings went to 50, the sections would start to crowd each other.
  static double section(BuildContext context) => context.isWide
      ? 144
      : switch (context.screenSize) {
          ScreenSize.mobile => 72,
          ScreenSize.tablet => 96,
          ScreenSize.desktop => 120,
        };

  static double gutter(BuildContext context) => switch (context.screenSize) {
    ScreenSize.mobile => s20,
    ScreenSize.tablet => 28,
    ScreenSize.desktop => s32,
  };
}

/// The two column ratios this page uses. Named so that a section picks one of
/// them deliberately, rather than inventing a ratio per section — which is
/// how the left column ended up at 40% under one heading and 45% under the
/// next, close enough to look like a mistake rather than a decision.
abstract final class BentoSplit {
  /// Left column carrying a heading and nothing else.
  static const int heading = 4;

  /// Left column carrying a heading plus supporting copy, so it earns width.
  static const int copy = 5;

  /// The panel on the right of either.
  static const int panel = 6;
}

class LandingSection extends StatelessWidget {
  const LandingSection({
    super.key,
    required this.child,
    this.top,
    this.bottom = 0,
  });

  final Widget child;
  final double? top;
  final double bottom;

  /// The page's measure. It grows on a wide display in step with
  /// [LandingText], so the extra width buys bigger type rather than longer
  /// lines — a 1160px column of 19px copy on a 1700px screen is not too narrow
  /// to read, it is too small for how far away the reader is sitting.
  static double maxWidth(BuildContext context) => context.isWide ? 1320 : 1160;

  @override
  Widget build(BuildContext context) {
    final gutter = LandingSpace.gutter(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth(context)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            top ?? LandingSpace.section(context),
            gutter,
            bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}

class LandingHeading extends StatelessWidget {
  const LandingHeading({
    super.key,
    required this.text,
    this.maxWidth,
    this.color,
  });

  final String text;
  final double? maxWidth;

  /// Only for a heading on a filled surface, which needs that surface's ink
  /// rather than the page's. Everything else takes the default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = LandingText.section(context);
    final heading = Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: LandingText.tracking(size),
        height: 1.08,
        color: color ?? t.text,
      ),
    );
    if (maxWidth == null) return heading;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: heading,
    );
  }
}

/// A heading column standing beside a panel: carries [LandingSpace.headingInset]
/// so the two read as evenly spaced despite only one of them having a border.
class LandingHeadingColumn extends StatelessWidget {
  const LandingHeadingColumn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        // Stacked on mobile, the inset would push the heading off-axis from
        // the tile below it; the row gap already separates them there.
        right: context.isMobile ? 0 : LandingSpace.headingInset,
        bottom: context.isMobile ? LandingSpace.s4 : 0,
      ),
      child: child,
    );
  }
}

class LandingLead extends StatelessWidget {
  const LandingLead({
    super.key,
    required this.text,
    this.maxWidth = 520,
    this.color,
  });

  final String text;
  final double maxWidth;

  /// See [LandingHeading.color].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        text,
        style: TextStyle(
          fontSize: LandingText.lead(context),
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: -0.2,
          color: color ?? t.textDim,
        ),
      ),
    );
  }
}

class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.bordered = true,
    this.alignment,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool bordered;
  final AlignmentGeometry? alignment;

  /// Levels a row of otherwise-ragged tiles without `IntrinsicHeight`: a tile
  /// whose content runs longer still grows, it just starts from a shared floor.
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      alignment: alignment,
      constraints: minHeight == null
          ? null
          : BoxConstraints(minHeight: minHeight!),
      padding: padding ?? const EdgeInsets.all(LandingSpace.tilePad),
      decoration: BoxDecoration(
        color: color ?? t.surface,
        borderRadius: BorderRadius.circular(Dimens.rCard),
        border: bordered ? Border.all(color: t.border) : null,
      ),
      child: child,
    );
  }
}

/// The page's one pill: a short label or figure on a tinted ground.
///
/// Sized by its content in every context, which is less obvious than it
/// sounds — a [Container] carrying an `alignment` expands to fill whatever
/// bounded width its parent offers, so the same chip shrink-wrapped inside a
/// row and stretched across the column when it was stacked. Height is fixed
/// here instead, and the width comes from a shrink-wrapping row.
class LandingBadge extends StatelessWidget {
  const LandingBadge({
    super.key,
    required this.text,
    required this.background,
    required this.ink,
    this.style,
    this.border,
  });

  final String text;
  final Color background;
  final Color ink;

  /// Defaults to the uppercase label. Pass [AppText.mono] for a figure.
  final TextStyle? style;

  final BoxBorder? border;

  static const double height = LandingSpace.s20;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Dimens.rChip),
        border: border,
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LandingSpace.s8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flexible with a min-size row is the pair that both shrink-wraps
              // a short label and lets a long translation ellipsise instead of
              // overflowing its parent.
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (style ?? AppText.label()).copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BentoCell {
  const BentoCell({required this.child, this.flex = 1});

  final Widget child;
  final int flex;
}

/// Lays cells out side by side with hierarchy carried by [BentoCell.flex],
/// collapsing to a single column on compact widths.
///
/// Deliberately no `IntrinsicHeight`: it measures children at their unbounded
/// intrinsic width, so any cell whose text rewraps at its real flex width ends
/// up short and overflows. Cells take their natural height instead.
class BentoRow extends StatelessWidget {
  const BentoRow({
    super.key,
    required this.cells,
    this.gap = LandingSpace.gap,
    this.align = CrossAxisAlignment.start,
  });

  final List<BentoCell> cells;
  final double gap;

  /// `center` is safe here where `stretch` is not: it needs the row's own
  /// height, which the tallest cell already provides, rather than an intrinsic
  /// pass over children that rewrap.
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            cells[i].child,
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: align,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(flex: cells[i].flex, child: cells[i].child),
        ],
      ],
    );
  }
}

const double kLandingNavBreakpoint = 940;

bool landingShowsNav(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kLandingNavBreakpoint;

class TileTitle extends StatelessWidget {
  const TileTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      style: TextStyle(
        fontSize: LandingText.tile(context),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
        color: t.text,
      ),
    );
  }
}

class TileBody extends StatelessWidget {
  const TileBody(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      style: TextStyle(
        fontSize: LandingText.tileBody(context),
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: t.textDim,
      ),
    );
  }
}
