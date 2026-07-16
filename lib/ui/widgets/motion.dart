import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Shared motion language: one ease-out curve (the mock's cubic-bezier) and
/// consistent durations, so every surface moves the same way.
abstract final class Motion {
  static const Curve curve = Cubic(.2, .8, .3, 1);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration med = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
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
      duration: duration,
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
      duration: duration,
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

/// Fade + slide-up entrance, played once on mount; [delay] staggers items
/// (the mock's `portUp` keyframes).
class EnterUp extends StatefulWidget {
  const EnterUp({
    super.key,
    this.delay = Duration.zero,
    this.duration = Motion.slow,
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
    curve: Motion.curve,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition animates the layer's opacity (no per-frame rebuild nor
    // widget-level saveLayer, unlike an Opacity built inside a builder).
    return FadeTransition(
      opacity: _anim,
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
