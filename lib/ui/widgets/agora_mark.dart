import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// The drawing itself, a hand copy of `tool/gen_brand_assets.py` — the script
/// that renders every file under `assets/brand/` and the only other place
/// these numbers exist. `test/ui/agora_mark_test.dart` compares the two and
/// fails if either moves.
///
/// Painted rather than loaded from `agora-mark.png` because the animations
/// below have to take the mark apart: a bitmap can only be faded and scaled,
/// and the whole point is that one diagonal cuts both planes.
abstract final class _Mark {
  /// x, y, w, h — the tight box around both polygons.
  static const Rect art = Rect.fromLTWH(9, 5, 46, 51);

  static const List<Offset> back = [
    Offset(9, 17),
    Offset(33, 10.7),
    Offset(25, 56),
    Offset(9, 56),
  ];

  static const List<Offset> front = [
    Offset(40, 8.9),
    Offset(55, 5),
    Offset(55, 56),
    Offset(32, 56),
  ];

  /// The cut: the one line all four top vertices fall on, from the back
  /// plane's top-left corner to the front plane's top-right.
  static final Offset cutFrom = back.first;
  static final Offset cutTo = front[1];

  /// Along the cut, and perpendicular to it pointing down into both planes.
  static final Offset dir = (cutTo - cutFrom) / (cutTo - cutFrom).distance;
  static final Offset normal = Offset(-dir.dy, dir.dx);

  /// Brand inks, not theme tokens: the mark is the same drawing on every
  /// palette. Only the back plane moves, because `#14208f` drowns below
  /// `#1a1f26` (see assets/brand/README.md).
  static const Color inkBackOnLight = Color(0xFF14208F);
  static const Color inkBackOnDark = Color(0xFF3350E0);
  static const Color inkFront = Color(0xFF4AA8EE);

  /// The wordmark's ink beside the mark, also from the generator. Not the
  /// `text` token: on light grounds the lockup's word is brand navy rather
  /// than the app's near-black, and matching it is the whole reason the
  /// in-app lockup and the one in the stores read as the same object.
  static const Color wordOnLight = Color(0xFF14208F);
  static const Color wordOnDark = Color(0xFFECEFF2);

  /// The light that does the cutting, in both animations: the front ink,
  /// lifted. Deliberately not white — a white leading edge is invisible
  /// against the light theme's near-white ground, so the plane would look
  /// eaten away at exactly the moment it should look lit.
  static final Color glint = Color.lerp(inkFront, Colors.white, .35)!;

  /// How far [poly] reaches below the cut — the distance a fill has to travel
  /// to arrive at the line.
  static double depth(List<Offset> poly) => poly.fold(0, (deepest, v) {
    final rel = v - cutFrom;
    return math.max(deepest, rel.dx * normal.dx + rel.dy * normal.dy);
  });

  static Path path(List<Offset> poly) => Path()..addPolygon(poly, true);

  /// Maps a depth fraction (0 at the cut, 1 at [poly]'s deepest point) onto a
  /// gradient laid along that axis, so both animations can describe where
  /// their light is in the same units.
  static ui.Gradient wash(
    double depth,
    List<Color> colors,
    List<double> stops, {
    double from = 0,
    double to = 1,
  }) {
    return ui.Gradient.linear(
      cutFrom + normal * (depth * from),
      cutFrom + normal * (depth * to),
      colors,
      stops,
    );
  }

  static (Color, Color) inks(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return (dark ? inkBackOnDark : inkBackOnLight, inkFront);
  }
}

/// The Agora mark, [size] tall; the width follows the drawing's 46:51 box.
class AgoraMark extends StatelessWidget {
  const AgoraMark({super.key, this.size = AppIcon.hero});

  final double size;

  @override
  Widget build(BuildContext context) {
    // A CustomPaint announces nothing at all, so on the cover screen the
    // product's own name was invisible to a screen reader.
    return Semantics(
      image: true,
      label: context.t.app.brand,
      child: _MarkBox(
        size: size,
        progress: const AlwaysStoppedAnimation<double>(1),
      ),
    );
  }
}

/// The mark beside the wordmark, in the proportions assets/brand/README.md
/// lays down for a mark of height H: gap `0.30 H`, word at `0.63 H`, tracking
/// `-0.035em`.
///
/// Built live rather than shipped as `agora-lockup-*.png`, which is what that
/// README asks for anywhere the app can do it: the PNG is for READMEs and
/// stores, and it cannot follow the theme or stay crisp at an arbitrary size.
class AgoraLockup extends StatelessWidget {
  const AgoraLockup({super.key, this.size = 30});

  /// Height of the mark; everything else is derived from it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The wordmark beside it already carries the name; a labelled mark
        // here would have a screen reader say "Agora Agora".
        ExcludeSemantics(child: AgoraMark(size: size)),
        SizedBox(width: size * .3),
        Text(
          context.t.app.brand,
          style: TextStyle(
            fontSize: size * .63,
            fontWeight: FontWeight.w800,
            letterSpacing: size * .63 * -.035,
            height: 1,
            color: dark ? _Mark.wordOnDark : _Mark.wordOnLight,
          ),
        ),
      ],
    );
  }
}

/// [AgoraMark] playing its entrance once on mount: a streak of light draws the
/// cut before there is anything to cut, each plane then grows up to meet it —
/// back plane leading, its leading edge lit by the same light — and the streak
/// retracts along the line once the planes are its own edge.
///
/// [onEnd] fires exactly once when the mark has settled, including under
/// Reduce Motion, where it is already settled on the first frame.
class AgoraMarkEntrance extends StatefulWidget {
  const AgoraMarkEntrance({super.key, this.size = AppIcon.hero, this.onEnd});

  final double size;
  final VoidCallback? onEnd;

  @override
  State<AgoraMarkEntrance> createState() => _AgoraMarkEntranceState();
}

class _AgoraMarkEntranceState extends State<AgoraMarkEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: Motion.focal)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onEnd?.call();
        });

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
      return;
    }
    // Reduce Motion gets the finished mark rather than a faster entrance, but
    // the callback still has to fire or whatever waits on it never appears.
    // Not by setting `value` here: that notifies synchronously, which would
    // land the listener's setState inside this build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.value = 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MarkBox(size: widget.size, progress: _controller);
  }
}

/// An indeterminate loader that animates the drawing rather than decorating
/// it: the two planes shuttle apart along the cut and back together, the front
/// one trailing the back, holding briefly at the end of each beat so the loop
/// reads as deliberate rather than as something spinning.
///
/// They travel along the cut because every top vertex sits on that line, so
/// sliding a plane down it leaves the remates exactly where they were: the
/// diagonal survives the whole move. No other direction has that property,
/// which is what makes this the mark's own move rather than one borrowed from
/// a logo with a circle in it.
///
/// [color] paints both planes in one ink, the way `agora-mark-mono.svg` does,
/// for grounds the brand blues cannot sit on (inside a filled button).
class AgoraLoader extends StatefulWidget {
  const AgoraLoader({super.key, this.size = AppIcon.feature, this.color});

  final double size;
  final Color? color;

  @override
  State<AgoraLoader> createState() => _AgoraLoaderState();
}

class _AgoraLoaderState extends State<AgoraLoader>
    with SingleTickerProviderStateMixin {
  // Not routed through Motion.of: see Motion.loop. Stopping an indeterminate
  // indicator claims the work finished.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.loop,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (back, front) = _Mark.inks(context);
    return Semantics(
      label: context.t.common.loading,
      liveRegion: true,
      child: SizedBox(
        width:
            widget.size * _LoaderPainter.box.width / _LoaderPainter.box.height,
        height: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _LoaderPainter(
              progress: _controller,
              back: widget.color ?? back,
              front: widget.color ?? front,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkBox extends StatelessWidget {
  const _MarkBox({required this.size, required this.progress});

  final double size;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final (back, front) = _Mark.inks(context);
    return SizedBox(
      width: size * _Mark.art.width / _Mark.art.height,
      height: size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _MarkPainter(progress: progress, back: back, front: front),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.progress,
    required this.back,
    required this.front,
  }) : super(repaint: progress);

  /// Repaints the painter directly, so the entrance never rebuilds a widget.
  final Animation<double> progress;
  final Color back;
  final Color front;

  // The beats, as fractions of Motion.focal. Drawing the cut first and having
  // the planes grow up to it is what makes the diagonal read as the thing that
  // shaped the mark, rather than as an edge two shapes happen to share.
  //
  // The windows overlap generously because Motion.arrive is an exponential
  // ease: it spends nine tenths of its travel in the first third of whatever
  // interval it is given. Beats timed to divide the duration evenly all landed
  // inside the first 300ms and left the rest of the entrance standing still.
  static const _fadeIn = Interval(0, .14, curve: Motion.curve);
  static const _cutIn = Interval(0, .45, curve: Motion.arrive);
  static const _backRise = Interval(.10, .70, curve: Motion.arrive);
  static const _frontRise = Interval(.22, .88, curve: Motion.arrive);

  /// The streak's own tail, retracting along the line once the planes are
  /// under it: the light leaves the way it came in rather than dissolving in
  /// place, and it goes out for real on reaching the front plane, whose ink it
  /// is already painted in. Ease-in because it is the return leg of the draw.
  static final _cutOut = Interval(.45, 1, curve: Motion.curveOut);

  /// How far below the reveal edge the lit rim fades back into flat ink, as a
  /// fraction of the plane's depth. A filo, not a wash: wider than this and
  /// the plane stops arriving and starts looking merely unfinished, because
  /// early on the rim is a large share of the little that has been revealed.
  static const double _rim = .04;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final alpha = _fadeIn.transform(t);
    if (alpha <= 0) return;

    final scale = size.height / _Mark.art.height;
    canvas.save();
    // A settle rather than an arrival: the wipe already carries the entrance,
    // so this is only here to keep the mark from landing at full size.
    final settle = .95 + .05 * Motion.arrive.transform(t);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(settle * scale);
    canvas.translate(-_Mark.art.center.dx, -_Mark.art.center.dy);

    _streak(canvas, t, alpha, scale);
    _plane(canvas, _Mark.back, back, _backRise.transform(t), alpha, scale);
    _plane(canvas, _Mark.front, front, _frontRise.transform(t), alpha, scale);

    canvas.restore();
  }

  /// The light travelling along the cut: a head that fades back into nothing
  /// over its own tail, with a wide dim pass under it.
  void _streak(Canvas canvas, double t, double alpha, double scale) {
    final head = _cutIn.transform(t);
    final tail = _cutOut.transform(t);
    if (head <= tail) return;

    final from = Offset.lerp(_Mark.cutFrom, _Mark.cutTo, tail)!;
    final to = Offset.lerp(_Mark.cutFrom, _Mark.cutTo, head)!;

    // A hairline stays a hairline. Scaled with the mark it is a fair 1.5px on
    // the splash and a 5px bar at preview size, which is what made the cut
    // read as a rule ruled over the mark instead of the light that cut it.
    final hair = 1.5 * math.sqrt(_Mark.art.height * scale / 64) / scale;

    // Dim and wide first, then the line itself: two passes of the same stroke
    // is what separates light from ink at this size.
    for (final (width, weight) in const [(3.4, .16), (1.0, 1.0)]) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..shader = ui.Gradient.linear(
            from,
            to,
            [
              front.withValues(alpha: 0),
              front.withValues(alpha: alpha * weight * .85),
              front.withValues(alpha: alpha * weight),
            ],
            const [0, .3, 1],
          )
          ..strokeWidth = hair * width
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Fills [poly] up to a line parallel to the cut, [grown] of the way from
  /// the plane's deepest point to the cut itself, with the reveal edge lit by
  /// the same light as the streak.
  ///
  /// One gradient fill rather than a clip or a path intersection: the shader
  /// carries the leading edge for free, and clipping a fill leaves a hairline
  /// seam where the two sets of antialiased edges meet.
  void _plane(
    Canvas canvas,
    List<Offset> poly,
    Color ink,
    double grown,
    double alpha,
    double scale,
  ) {
    if (grown <= 0) return;
    final depth = _Mark.depth(poly);
    final edge = 1 - grown;
    final clear = _Mark.glint.withValues(alpha: 0);
    final body = ink.withValues(alpha: alpha);
    // The rim goes out as the plane lands, so arriving is a fade rather than
    // the pop of a lit edge being replaced by flat ink in one frame.
    final rim = Color.lerp(ink, _Mark.glint, math.min(1, (1 - grown) * 5))!;

    // The shader is evaluated per pixel, so a pair of identical stops would
    // leave the reveal edge aliased along a diagonal that is nowhere near 45
    // degrees. One device pixel of ramp reads as sharp and resolves cleanly.
    final soft = (1 / (depth * scale)).clamp(.002, .05);

    canvas.drawPath(
      _Mark.path(poly),
      Paint()
        ..shader = _Mark.wash(
          depth,
          [clear, clear, rim.withValues(alpha: alpha), body, body],
          [0, math.max(0, edge - soft), edge, math.min(1, edge + _rim), 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.progress != progress || old.back != back || old.front != front;
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter({
    required this.progress,
    required this.back,
    required this.front,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color back;
  final Color front;

  /// The planes travel outside the art box as they open, so the loader draws
  /// into a padded one — otherwise the move is clipped. The cut runs shallow,
  /// so the room they need is nearly all sideways.
  static const double _padX = 9;
  static const double _padY = 3;
  static final Rect box = Rect.fromLTWH(
    _Mark.art.left - _padX,
    _Mark.art.top - _padY,
    _Mark.art.width + 2 * _padX,
    _Mark.art.height + 2 * _padY,
  );

  /// How far each plane runs along the cut, in the mark's own units.
  static const double _reach = 9;

  /// Two beats per turn, so a pair of moves returns both planes to where they
  /// started and the loop closes on the drawing rather than on a fade.
  static const int _beats = 2;

  /// Share of a beat spent moving. The rest is a hold, and the hold is what
  /// makes the loop read as deliberate instead of restless — it is also the
  /// moment the mark is whole, which is the one frame worth looking at.
  static const double _travel = .72;

  /// How far the front plane trails the back one, within a beat.
  static const double _lag = .14;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.height / box.height);
    canvas.translate(-box.left, -box.top);

    final beat = progress.value * _beats;
    for (final (i, poly) in [_Mark.back, _Mark.front].indexed) {
      final open = math.sin(
        math.pi *
            Motion.curve.transform(
              (((beat - i * _lag) % 1) / _travel).clamp(0.0, 1.0),
            ),
      );
      final move = _Mark.dir * ((i.isEven ? -_reach : _reach) * open);
      canvas.save();
      canvas.translate(move.dx, move.dy);
      canvas.drawPath(
        _Mark.path(poly),
        Paint()..color = i.isEven ? back : front,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoaderPainter old) =>
      old.progress != progress || old.back != back || old.front != front;
}
