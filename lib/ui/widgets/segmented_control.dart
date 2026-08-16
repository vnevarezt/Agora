import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'motion.dart';

typedef Segment = ({IconData? icon, String label});

/// Segmented control (`.seg`): Assign/Preview tabs on mobile and the
/// static chip on the preview bar ([onChanged] null).
///
/// Segments can be equal-width ([expand]) or sized to their own content —
/// either way, a single indicator slides to whichever one is active instead
/// of each segment fading its own background independently. Since content
/// width isn't known in advance, the indicator's position is measured off
/// the actual segments after layout rather than computed from a fraction.
class SegmentedTabs extends StatefulWidget {
  const SegmentedTabs({
    super.key,
    required this.segments,
    this.index = 0,
    this.onChanged,
    this.expand = false,
  });

  final List<Segment> segments;
  final int index;
  final ValueChanged<int>? onChanged;

  /// On mobile the buttons share the available width.
  final bool expand;

  @override
  State<SegmentedTabs> createState() => _SegmentedTabsState();
}

class _SegmentedTabsState extends State<SegmentedTabs> {
  final _trackKey = GlobalKey();
  List<GlobalKey> _segmentKeys = const [];
  Rect? _indicator;

  @override
  void initState() {
    super.initState();
    _segmentKeys = List.generate(widget.segments.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(covariant SegmentedTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments.length != widget.segments.length) {
      _segmentKeys =
          List.generate(widget.segments.length, (_) => GlobalKey());
    }
  }

  /// Reads the active segment's rect relative to the track. Scheduled after
  /// every build (cheap: a couple of RenderBox reads) rather than only on
  /// index change, since content-sized segments can also move when their
  /// own label reflows (locale switch, dynamic type).
  void _measure() {
    if (!mounted || widget.index >= _segmentKeys.length) return;
    final track = _trackKey.currentContext?.findRenderObject() as RenderBox?;
    final segment =
        _segmentKeys[widget.index].currentContext?.findRenderObject()
            as RenderBox?;
    if (track == null || segment == null || !track.hasSize || !segment.hasSize) {
      return;
    }
    final origin = segment.localToGlobal(Offset.zero, ancestor: track);
    final rect = origin & segment.size;
    if (rect != _indicator) setState(() => _indicator = rect);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rControl),
        border: Border.all(color: t.border),
      ),
      child: Stack(
        key: _trackKey,
        children: [
          if (_indicator != null)
            AnimatedPositioned(
              duration: Motion.of(context, Motion.fast),
              curve: Motion.curve,
              left: _indicator!.left,
              top: _indicator!.top,
              width: _indicator!.width,
              height: _indicator!.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: esOscuro ? t.accentSoft : t.surface,
                  borderRadius: BorderRadius.circular(Dimens.rChip),
                  boxShadow: !esOscuro ? Elevation.control : null,
                ),
              ),
            ),
          Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.segments.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                _boton(t, i),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _boton(AppTokens t, int i) {
    final activo = i == widget.index;
    final button = Pressable(
      key: _segmentKeys[i],
      onTap: widget.onChanged == null || activo
          ? null
          : () => widget.onChanged!(i),
      builder: (context, hovered, _) {
        return AnimatedContainer(
          duration: Motion.of(context, Motion.instant),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            // The sliding indicator behind already carries the selected
            // look; hover only needs to read on an unselected segment, and
            // lighter than the indicator so it never reads as picked.
            color: !activo && hovered ? t.border2 : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimens.rChip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.segments[i].icon != null) ...[
                Icon(widget.segments[i].icon,
                    size: 15, color: activo ? t.text : t.textDim),
                const SizedBox(width: 6),
              ],
              Text(
                widget.segments[i].label,
                style: TextStyle(
                  fontSize: AppText.small,
                  fontWeight: FontWeight.w700,
                  color: activo ? t.text : t.textDim,
                ),
              ),
            ],
          ),
        );
      },
    );
    return widget.expand ? Expanded(child: button) : button;
  }
}
