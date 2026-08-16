import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'landing_layout.dart';
import 'landing_motion.dart';

/// Between peers in a row. Short enough to read as one arrival with a lean to
/// it rather than three separate ones.
const Duration _peerStep = Duration(milliseconds: 70);

class LandingPreview extends StatelessWidget {
  const LandingPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final p = tr.landing.preview;
    final f = tr.landing.features;

    final points = [
      (p.point1Title, p.point1Body),
      (p.point2Title, p.point2Body),
      (p.point3Title, p.point3Body),
    ];

    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(child: LandingHeading(text: p.title, maxWidth: 720)),
          const SizedBox(height: LandingSpace.s32),
          BentoRow(
            cells: [
              for (var i = 0; i < points.length; i++)
                BentoCell(
                  child: Reveal(
                    delay: _peerStep * i,
                    child: _Point(title: points[i].$1, body: points[i].$2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LandingSpace.gap),
          Reveal(
            child: BentoTile(
              color: t.surface2,
              // The strip's own cells carry the rest of the tile padding, so
              // that a divider between them can run the full height.
              padding: const EdgeInsets.symmetric(
                horizontal: LandingSpace.s8,
                vertical: LandingSpace.s4,
              ),
              child: _FeatureStrip(
                items: [
                  (f.auxRoomTitle, f.auxRoomBody),
                  (f.circuitTitle, f.circuitBody),
                  (f.editTitle, f.editBody),
                  (f.gapsTitle, f.gapsBody),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.title, required this.body});

  final String title;
  final String body;

  /// A shared floor for the three, so they read as one row rather than three
  /// heights. Tall enough for a two-line title at the narrowest column.
  static const double _floor = 176;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return BentoTile(
      // Only while they stand side by side. Stacked, there is no ragged row
      // left to level and the floor just pads three short cards out to a
      // height none of them needs.
      minHeight: context.isMobile ? null : _floor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: LandingSpace.s8,
            height: LandingSpace.s8,
            margin: const EdgeInsets.only(bottom: LandingSpace.s16),
            decoration: BoxDecoration(
              color: t.successStrong,
              shape: BoxShape.circle,
            ),
          ),
          TileTitle(title),
          const SizedBox(height: LandingSpace.s4),
          TileBody(body),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    // Same rule read two ways: stacked, the cells are separated above; in a
    // row, beside. Without it the four run together on wide windows while
    // the mobile version is properly ruled.
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            _Feature(
              title: items[i].$1,
              body: items[i].$2,
              divider: i == 0
                  ? null
                  : Border(top: BorderSide(color: t.border)),
            ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: _Feature(
              title: items[i].$1,
              body: items[i].$2,
              divider: i == 0
                  ? null
                  : Border(left: BorderSide(color: t.border)),
            ),
          ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.title, required this.body, this.divider});

  final String title;
  final String body;
  final BoxBorder? divider;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(border: divider),
      child: Padding(
        // Horizontal padding plus the strip tile's own comes to a full
        // [LandingSpace.tilePad] at the outer edge, so the strip lines up with
        // the bento tiles above it.
        padding: const EdgeInsets.symmetric(
          horizontal: LandingSpace.s16,
          vertical: LandingSpace.s20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.3,
                color: t.text,
              ),
            ),
            const SizedBox(height: LandingSpace.s4),
            Text(
              body,
              style: TextStyle(
                fontSize: AppText.body,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: t.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
