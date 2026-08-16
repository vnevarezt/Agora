import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../i18n/strings.g.dart';
import '../theme/tokens.dart';
import '../widgets/motion.dart';
import 'landing_back_to_top.dart';
import 'landing_downloads.dart';
import 'landing_footer.dart';
import 'landing_header.dart';
import 'landing_hero.dart';
import 'landing_how_it_works.dart';
import 'landing_layout.dart';
import 'landing_motion.dart';
import 'landing_preview.dart';
import 'landing_privacy.dart';
import 'landing_schedules.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key, required this.onEnterApp});

  final VoidCallback onEnterApp;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();
  final _howItWorksKey = GlobalKey();
  final _schedulesKey = GlobalKey();
  final _privacyKey = GlobalKey();
  final _downloadsKey = GlobalKey();

  /// Lands the section's top edge just below the bar.
  ///
  /// Not [Scrollable.ensureVisible]: its alignment is a fraction of the
  /// viewport, and the viewport now starts *behind* the header — so any
  /// fraction small enough to look like "at the top" parks the section's first
  /// line under the glass, and the fraction that clears it on a laptop leaves
  /// a third of a phone screen empty.
  void _scrollTo(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final position = _scrollController.position;
    if (box == null || !box.hasSize) return;

    final target =
        RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset -
        LandingHeader.height -
        LandingSpace.s24;

    _scrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: Motion.of(context, Motion.med),
      curve: Motion.curve,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Motion.of(context, Motion.med),
      curve: Motion.curve,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;

    final gutter = LandingSpace.gutter(context);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        // Everything below the fold arrives on scroll, and the reveals are
        // several sections deep inside const subtrees — the scope hands them
        // the controller without making each section stateful just to pass it
        // along. It wraps the whole stack so the floating chrome shares it.
        child: LandingScrollScope(
          controller: _scrollController,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                // The bar is glass, so the page has to have somewhere to go
                // underneath it. The padding is what keeps the hero from
                // starting there rather than arriving there.
                padding: const EdgeInsets.only(top: LandingHeader.height),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LandingHero(onEnterApp: widget.onEnterApp),
                    KeyedSubtree(
                      key: _howItWorksKey,
                      child: const LandingHowItWorks(),
                    ),
                    KeyedSubtree(
                      key: _schedulesKey,
                      child: const LandingSchedules(),
                    ),
                    const LandingPreview(),
                    KeyedSubtree(
                      key: _privacyKey,
                      child: const LandingPrivacy(),
                    ),
                    KeyedSubtree(
                      key: _downloadsKey,
                      child: LandingDownloads(onEnterApp: widget.onEnterApp),
                    ),
                    const LandingFooter(),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LandingHeader(
                  onBrandTap: _scrollToTop,
                  onEnterApp: widget.onEnterApp,
                  scrollController: _scrollController,
                  navItems: [
                    (
                      label: tr.landing.nav.howItWorks,
                      onTap: () => _scrollTo(_howItWorksKey),
                    ),
                    (
                      label: tr.landing.nav.schedules,
                      onTap: () => _scrollTo(_schedulesKey),
                    ),
                    (
                      label: tr.landing.nav.privacy,
                      onTap: () => _scrollTo(_privacyKey),
                    ),
                    (
                      label: tr.landing.nav.downloads,
                      onTap: () => _scrollTo(_downloadsKey),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: gutter,
                bottom: gutter,
                child: LandingBackToTop(
                  scrollController: _scrollController,
                  onTap: _scrollToTop,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
