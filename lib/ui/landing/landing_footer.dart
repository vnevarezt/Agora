import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/motion.dart';
import 'brand_mark.dart';
import 'landing_layout.dart';
import 'landing_motion.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final f = tr.landing.footer;

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 22),
            const SizedBox(width: LandingSpace.s8),
            Text(
              tr.app.brand,
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: t.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: LandingSpace.s16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            f.legal,
            style: TextStyle(
              fontSize: AppText.body,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: t.textDim,
            ),
          ),
        ),
        const SizedBox(height: LandingSpace.s12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            f.license,
            style: TextStyle(
              fontSize: AppText.small,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: t.textMute,
            ),
          ),
        ),
      ],
    );

    final repoLink = Align(
      alignment: Alignment.topLeft,
      child: _FooterLink(
        label: f.linkRepo,
        onTap: () => launchUrl(Uri.parse('https://github.com/vnevarezt/Agora')),
      ),
    );

    return LandingSection(
      top: 72,
      bottom: LandingSpace.s56,
      child: Reveal(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: LandingSpace.s32),
            child: context.isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      identity,
                      const SizedBox(height: LandingSpace.s20),
                      repoLink,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: identity),
                      const SizedBox(width: LandingSpace.s40),
                      Expanded(child: repoLink),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => SizedBox(
        height: Dimens.hTouchMin,
        child: AnimatedInk(
          color: hovered ? t.accentStrong : t.accent,
          builder: (context, color) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: LandingSpace.s4),
              // Same nudge the closing CTA's arrow makes: an outbound link and
              // an outbound button should answer the pointer the same way.
              AnimatedSlide(
                duration: Motion.of(context, Motion.instant),
                curve: Motion.curve,
                offset: hovered ? const Offset(0.18, -0.18) : Offset.zero,
                child: Icon(Icons.north_east, size: 15, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
