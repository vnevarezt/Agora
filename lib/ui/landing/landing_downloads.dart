import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/motion.dart';
import 'landing_layout.dart';
import 'landing_motion.dart';

class LandingDownloads extends StatelessWidget {
  const LandingDownloads({super.key, required this.onEnterApp});

  final VoidCallback onEnterApp;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final d = tr.landing.downloads;
    final compact = context.isMobile;

    return LandingSection(
      child: Reveal(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? LandingSpace.s24 : LandingSpace.s48,
            vertical: compact ? LandingSpace.s40 : LandingSpace.s56,
          ),
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(Dimens.rCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LandingHeading(text: d.title, maxWidth: 640, color: t.accentInk),
              const SizedBox(height: LandingSpace.s16),
              LandingLead(
                text: d.body,
                color: t.accentInk.withValues(alpha: 0.86),
              ),
              const SizedBox(height: LandingSpace.s32),
              Align(
                alignment: Alignment.centerLeft,
                child: _InvertedCta(label: d.cta, onTap: onEnterApp),
              ),
              const SizedBox(height: LandingSpace.s32),
              Wrap(
                spacing: LandingSpace.s12,
                runSpacing: LandingSpace.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  LandingBadge(
                    text: d.comingSoonBadge.toUpperCase(),
                    background: t.accentInk.withValues(alpha: 0.18),
                    ink: t.accentInk,
                  ),
                  Text(
                    d.comingSoonBody,
                    style: TextStyle(
                      fontSize: AppText.body,
                      fontWeight: FontWeight.w600,
                      color: t.accentInk.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvertedCta extends StatelessWidget {
  const _InvertedCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, pressed) => AnimatedContainer(
        duration: Motion.of(context, Motion.instant),
        height: Dimens.hTouchMin,
        padding: const EdgeInsets.symmetric(horizontal: LandingSpace.s24),
        transform: pressed
            ? (Matrix4.identity()..translateByDouble(0, 1, 0, 1))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: hovered ? t.accentSoft : t.accentInk,
          borderRadius: BorderRadius.circular(Dimens.rControl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppText.bodyLarge,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                  color: t.accentStrong,
                ),
              ),
            ),
            const SizedBox(width: LandingSpace.s8),
            AnimatedSlide(
              duration: Motion.of(context, Motion.instant),
              curve: Motion.curve,
              offset: hovered ? const Offset(0.2, 0) : Offset.zero,
              child: Icon(Icons.arrow_forward, size: 18, color: t.accentStrong),
            ),
          ],
        ),
      ),
    );
  }
}
