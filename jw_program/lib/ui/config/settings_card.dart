import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Distribuye tarjetas en dos columnas (`.settings__cols`) en escritorio y en
/// una sola columna en pantallas estrechas.
class SettingsColumns extends StatelessWidget {
  const SettingsColumns({super.key, required this.left, required this.right});

  final List<Widget> left;
  final List<Widget> right;

  static List<Widget> _conSeparacion(List<Widget> cards) => [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          cards[i],
        ],
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _conSeparacion([...left, ...right]),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _conSeparacion(left),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _conSeparacion(right),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Rejilla de campos dentro de una tarjeta (`.set-grid`): 2 columnas en
/// escritorio, 1 en estrecho.
class SettingsGrid extends StatelessWidget {
  const SettingsGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gapX = 18.0;
        final cols = c.maxWidth < 300 ? 1 : 2;
        final colW = (c.maxWidth - (cols - 1) * gapX) / cols;
        return Wrap(
          spacing: gapX,
          runSpacing: 14,
          children: [
            for (final child in children) SizedBox(width: colW, child: child),
          ],
        );
      },
    );
  }
}

/// Tarjeta de configuración (`.set-card`): título uppercase, descripción y
/// contenido.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.title,
    this.desc,
    required this.children,
  });

  final String title;
  final String? desc;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: t.text,
            ),
          ),
          if (desc != null) ...[
            const SizedBox(height: 4),
            Text(
              desc!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: t.textMute,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Fila de ajuste (`.set-row`): título + descripción a la izquierda y un
/// control a la derecha. [first] omite el borde superior.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.first = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: first
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: t.border2)),
            ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: t.textMute,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 14),
            trailing!,
          ],
        ],
      ),
    );
  }
}
