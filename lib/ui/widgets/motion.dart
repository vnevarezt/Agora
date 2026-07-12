import 'package:flutter/material.dart';

/// Shared motion language: one ease-out curve (the mock's cubic-bezier) and
/// consistent durations, so every surface moves the same way.
abstract final class Motion {
  static const Curve curve = Cubic(.2, .8, .3, 1);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration med = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// Cross-fade with a subtle upward settle between children — the default
/// transition for swapping whole surfaces (gate states, shell sections).
/// Give each child a distinct key.
class FadeThroughSwitcher extends StatelessWidget {
  const FadeThroughSwitcher({
    super.key,
    required this.child,
    this.duration = Motion.med,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Motion.curve,
      switchOutCurve: Motion.curve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .015),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
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
            child: candidate,
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _anim.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
