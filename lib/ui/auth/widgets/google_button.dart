import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_spinner.dart';

/// `.btn-google`: surface button with the four-color Google mark.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null && !busy;
    return Pressable(
      onTap: enabled ? onPressed : null,
      builder: (context, hovered, pressed) => AnimatedContainer(
        duration: Dimens.dFast,
        height: 46,
        decoration: BoxDecoration(
          color: hovered ? t.surface2 : t.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: hovered ? t.textMute : t.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              AppSpinner(size: 16, color: t.textDim)
            else
              const CustomPaint(
                size: Size(18, 18),
                painter: _GoogleLogoPainter(),
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Procedural approximation of the Google "G" (arcs + crossbar): faithful at
/// button size without shipping an asset or an SVG dependency.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final ring = Rect.fromCircle(
      center: Offset(12 * s, 12 * s),
      radius: 9.6 * s,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8 * s;
    double d(double deg) => deg * math.pi / 180;

    canvas.drawArc(ring, d(-13), d(58), false, stroke..color = _blue);
    canvas.drawArc(ring, d(45), d(105), false, stroke..color = _green);
    canvas.drawArc(ring, d(150), d(55), false, stroke..color = _yellow);
    canvas.drawArc(ring, d(205), d(90), false, stroke..color = _red);
    canvas.drawRect(
      Rect.fromLTRB(12 * s, 9.82 * s, 23.4 * s, 14.46 * s),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
