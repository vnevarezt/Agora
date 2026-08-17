import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/motion.dart';
import 'brand_mark.dart';
import 'landing_glass.dart';
import 'landing_layout.dart';

typedef LandingNavItem = ({String label, VoidCallback onTap});

class LandingHeader extends StatefulWidget {
  const LandingHeader({
    super.key,
    required this.navItems,
    required this.onEnterApp,
    required this.onBrandTap,
    required this.scrollController,
  });

  final List<LandingNavItem> navItems;
  final VoidCallback onEnterApp;
  final VoidCallback onBrandTap;

  /// Watched only to know whether anything has scrolled under the bar.
  final ScrollController scrollController;

  static const double height = LandingSpace.s64;

  /// Far enough that a trackpad's idle jitter at the top of the page does not
  /// flicker the rule on and off.
  static const double _liftAt = 4;

  /// Caps the brand lockup so it can never push into the actions. A cap rather
  /// than a [Flexible] on purpose — see the note on the row below — and safe
  /// as one because the brand name is a proper noun that does not localise and
  /// the badge beside it only appears above [kLandingNavBreakpoint]. The
  /// widest this can actually render is well under half of the narrowest
  /// window the page supports.
  static const double _brandMaxWidth = 260;

  @override
  State<LandingHeader> createState() => _LandingHeaderState();
}

class _LandingHeaderState extends State<LandingHeader> {
  bool _lifted = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant LandingHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  /// Rebuilds on the crossing, not on the scroll. Rebuilding the bar from the
  /// scroll notification itself would rebuild the brand, four nav links and
  /// two buttons on every frame of every scroll, to change one border colour
  /// twice.
  void _onScroll() {
    final controller = widget.scrollController;
    final lifted =
        controller.hasClients && controller.offset > LandingHeader._liftAt;
    if (lifted != _lifted) setState(() => _lifted = lifted);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final showNav = landingShowsNav(context);

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: LandingSection.maxWidth(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: LandingSpace.gutter(context),
          ),
          child: Row(
            children: [
              // The brand and the nav share one flexible cell so that whatever
              // width they leave unused collects *here*, between the nav and
              // the actions, rather than past the last button.
              //
              // As two separate flex children of the outer row they split its
              // free space evenly, the brand took only what its lockup needs,
              // and the half it did not use stranded at the end of the row —
              // which is what left the actions floating 84px short of the
              // column edge every section below the bar lines up with.
              Expanded(
                child: Row(
                  children: [
                    // Capped rather than Flexible: a loose flex child would
                    // claim an even share of this row's free space and hand
                    // the nav less than its four links need, clipping them
                    // into the horizontal scroller for no reason.
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: LandingHeader._brandMaxWidth,
                      ),
                      child: _Brand(
                        onTap: widget.onBrandTap,
                        showBadge: showNav,
                      ),
                    ),
                    if (showNav) ...[
                      const SizedBox(width: LandingSpace.s32),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final item in widget.navItems)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: LandingSpace.s24,
                                  ),
                                  child: _NavLink(
                                    label: item.label,
                                    onTap: item.onTap,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showNav) ...[
                _NavLink(label: tr.landing.signIn, onTap: widget.onEnterApp),
                const SizedBox(width: LandingSpace.s16),
              ],
              AppButton(
                onPressed: widget.onEnterApp,
                height: Dimens.hTouchMin,
                label: tr.landing.openApp,
              ),
            ],
          ),
        ),
      ),
    );

    // The glass is always on: at the top of the page it sits over the page's
    // own background and is invisible by construction, so there is no moment
    // where the material changes under the reader. Only the rule arrives —
    // it exists once there is something behind the bar for it to separate,
    // and over the unbroken hero a line reads as a seam.
    return LiquidGlass(
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.med),
        curve: Motion.curve,
        height: LandingHeader.height,
        decoration: BoxDecoration(
          border: Border(
            // Transparent rather than absent: the bar keeps the same height
            // either way, so nothing below it moves when the rule arrives.
            bottom: BorderSide(
              color: _lifted ? t.border : Colors.transparent,
            ),
          ),
        ),
        child: content,
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.onTap, required this.showBadge});

  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => AnimatedOpacity(
        // The brand scrolls the page back to the top, so it has to answer the
        // pointer like the links beside it rather than look like a logo.
        duration: Motion.of(context, Motion.instant),
        curve: Motion.curve,
        opacity: hovered ? 0.7 : 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(),
            const SizedBox(width: LandingSpace.s8),
            Flexible(
              child: Text(
                tr.app.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppText.title,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: t.text,
                ),
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: LandingSpace.s8),
              LandingBadge(
                // Uppercased at the call site the way the "coming soon" badge
                // is: the page has one badge, in three places.
                text: tr.landing.betaBadge.toUpperCase(),
                background: t.warningSoft,
                ink: t.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => SizedBox(
        height: Dimens.hTouchMin,
        child: Center(
          // Snapping between two greys on hover is the tell that a control was
          // styled but never animated; at this size the fade is most of what
          // makes it feel like a link rather than a label.
          child: AnimatedInk(
            color: hovered ? t.text : t.textDim,
            builder: (context, color) => Text(
              label,
              style: TextStyle(
                fontSize: AppText.body,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
