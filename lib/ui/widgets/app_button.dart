import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'app_spinner.dart';
import 'motion.dart';

/// Shared hover/pressed detection for the catalog buttons.
///
/// The `hovered` flag the builder receives is true while the pointer is over
/// the control OR while it is held down. Touch devices have no hover, so
/// every control styled only on `hovered` — most of the ghost buttons, icon
/// buttons and nav items — used to sit in its resting state with no reaction
/// to a finger at all. The theme also disables the Material ripple
/// (`NoSplash`), so nothing else was covering that gap.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.onTap,
    this.tooltip,
    this.semanticLabel,
    this.focusRadius = Dimens.rControl,
  });

  final Widget Function(BuildContext context, bool hovered, bool pressed)
  builder;
  final VoidCallback? onTap;
  final String? tooltip;

  /// Corner radius of the keyboard focus ring, so it traces the control it
  /// belongs to instead of a generic rounded rect. Pass the same radius the
  /// builder paints.
  final double focusRadius;

  /// What VoiceOver / TalkBack announces. Required in practice for controls
  /// whose only content is an icon: a bare [GestureDetector] exposes the tap
  /// action but no role and no name, so a screen reader lands on an anonymous
  /// element. Controls that render their own text can leave this null — the
  /// text is already the name.
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  void _activate() {
    // Keyboard activation has no press phase of its own; flash the pressed
    // state so Space/Enter reads like a tap instead of firing invisibly.
    if (widget.onTap == null) return;
    setState(() => _pressed = true);
    widget.onTap!();
    Future.delayed(Motion.instant, () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    Widget child = FocusableActionDetector(
      enabled: enabled,
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      // Only true when the focus arrived by keyboard, so a mouse click never
      // leaves a ring behind.
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent:
            CallbackAction<ActivateIntent>(onInvoke: (_) => _activate()),
      },
      child: GestureDetector(
        // opaque: with the default deferToChild only PAINTED pixels react,
        // so controls without a background (bottom-nav items, text links)
        // had dead zones everywhere except the icon/label glyphs.
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: widget.builder(context, _hovered || _pressed, _pressed),
      ),
    );

    // Foreground decoration, so the ring paints over the control without
    // taking part in layout — a focus state that resized the button would
    // shift everything next to it.
    child = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.focusRadius),
        border: _focused
            ? Border.all(color: context.tokens.accent, width: 2)
            : null,
      ),
      child: child,
    );

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: child,
    );
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
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final String? label;
  final double height;
  final bool busy;
  final bool expand;

  /// Announced name. Only needed in the icon-only form ([label] null), where
  /// the button renders no text for a screen reader to read.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null && !busy;
    final esPrimary = variant == AppButtonVariant.primary;

    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: semanticLabel,
      builder: (context, hovered, pressed) {
        final bg = esPrimary
            ? (hovered ? t.accentStrong : t.accent)
            : (hovered ? t.surface2 : Colors.transparent);
        final fg = esPrimary ? t.accentInk : (hovered ? t.text : t.textDim);

        // The width is always intrinsic: going from fixed width to null
        // breaks the AnimatedContainer interpolation (finite <-> infinite). The
        // icon-only button is made square with symmetric padding.
        // minHeight, not height: at the largest system text size a fixed box
        // clips its own label. The button keeps its designed height at normal
        // scale and grows only when the text needs the room.
        return AnimatedContainer(
          duration: Motion.of(context, Motion.instant),
          constraints: BoxConstraints(minHeight: height),
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 16 : (height - 17) / 2,
            vertical: Space.s4,
          ),
          transform: pressed
              ? (Matrix4.identity()..translateByDouble(0, 1, 0, 1))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: enabled ? bg : bg.withValues(alpha: esPrimary ? 0.55 : 0),
            borderRadius: BorderRadius.circular(Dimens.rControl),
            border: esPrimary ? null : Border.all(color: t.border),
            boxShadow: esPrimary && enabled ? Elevation.control : null,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                AppSpinner(size: 15, color: fg)
              else if (icon != null)
                Icon(icon, size: AppIcon.control, color: fg),
              if (label != null) ...[
                if (icon != null || busy) const SizedBox(width: Space.s8),
                // Flexible: a label longer than the button ellipsizes instead
                // of overflowing the Row.
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: height >= Dimens.hExportMobile
                          ? AppText.bodyLarge
                          : AppText.body,
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
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool bordered;
  final bool elevated;
  final double size;

  /// Overrides the announced name. Defaults to [tooltip], which already
  /// describes the action in words — an icon-only button has nothing else a
  /// screen reader could read.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onPressed,
      tooltip: tooltip,
      semanticLabel: semanticLabel ?? tooltip,
      builder: (context, hovered, pressed) {
        final visual = AnimatedContainer(
          duration: Motion.of(context, Motion.instant),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: elevated
                ? (hovered ? t.surface2 : t.surface)
                : (hovered ? t.surface2 : Colors.transparent),
            borderRadius: BorderRadius.circular(Dimens.rControl),
            border: bordered || elevated ? Border.all(color: t.border) : null,
            boxShadow: elevated ? Elevation.raised : null,
          ),
          child: Icon(icon, size: AppIcon.control, color: hovered ? t.text : t.textDim),
        );
        // The paint stays [size]; the tap area never shrinks below the
        // platform touch-target floor. Callers positioning this precisely
        // (e.g. Positioned in a Stack) must compensate by (hTouchMin -
        // size) / 2 to keep the visible control's position unchanged.
        if (size >= Dimens.hTouchMin) return visual;
        return SizedBox(
          width: Dimens.hTouchMin,
          height: Dimens.hTouchMin,
          child: Center(child: visual),
        );
      },
    );
  }
}
