import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import 'app_spinner.dart';
import '../theme/tokens.dart';

/// Shared hover/pressed detection for the catalog buttons.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.builder, this.onTap, this.tooltip});

  final Widget Function(BuildContext context, bool hovered, bool pressed)
  builder;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Widget child = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // opaque: with the default deferToChild only PAINTED pixels react,
        // so controls without a background (bottom-nav items, text links)
        // had dead zones everywhere except the icon/label glyphs.
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: widget.builder(context, _hovered, _pressed),
      ),
    );
    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}

enum AppButtonVariant { primary, ghost }

/// Button (`.btn--primary` / `.btn--ghost`). With a null [label] it
/// becomes square (icon only, like the compact mobile Export).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.label,
    this.height = Dimens.hControl,
    this.busy = false,
    this.expand = false,
  });

  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final String? label;
  final double height;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null && !busy;
    final esPrimary = variant == AppButtonVariant.primary;

    return Pressable(
      onTap: enabled ? onPressed : null,
      builder: (context, hovered, pressed) {
        final bg = esPrimary
            ? (hovered ? t.accentStrong : t.accent)
            : (hovered ? t.surface2 : Colors.transparent);
        final fg = esPrimary ? t.accentInk : (hovered ? t.text : t.textDim);

        // The width is always intrinsic: going from fixed width to null
        // breaks the AnimatedContainer interpolation (finite <-> infinite). The
        // icon-only button is made square with symmetric padding.
        return AnimatedContainer(
          duration: Dimens.dFast,
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 16 : (height - 17) / 2,
          ),
          transform: pressed
              ? (Matrix4.identity()..translateByDouble(0, 1, 0, 1))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: enabled ? bg : bg.withValues(alpha: esPrimary ? 0.55 : 0),
            borderRadius: BorderRadius.circular(Dimens.rControl),
            border: esPrimary ? null : Border.all(color: t.border),
            boxShadow: esPrimary && enabled
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                AppSpinner(size: 15, color: fg)
              else if (icon != null)
                Icon(icon, size: 17, color: fg),
              if (label != null) ...[
                if (icon != null || busy) const SizedBox(width: 8),
                // Flexible: a label longer than the button ellipsizes instead
                // of overflowing the Row.
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: height >= Dimens.hExportMobile ? 15 : 13.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 38x38 icon button (`.icon-btn`). [bordered] adds the subtle border;
/// [elevated] turns it into a small FAB (preview zoom).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.bordered = false,
    this.elevated = false,
    this.size = Dimens.hControl,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool bordered;
  final bool elevated;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onPressed,
      tooltip: tooltip,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: Dimens.dFast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: elevated
                ? (hovered ? t.surface2 : t.surface)
                : (hovered ? t.surface2 : Colors.transparent),
            borderRadius: BorderRadius.circular(Dimens.rControl),
            border: bordered || elevated ? Border.all(color: t.border) : null,
            boxShadow: elevated
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 19, color: hovered ? t.text : t.textDim),
        );
      },
    );
  }
}
