import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Shared motion language: one ease-out curve (the mock's cubic-bezier) and
/// one duration scale, so every surface moves the same way.
///
/// This is the only duration scale. Timings used to be split between here and
/// `Dimens`, where `dSlide` (180ms) duplicated [fast] under another name and
/// `dSheet` was never used at all.
///
/// Two rules, both checked by `test/ui/motion_guard_test.dart`:
///
/// * a duration always travels with [curve]. `AnimatedContainer` and every
///   other implicit animation default to `Curves.linear`, which starts and
///   stops at full speed — the one shape nothing physical moves in, and the
///   reason the hover and press states used to feel mechanical.
/// * a duration always goes through [of]. A raw duration handed to an
///   animated widget ignores Reduce Motion.
abstract final class Motion {
  /// Ease-out: leaves fast, settles slowly, no overshoot — the shape a
  /// critically damped spring draws, which is what iOS uses for anything the
  /// user did not throw. Overshoot (`easeOutBack` and friends) is reserved for
  /// motion that inherited momentum from a gesture; we have none, so this is
  /// the only curve in the app.
  static const Curve curve = Cubic(.2, .8, .3, 1);

  /// [curve] mirrored, for the return leg of a reversible transition: a
  /// surface should retrace the path it arrived on rather than ease out of
  /// the screen the same way it eased in.
  static final Curve curveOut = curve.flipped;

  /// The arrival curve, for content travelling a visible distance on its way
  /// in. [curve] decelerates gently, which is right for a control settling
  /// into a new state a few pixels away; over 14px or more it reads as drift.
  /// This one dumps almost all its speed in the first third, so the element
  /// looks like it was placed rather than floated into position.
  ///
  /// Use it for entrances and content swaps. State and press feedback stay on
  /// [curve] — the two are not interchangeable.
  static const Curve arrive = Cubic(.16, 1, .3, 1);

  /// Micro-interactions: hover and press feedback on a control. Short enough
  /// to read as a direct response to the finger rather than an animation.
  static const Duration instant = Duration(milliseconds: 150);

  /// A single element changing state or position.
  static const Duration fast = Duration(milliseconds: 180);

  /// A surface entering or leaving: sheets, page transitions.
  static const Duration med = Duration(milliseconds: 300);

  // There is deliberately no step above `med`. A 500ms entrance was the one
  // timing here that the user waited on rather than read, and waiting is not
  // a style.

  /// How far a control shrinks while held. The give under the finger is what
  /// makes a control feel like an object instead of a painted rectangle, and
  /// it is the one piece of feedback that reaches touch devices — they have no
  /// hover state at all.
  static const double pressScale = .97;

  /// The same idea on a card. Large surfaces need a much smaller factor: the
  /// scale is a ratio, so the edge of a 264px card travels ten times further
  /// than the edge of a chip at the same value, and .97 reads as a lurch.
  static const double pressScaleSurface = .99;

  /// Delay for the [step]-th item (0-based) of a staggered entrance. One
  /// constant step instead of delays picked by hand per screen, which drift
  /// out of rhythm as soon as someone inserts a row.
  ///
  /// Small on purpose, and capped. The stagger is meant to be felt as the
  /// screen settling into place, not watched item by item: at 30ms a capped
  /// run is over in under a third of a second, and no caller can turn a long
  /// list into a queue by handing this a large index.
  static Duration stagger(int step) =>
      Duration(milliseconds: 30 * step.clamp(0, 8));

  /// One authored entrance per surface, long enough to be watched rather than
  /// merely noticed. Deliberately the only duration above [slow]: if a second
  /// element on the same screen wants this, one of them is not focal.
  static const Duration focal = Duration(milliseconds: 720);

  /// [d] unless the user has asked the OS to reduce motion, in which case
  /// zero — the state change still happens, it just arrives immediately.
  /// Every animation in this file goes through here; a raw duration handed
  /// straight to an animated widget ignores the setting.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// [AnimatedSize] that honours Reduce Motion without asserting.
///
/// `AnimatedSize(duration: Motion.of(context, ...))` looks like the obvious
/// spelling and is a crash: `RenderAnimatedSize` restarts its controller from
/// inside `performLayout`, and a zero-length `forward()` notifies its listeners
/// synchronously rather than on the next tick — so the render object marks
/// itself dirty in the middle of its own layout and Flutter throws. Under
/// Reduce Motion there is no resize to ease, so the child is sized directly.
class MotionSize extends StatelessWidget {
  const MotionSize({
    super.key,
    this.duration = Motion.med,
    this.alignment = Alignment.center,
    required this.child,
  });

  final Duration duration;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: duration,
      curve: Motion.curve,
      alignment: alignment,
      child: child,
    );
  }
}

/// Material Design 3 "fade through": the outgoing surface fades out over the
/// first ~30% while the incoming one fades in and scales up from 92% over the
/// rest — the two never sit at full opacity at once, so it stays smooth on
/// low-end GPUs and Windows (unlike a plain cross-dissolve). Backed by the
/// official `animations` package. Give each child a distinct key.
class FadeThroughSwitcher extends StatelessWidget {
  const FadeThroughSwitcher({
    super.key,
    required this.child,
    this.duration = Motion.med,
    this.reverse = false,
  });

  final Widget child;
  final Duration duration;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: Motion.of(context, duration),
      reverse: reverse,
      transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
        animation: primary,
        secondaryAnimation: secondary,
        // Transparent: fade through to whatever is behind (the Scaffold bg)
        // instead of flashing an opaque theme color mid-transition.
        fillColor: Colors.transparent,
        child: RepaintBoundary(child: child),
      ),
      child: child,
    );
  }
}

/// iOS-style push/pop between steps of a flow: incoming slides from the
/// right, outgoing exits to the left (mirrored when [reverse]). Change the
/// [child] key to trigger it.
class SlideSwitcher extends StatelessWidget {
  const SlideSwitcher({
    super.key,
    required this.child,
    required this.reverse,
    this.duration = Motion.med,
  });

  final Widget child;
  final bool reverse;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, duration),
      switchInCurve: Motion.curve,
      switchOutCurve: Motion.curve,
      transitionBuilder: (candidate, animation) {
        // The switcher runs the outgoing child's animation in reverse, so its
        // begin offset must sit on the opposite side of the incoming one.
        final incoming = candidate.key == child.key;
        final begin = incoming == !reverse
            ? const Offset(.22, 0)
            : const Offset(-.22, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: begin, end: Offset.zero).animate(animation),
            child: RepaintBoundary(child: candidate),
          ),
        );
      },
      child: child,
    );
  }
}

/// Eases text or an icon between two inks instead of cutting between them.
///
/// The gap this closes: a control whose background animates on hover while
/// its label changes colour in a single frame reads as two controls answering
/// at different speeds. [AnimatedDefaultTextStyle] would also do it, but it
/// *replaces* the ambient text style rather than merging into it, which
/// silently drops the app's font family — hence the tween on the colour alone.
class AnimatedInk extends StatelessWidget {
  const AnimatedInk({
    super.key,
    required this.color,
    this.duration = Motion.instant,
    required this.builder,
  });

  final Color color;
  final Duration duration;

  /// Receives the interpolated colour; hand it to a [Text] style or [Icon].
  final Widget Function(BuildContext context, Color color) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: Motion.of(context, duration),
      curve: Motion.curve,
      // No begin: the first build settles on the current colour rather than
      // animating in from nothing.
      tween: ColorTween(end: color),
      builder: (context, value, _) => builder(context, value ?? color),
    );
  }
}

/// Fade + slide-up entrance, played once on mount; [delay] staggers items
/// (the mock's `portUp` keyframes).
class EnterUp extends StatefulWidget {
  const EnterUp({
    super.key,
    this.delay = Duration.zero,
    this.duration = Motion.fast,
    required this.child,
  });

  final Duration delay;
  final Duration duration;
  final Widget child;

  @override
  State<EnterUp> createState() => _EnterUpState();
}

class _EnterUpState extends State<EnterUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _anim = CurvedAnimation(
    parent: _controller,
    curve: Motion.arrive,
  );

  /// Held so it can be cancelled. `Future.delayed` keeps running after the
  /// widget goes away — harmless in the app, where the callback checks
  /// `mounted`, but a leak all the same, and it reaches a disposed controller
  /// whenever the widget leaves before its own entrance starts, which is
  /// exactly what a fast route change is.
  Timer? _pending;

  @override
  void initState() {
    super.initState();
    // A cancellable Timer rather than Future.delayed, which fails any widget
    // test that tears the tree down before a staggered item has had its turn.
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _pending = Timer(widget.delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _pending?.cancel();
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The staggered entrance is decorative: it carries no state change a
    // reader would miss. Under Reduce Motion the content is simply already
    // there, rather than sliding in faster.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    // FadeTransition animates the layer's opacity (no per-frame rebuild nor
    // widget-level saveLayer, unlike an Opacity built inside a builder).
    return FadeTransition(
      opacity: _anim,
      // A fully transparent RenderOpacity drops its subtree from the semantics
      // tree, so without this the content is missing for a screen reader for
      // as long as the entrance runs — and permanently for anything whose
      // entrance never fires.
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 14 * (1 - _anim.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
