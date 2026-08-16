import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/motion.dart';

/// Carries the landing's scroll controller down to the [Reveal]s, which need
/// to know when they have come into view.
///
/// An [InheritedWidget] rather than a constructor argument because reveals sit
/// several sections deep inside `const` subtrees, and threading the controller
/// through every one of them would make each section stateful for no reason.
class LandingScrollScope extends InheritedWidget {
  const LandingScrollScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;

  static ScrollController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LandingScrollScope>()
      ?.controller;

  @override
  bool updateShouldNotify(LandingScrollScope oldWidget) =>
      oldWidget.controller != controller;
}

/// Fade + rise, played once, the first time the element comes within reach of
/// the viewport bottom.
///
/// Distinct from [EnterUp], which fires on mount: everything below the fold
/// mounts at the same instant on this page, so an on-mount entrance would run
/// its whole choreography against a screen nobody is looking at and leave the
/// rest of the page arriving dead. Travel is deliberately short — this is the
/// supporting motion, and the hero sheet is the only authored entrance here.
class Reveal extends StatefulWidget {
  const Reveal({super.key, this.delay = Duration.zero, required this.child});

  /// Staggers siblings that read as a row of peers. Keep the total under a
  /// few hundred ms: past that the last cell arrives after the eye has moved.
  final Duration delay;

  final Widget child;

  /// How far above the viewport bottom the element's top edge has to reach
  /// before it counts as seen. Enough that the motion is already finishing by
  /// the time the element is properly on screen, rather than starting there.
  static const double _margin = 64;

  /// Distance travelled on the way in.
  static const double _rise = 16;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );
  late final CurvedAnimation _anim = CurvedAnimation(
    parent: _controller,
    curve: Motion.arrive,
  );

  ScrollController? _scroll;

  /// Held so it can be cancelled: a stagger delay left running past dispose
  /// would call into a torn-down controller, and a page scrolled and left
  /// quickly enough is exactly when that happens.
  Timer? _pending;

  bool _fired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = LandingScrollScope.maybeOf(context);
    if (scroll == _scroll) return;
    _scroll?.removeListener(_check);
    _scroll = _fired ? null : scroll;
    _scroll?.addListener(_check);
  }

  /// Fires as soon as the element's top edge clears the trigger line. Reading
  /// the box position beats attaching a viewport observer per section: it is
  /// two cheap render-tree reads, and the listener detaches for good the
  /// moment it fires, so a fully scrolled page costs nothing.
  void _check() {
    if (_fired || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top > MediaQuery.sizeOf(context).height - Reveal._margin) return;

    _fired = true;
    _scroll?.removeListener(_check);
    _scroll = null;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _pending = Timer(widget.delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _pending?.cancel();
    _scroll?.removeListener(_check);
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Decorative: the content carries no state a reader would miss by having
    // it simply be there already.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    // Anything still hidden when the frame ends gets re-checked, which covers
    // the first paint and any resize that brings it into view without a
    // scroll. Stops being scheduled once it has fired.
    if (!_fired) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }

    return FadeTransition(
      opacity: _anim,
      // Without this the section is absent from the semantics tree until it
      // is scrolled to, so a screen reader walking the page top to bottom
      // would find most of it missing.
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, Reveal._rise * (1 - _anim.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
