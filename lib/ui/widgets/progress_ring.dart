import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';

/// Assignment progress ring (`.ring` + `.progress__txt`): accent arc over
/// a border-colored base, number in the center and, optionally, the
/// "N/M asignados" text alongside.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.done,
    required this.total,
    this.showLabel = true,
    this.size = Dimens.ring,
  });

  final int done;
  final int total;
  final bool showLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final pct = total == 0 ? 0.0 : done / total;

    final anillo = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: pct,
          colorArco: t.accent,
          colorBase: t.border,
        ),
        child: Center(
          child: Text(
            '$done',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: t.text,
            ),
          ),
        ),
      ),
    );

    if (!showLabel) return anillo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        anillo,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$done/$total',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: t.text)),
            Text('asignados',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: t.textMute)),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.colorArco,
    required this.colorBase,
  });

  final double progress;
  final Color colorArco;
  final Color colorBase;

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 4.0;
    final centro = size.center(Offset.zero);
    final radio = (size.shortestSide - grosor) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = colorBase;
    canvas.drawCircle(centro, radio, base);

    if (progress > 0) {
      final arco = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..color = colorArco;
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        arco,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.colorArco != colorArco ||
      old.colorBase != colorBase;
}
