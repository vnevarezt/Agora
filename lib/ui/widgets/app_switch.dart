import 'package:flutter/material.dart';

import '../theme/dimens.dart';

/// A [Switch] painted smaller than the platform default (via [scale]) while
/// keeping a real [Dimens.hTouchMin] tap area — a bare `Transform.scale`
/// around a `Switch` shrinks the hit region along with the paint, which is
/// how the app's toggles ended up under the 48dp floor everywhere.
///
/// Set [interactive] to false when this sits inside a row that already owns
/// a full-row tap handler wired to the same [onChanged] (the settings-menu
/// toggles do this). Two overlapping tap regions calling the same callback
/// double-fire — that's what read as the switch "reacting twice" on hover.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.scale = 0.85,
    this.interactive = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double scale;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final painted = Transform.scale(
      scale: scale,
      child: IgnorePointer(
        child: Switch(value: value, onChanged: onChanged),
      ),
    );

    if (!interactive) {
      return Semantics(toggled: value, child: painted);
    }

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: SizedBox(
        width: Dimens.hTouchMin,
        height: Dimens.hTouchMin,
        child: MouseRegion(
          cursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => onChanged!(!value) : null,
            // The real Switch renders the correct enabled/disabled/selected
            // look; the outer GestureDetector owns the tap so the hit area
            // doesn't shrink with the paint.
            child: Center(child: painted),
          ),
        ),
      ),
    );
  }
}
