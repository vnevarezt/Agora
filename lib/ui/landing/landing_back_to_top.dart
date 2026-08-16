import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/motion.dart';
import 'landing_glass.dart';

/// Floating return to the top of the page, in the same glass as the header so
/// the two read as one layer of chrome floating over the content rather than
/// two unrelated controls.
///
/// It earns its place only on a page this long: the reader is several sections
/// deep, the header has scrolled past, and the alternative is a flick back
/// through everything they just read.
class LandingBackToTop extends StatefulWidget {
  const LandingBackToTop({
    super.key,
    required this.scrollController,
    required this.onTap,
  });

  final ScrollController scrollController;
  final VoidCallback onTap;

  /// Comfortably past the touch-target floor: this control floats over content
  /// with nothing adjacent to it, so it can afford to be the size it wants to
  /// be rather than the size it must be.
  static const double size = 52;

  /// Appears once the hero is properly behind the reader. Tied to the viewport
  /// rather than a fixed offset so it arrives at the same point in the page on
  /// a laptop and on a phone.
  static const double _showAfterViewports = 0.75;

  @override
  State<LandingBackToTop> createState() => _LandingBackToTopState();
}

class _LandingBackToTopState extends State<LandingBackToTop> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant LandingBackToTop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  /// Rebuilds on the crossing, not on the scroll — the same rule the header's
  /// rule follows, and for the same reason.
  void _onScroll() {
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    final threshold =
        MediaQuery.sizeOf(context).height *
        LandingBackToTop._showAfterViewports;
    final visible = controller.offset > threshold;
    if (visible != _visible) setState(() => _visible = visible);
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
    final label = tr.landing.backToTop;
    final duration = Motion.of(context, Motion.med);

    return IgnorePointer(
      ignoring: !_visible,
      // A button that is invisible but still announced is a button a screen
      // reader user is invited to press and cannot see the result of.
      child: ExcludeSemantics(
        excluding: !_visible,
        child: AnimatedSlide(
          duration: duration,
          curve: Motion.arrive,
          // Leaves downward, the direction it sends the reader back from.
          offset: _visible ? Offset.zero : const Offset(0, 0.4),
          child: AnimatedOpacity(
            duration: duration,
            curve: Motion.curve,
            opacity: _visible ? 1 : 0,
            child: AnimatedScale(
              duration: duration,
              curve: Motion.arrive,
              scale: _visible ? 1 : 0.85,
              child: Pressable(
                onTap: widget.onTap,
                tooltip: label,
                semanticLabel: label,
                builder: (context, hovered, pressed) => LiquidGlass(
                  borderRadius: BorderRadius.circular(
                    LandingBackToTop.size / 2,
                  ),
                  border: Border.all(color: t.border),
                  boxShadow: Elevation.raised,
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.instant),
                    curve: Motion.curve,
                    width: LandingBackToTop.size,
                    height: LandingBackToTop.size,
                    transform: pressed
                        ? (Matrix4.identity()..translateByDouble(0, 1, 0, 1))
                        : Matrix4.identity(),
                    alignment: Alignment.center,
                    // The arrow lifts on hover — the control previewing the
                    // thing it is about to do.
                    child: AnimatedSlide(
                      duration: Motion.of(context, Motion.instant),
                      curve: Motion.curve,
                      offset: hovered ? const Offset(0, -0.12) : Offset.zero,
                      child: AnimatedInk(
                        color: hovered ? t.text : t.textDim,
                        builder: (context, color) => Icon(
                          Icons.arrow_upward_rounded,
                          size: 21,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
