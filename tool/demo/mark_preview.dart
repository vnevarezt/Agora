// Watches the mark's entrance on a loop, light and dark side by side.
//
//   flutter run -t tool/demo/mark_preview.dart -d macos
//
// Nothing here ships: it exists so the entrance can be judged running rather
// than as a strip of stills. Slower speeds go through `timeDilation`, which
// stretches the real controller instead of retiming it — what you see at 8x
// is the same curve, so a beat that looks wrong there is wrong at 1x too.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/agora_mark.dart';

void main() => runApp(const MarkPreview());

class MarkPreview extends StatefulWidget {
  const MarkPreview({super.key});

  @override
  State<MarkPreview> createState() => _MarkPreviewState();
}

class _MarkPreviewState extends State<MarkPreview> {
  static const _speeds = [1.0, 2.0, 4.0, 8.0];
  static const _hold = Duration(milliseconds: 700);

  int _run = 0;
  double _slowdown = 1;
  Timer? _pending;

  /// Restarting means a new [AgoraMarkEntrance], since the entrance plays once
  /// on mount by design — looping is a property of this harness, not of the
  /// widget, and building the loop in here keeps it that way.
  void _replay() {
    _pending?.cancel();
    _pending = Timer(_hold, () {
      if (mounted) setState(() => _run++);
    });
  }

  @override
  void dispose() {
    _pending?.cancel();
    timeDilation = 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                for (final mode in Brightness.values)
                  Expanded(
                    child: _Panel(
                      mode: mode,
                      // Only one side drives the loop, or the two panels race
                      // each other and drift apart within a few cycles.
                      onEnd: mode == Brightness.light ? _replay : null,
                      run: _run,
                    ),
                  ),
              ],
            ),
          ),
          _Speeds(
            speeds: _speeds,
            current: _slowdown,
            onPick: (s) => setState(() {
              _slowdown = s;
              timeDilation = s;
              _run++;
            }),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.mode, required this.onEnd, required this.run});

  final Brightness mode;
  final VoidCallback? onEnd;
  final int run;

  @override
  Widget build(BuildContext context) {
    final tokens = mode == Brightness.light ? pizarra.light : pizarra.dark;
    return Theme(
      data: buildAppTheme(tokens, mode),
      child: ColoredBox(
        color: tokens.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big enough to read the geometry, then at the size the splash
              // actually uses — a beat that works at 220 can still be mush
              // at 64.
              AgoraMarkEntrance(key: ValueKey('$run-big'), size: 180),
              const SizedBox(height: 40),
              AgoraMarkEntrance(
                key: ValueKey('$run-splash'),
                size: 64,
                onEnd: onEnd,
              ),
              const SizedBox(height: 56),
              // The loader never restarts: it is the same widget all the way
              // through, so the seam between turns is on show rather than
              // hidden by a remount.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final size in [72.0, 40.0, 24.0, 16.0]) ...[
                    AgoraLoader(size: size),
                    const SizedBox(width: 26),
                  ],
                  // On a filled ground the brand blues have nowhere to sit, so
                  // the mono ink is what a button would use.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: AgoraLoader(size: 20, color: tokens.accentInk),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Speeds extends StatelessWidget {
  const _Speeds({
    required this.speeds,
    required this.current,
    required this.onPick,
  });

  final List<double> speeds;
  final double current;
  final ValueChanged<double> onPick;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: pizarra.dark.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final speed in speeds)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextButton(
                  onPressed: () => onPick(speed),
                  style: TextButton.styleFrom(
                    backgroundColor: speed == current
                        ? pizarra.dark.accent
                        : pizarra.dark.surface2,
                    foregroundColor: speed == current
                        ? pizarra.dark.accentInk
                        : pizarra.dark.text,
                  ),
                  child: Text(
                    speed == 1 ? 'real time' : '${speed.toInt()}x slower',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
