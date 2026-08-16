import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'landing_layout.dart';
import 'landing_motion.dart';

class LandingHowItWorks extends StatelessWidget {
  const LandingHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    // The numbers stay: this is the one place on the page where the order is
    // the content — you pick weeks before you can assign them, and assign
    // before there is anything to export.
    final steps = [
      ('01', tr.landing.howItWorks.step1Title, tr.landing.howItWorks.step1Body),
      ('02', tr.landing.howItWorks.step2Title, tr.landing.howItWorks.step2Body),
      ('03', tr.landing.howItWorks.step3Title, tr.landing.howItWorks.step3Body),
    ];

    return LandingSection(
      child: BentoRow(
        align: CrossAxisAlignment.center,
        cells: [
          BentoCell(
            flex: BentoSplit.heading,
            child: Reveal(
              child: LandingHeadingColumn(
                child: LandingHeading(text: tr.landing.howItWorks.title),
              ),
            ),
          ),
          BentoCell(
            flex: BentoSplit.panel,
            child: Reveal(
              delay: const Duration(milliseconds: 70),
              child: BentoTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: LandingSpace.tilePad,
                  vertical: LandingSpace.s8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      _Step(
                        number: steps[i].$1,
                        title: steps[i].$2,
                        body: steps[i].$3,
                        divided: i > 0,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    required this.divided,
  });

  final String number;
  final String title;
  final String body;
  final bool divided;

  /// Holds the three bodies on one left edge regardless of how wide the
  /// numeral renders.
  static const double _numberWidth = LandingSpace.s40;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divided ? Border(top: BorderSide(color: t.border2)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LandingSpace.s20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _numberWidth,
              child: Padding(
                // Optical: the caption-sized numeral sits on a much shorter
                // line box than the title beside it.
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  number,
                  style: AppText.mono(size: AppText.caption, color: t.accent),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TileTitle(title),
                  const SizedBox(height: LandingSpace.s4),
                  TileBody(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
