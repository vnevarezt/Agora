import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'landing_layout.dart';
import 'landing_motion.dart';

({Color treasures, Color ministry, Color christianLife}) _contrastSafeBands(
  BuildContext context,
) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark
      ? (
          treasures: const Color(0xFF9BA3AC),
          ministry: const Color(0xFFD9AE3D),
          christianLife: const Color(0xFFE08196),
        )
      : (
          treasures: const Color(0xFF5C5C5C),
          ministry: const Color(0xFF8A6408),
          christianLife: const Color(0xFF8C1B2E),
        );
}

class LandingSchedules extends StatelessWidget {
  const LandingSchedules({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    return LandingSection(
      child: BentoRow(
        align: CrossAxisAlignment.center,
        cells: [
          BentoCell(
            flex: BentoSplit.copy,
            child: const Reveal(
              child: LandingHeadingColumn(child: _TimingCopy()),
            ),
          ),
          BentoCell(
            flex: BentoSplit.panel,
            child: Reveal(
              delay: const Duration(milliseconds: 70),
              child: BentoTile(
                color: context.tokens.surface2,
                // Short at the bottom by exactly one row's padding, so the
                // last row's baseline sits the same distance from the border
                // as the label at the top does.
                padding: const EdgeInsets.fromLTRB(
                  LandingSpace.tilePad,
                  LandingSpace.tilePad,
                  LandingSpace.tilePad,
                  LandingSpace.s16,
                ),
                child: _SampleWeek(label: tr.landing.schedules.sampleLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingCopy extends StatelessWidget {
  const _TimingCopy();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LandingHeading(text: tr.landing.schedules.title),
        const SizedBox(height: LandingSpace.s20),
        LandingLead(text: tr.landing.schedules.body, maxWidth: 420),
        const SizedBox(height: LandingSpace.s24),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.accentSoft,
            borderRadius: BorderRadius.circular(Dimens.rControl),
          ),
          // A floor, not a fixed height: this line is the longest string in
          // the section and the narrowest column on the page, and it has to
          // stay able to wrap to a second line rather than overflow. Sizing
          // is left to the padding, which shrink-wraps in every context.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Dimens.hControl),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LandingSpace.s16,
                vertical: LandingSpace.s8,
              ),
              child: Text(
                tr.landing.schedules.slack,
                style: AppText.mono(
                  size: AppText.body,
                  color: t.accentStrong,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: LandingSpace.s20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            tr.landing.schedules.circuit,
            style: TextStyle(
              fontSize: AppText.body,
              fontWeight: FontWeight.w500,
              height: 1.55,
              color: t.textDim,
            ),
          ),
        ),
      ],
    );
  }
}

class _SampleWeek extends StatelessWidget {
  const _SampleWeek({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final bands = _contrastSafeBands(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 2,
                style: AppText.label(color: t.textMute),
              ),
            ),
            const SizedBox(width: LandingSpace.s8),
            Text(
              tr.landing.schedules.sampleTargetEnd,
              style: AppText.mono(color: t.textDim),
            ),
          ],
        ),
        // The first row carries its own half-gap, so this is short by that
        // much to land on the same rhythm as the gaps between rows.
        const SizedBox(height: LandingSpace.s16),
        _Row(time: '18:00', label: tr.landing.schedules.sampleOpeningSong),
        _Row(time: '18:08', label: tr.landing.schedules.sampleIntro),
        _Row(
          time: '18:09',
          label: tr.landing.schedules.sampleTreasures,
          color: bands.treasures,
          duration: tr.landing.schedules.sampleTreasuresDuration,
        ),
        _Row(
          time: '18:34',
          label: tr.landing.schedules.sampleMinistry,
          color: bands.ministry,
          duration: tr.landing.schedules.sampleMinistryDuration,
          fixed: true,
        ),
        _Row(time: '18:49', label: tr.landing.schedules.sampleSong2),
        _Row(
          time: '18:57',
          label: tr.landing.schedules.sampleChristianLife,
          color: bands.christianLife,
          duration: tr.landing.schedules.sampleChristianLifeDuration,
        ),
        _Row(time: '19:02', label: tr.landing.schedules.sampleBibleStudy),
        _Row(time: '19:32', label: tr.landing.schedules.sampleClosingWords),
        _Row(time: '19:35', label: tr.landing.schedules.sampleClosingSong),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.time,
    required this.label,
    this.color,
    this.duration,
    this.fixed = false,
  });

  final String time;
  final String label;
  final Color? color;
  final String? duration;
  final bool fixed;

  /// The section marks are twice the height of the plain ones: on the printed
  /// sheet a section is a band across the page and a song is a line.
  static const double _markMajor = LandingSpace.s24;
  static const double _markMinor = LandingSpace.s12;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final major = color != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LandingSpace.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(time, style: AppText.mono(color: t.textDim)),
          const SizedBox(width: LandingSpace.s12),
          Container(
            width: 3,
            height: major ? _markMajor : _markMinor,
            decoration: BoxDecoration(
              color: color ?? t.border,
              borderRadius: BorderRadius.circular(Dimens.rPill),
            ),
          ),
          const SizedBox(width: LandingSpace.s12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppText.body,
                fontWeight: major ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
                color: major ? t.text : t.textDim,
              ),
            ),
          ),
          if (duration != null) ...[
            const SizedBox(width: LandingSpace.s8),
            LandingBadge(
              text: duration!,
              style: AppText.mono(size: AppText.caption),
              background: fixed ? t.warningSoft : t.surface,
              ink: fixed ? t.warning : t.textDim,
              border: fixed ? null : Border.all(color: t.border),
            ),
          ],
        ],
      ),
    );
  }
}
