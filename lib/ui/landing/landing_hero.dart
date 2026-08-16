import 'dart:async';

import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/motion.dart';
import 'landing_layout.dart';
import 'program_sheet.dart';

/// When the sheet starts, measured from mount. Late enough that the headline
/// is already legible, early enough that it is still filling in as the eye
/// arrives from the last line of copy.
const Duration _sheetDelay = Duration(milliseconds: 200);

/// Staggers the copy above it. Kept under a third of a second end to end —
/// past that the reader is waiting on the page rather than reading it.
const Duration _copyStep = Duration(milliseconds: 70);

class LandingHero extends StatelessWidget {
  const LandingHero({super.key, required this.onEnterApp});

  final VoidCallback onEnterApp;

  @override
  Widget build(BuildContext context) {
    final copy = _HeroCopy(onEnterApp: onEnterApp);
    const sheet = _HeroSheet();

    return LandingSection(
      top: context.isMobile ? LandingSpace.s40 : LandingSpace.s64,
      bottom: LandingSpace.s8,
      child: context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: LandingSpace.s40),
                sheet,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 7, child: copy),
                const SizedBox(width: LandingSpace.s56),
                const Expanded(flex: 5, child: sheet),
              ],
            ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onEnterApp});

  final VoidCallback onEnterApp;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final size = LandingText.hero(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnterUp(
          child: Text(
            tr.landing.hero.title,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: LandingText.tracking(size),
              height: 1.0,
              color: t.text,
            ),
          ),
        ),
        const SizedBox(height: LandingSpace.s24),
        EnterUp(
          delay: _copyStep,
          child: LandingLead(text: tr.landing.hero.subtitle, maxWidth: 440),
        ),
        const SizedBox(height: LandingSpace.s32),
        EnterUp(
          delay: _copyStep * 2,
          child: Row(
            children: [
              AppButton(
                onPressed: onEnterApp,
                height: Dimens.hTouchMin,
                label: tr.landing.hero.cta,
                icon: Icons.arrow_forward,
              ),
            ],
          ),
        ),
        const SizedBox(height: LandingSpace.s16),
        EnterUp(
          delay: _copyStep * 3,
          child: Text(
            tr.landing.hero.note,
            style: TextStyle(
              fontSize: AppText.body,
              fontWeight: FontWeight.w600,
              color: t.textMute,
            ),
          ),
        ),
      ],
    );
  }
}

/// The page's one authored entrance: the sheet lifts into place and then
/// writes itself, line by line, names landing last.
///
/// It is the argument the headline makes ("you put in the names, that's it")
/// performed rather than stated, which is why nothing else on this page gets
/// motion at this length — a second one would make this one ordinary.
class _HeroSheet extends StatefulWidget {
  const _HeroSheet();

  @override
  State<_HeroSheet> createState() => _HeroSheetState();
}

class _HeroSheetState extends State<_HeroSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.focal,
  );

  /// The sheet arriving: over by the time the program is well underway, so
  /// the two phases read as one gesture rather than a queue.
  late final CurvedAnimation _lift = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, .35, curve: Motion.arrive),
  );

  /// Handed to [ProgramSheet], which slices it further per line. Linear on
  /// purpose: the easing belongs to each line, not to the window they share.
  late final CurvedAnimation _assemble = CurvedAnimation(
    parent: _controller,
    curve: const Interval(.15, 1),
  );

  Timer? _pending;

  @override
  void initState() {
    super.initState();
    _pending = Timer(_sheetDelay, _controller.forward);
  }

  @override
  void dispose() {
    _pending?.cancel();
    _lift.dispose();
    _assemble.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion gets the finished sheet. The entrance carries the
    // argument, but the headline states it too — nothing is lost by having
    // the page simply be there.
    final still = MediaQuery.disableAnimationsOf(context);

    final sheet = DecoratedBox(
      decoration: BoxDecoration(
        // Same corner as the paper it sits behind: a shadow rounded more than
        // its subject leaks past the sheet's edges.
        borderRadius: BorderRadius.circular(ProgramSheet.radius),
        boxShadow: Elevation.page,
      ),
      // Decorative: a picture of the printed program, which the headline and
      // subtitle beside it already say in words. A screen reader announcing
      // thirteen invented assignments would be noise, not information.
      child: ExcludeSemantics(
        child: ProgramSheet(assemble: still ? null : _assemble),
      ),
    );

    if (still) return sheet;

    return FadeTransition(
      opacity: _lift,
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: _lift,
        builder: (context, child) {
          final away = 1 - _lift.value;
          return Transform.translate(
            offset: Offset(0, LandingSpace.s24 * away),
            child: Transform.scale(scale: 1 - .04 * away, child: child),
          );
        },
        child: sheet,
      ),
    );
  }
}
