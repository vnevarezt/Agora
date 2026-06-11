import 'package:flutter/material.dart';

/// Borde discontinuo sobre un rectángulo redondeado (círculo = radio máximo).
/// Flutter no trae bordes dashed; lo usan el avatar vacío y el botón
/// "Asignar…" para replicar el `border: dashed` del mock.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dash = 4,
    this.gap = 3.5,
    required this.child,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dash: dash,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final origen = Path()..addRRect(rrect);
    final dashed = Path();
    for (final metric in origen.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        dashed.addPath(metric.extractPath(d, d + dash), Offset.zero);
        d += dash + gap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}
