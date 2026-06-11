import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';

/// Detección de hover/pressed compartida por los botones del catálogo.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.onTap,
    this.tooltip,
  });

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

/// Botón del rediseño (`.btn--primary` / `.btn--ghost`). Con [label] nulo se
/// vuelve cuadrado (solo icono, como el Exportar compacto del móvil).
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
    final habilitado = onPressed != null && !busy;
    final esPrimary = variant == AppButtonVariant.primary;

    return Pressable(
      onTap: habilitado ? onPressed : null,
      builder: (context, hovered, pressed) {
        final bg = esPrimary
            ? (hovered ? t.accentStrong : t.accent)
            : (hovered ? t.surface2 : Colors.transparent);
        final fg = esPrimary ? t.accentInk : (hovered ? t.text : t.textDim);

        // El ancho siempre es intrínseco: pasar de width fijo a null rompe
        // la interpolación de AnimatedContainer (finito ↔ infinito). El
        // botón solo-icono se hace cuadrado con padding simétrico.
        return AnimatedContainer(
          duration: Dimens.dFast,
          height: height,
          padding: EdgeInsets.symmetric(
              horizontal: label != null ? 16 : (height - 17) / 2),
          transform: pressed
              ? (Matrix4.identity()..translateByDouble(0, 1, 0, 1))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: habilitado ? bg : bg.withValues(alpha: esPrimary ? 0.55 : 0),
            borderRadius: BorderRadius.circular(Dimens.rControl),
            border: esPrimary ? null : Border.all(color: t.border),
            boxShadow: esPrimary && habilitado
                ? const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 2,
                        offset: Offset(0, 1)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else if (icon != null)
                Icon(icon, size: 17, color: fg),
              if (label != null) ...[
                if (icon != null || busy) const SizedBox(width: 8),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: height >= Dimens.hExportMobile ? 15 : 13.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
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

/// Botón de icono 38×38 (`.icon-btn`). [bordered] añade el borde sutil;
/// [elevated] lo convierte en FAB pequeño (zoom de la vista previa).
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
                        offset: Offset(0, 2)),
                  ]
                : null,
          ),
          child: Icon(icon, size: 19, color: hovered ? t.text : t.textDim),
        );
      },
    );
  }
}
