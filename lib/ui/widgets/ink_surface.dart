import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'motion.dart';

/// MD3 interactive surface for the app's cards. [builder] receives the hover
/// flag for content that only appears on hover (e.g. a card's kebab).
class InkSurface extends StatefulWidget {
  const InkSurface({
    super.key,
    required this.onTap,
    required this.builder,
    this.borderRadius = 14,
    this.padding = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.hoverBorderColor,
    this.hoverElevation = 5,
    this.clipBehavior = Clip.antiAlias,
  });

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool hovered) builder;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// Defaults resolve against the theme tokens (surface / border / accent).
  final Color? color;
  final Color? borderColor;
  final Color? hoverBorderColor;

  /// Resting elevation is always 0 (flat outlined card); this is the lift on
  /// hover. Set to 0 for surfaces that shouldn't cast a shadow (e.g. the
  /// dashed "new" card).
  final double hoverElevation;
  final Clip clipBehavior;

  @override
  State<InkSurface> createState() => _InkSurfaceState();
}

class _InkSurfaceState extends State<InkSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = widget.onTap != null;
    final lifted = _hovered && enabled;
    final base = widget.color ?? t.surface;
    final border = widget.borderColor ?? t.border;
    final hoverBorder = widget.hoverBorderColor ?? t.accent;
    final radius = BorderRadius.circular(widget.borderRadius);

    // Material animates color / elevation / shape over animationDuration, so
    // the lift, the shadow and the border tint all ease in together.
    return Material(
      animationDuration: Motion.med,
      color: base,
      elevation: lifted ? widget.hoverElevation : 0,
      shadowColor: Elevation.materialShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: lifted ? hoverBorder : border),
      ),
      clipBehavior: widget.clipBehavior,
      child: InkWell(
        onTap: widget.onTap,
        onHover: enabled ? (h) => setState(() => _hovered = h) : null,
        borderRadius: radius,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return t.accent.withValues(alpha: 0.11);
          }
          if (states.contains(WidgetState.hovered)) {
            return t.accent.withValues(alpha: 0.05);
          }
          return null;
        }),
        child: Padding(
          padding: widget.padding,
          child: widget.builder(context, _hovered),
        ),
      ),
    );
  }
}
