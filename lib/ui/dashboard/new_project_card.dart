import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/tokens.dart';
import '../widgets/dashed_border.dart';
import '../widgets/motion.dart';

/// "Nuevo proyecto" card (`.project--new`): dashed border and a "+" ring.
/// The creation modal comes in a later phase; for now [onTap] stays optional.
///
/// Hover is driven by a single opaque [MouseRegion] (the one authority — no
/// nested hover regions to thrash against) and a single [TweenAnimationBuilder]
/// so the border, fill, ring, icon and label all ease together over the same
/// curve. The previous version flipped the dashed border instantly while the
/// fill animated separately, which read as a flicker.
class NewProjectCard extends StatefulWidget {
  const NewProjectCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<NewProjectCard> createState() => _NewProjectCardState();
}

class _NewProjectCardState extends State<NewProjectCard> {
  bool _hovered = false;

  void _setHover(bool v) {
    if (_hovered != v) setState(() => _hovered = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = widget.onTap != null;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _hovered && enabled ? 1.0 : 0.0),
          duration: Motion.med,
          curve: Motion.curve,
          builder: (context, a, _) {
            final border = Color.lerp(t.border, t.accent, a)!;
            final fg = Color.lerp(t.textMute, t.accentStrong, a)!;
            final fill = Color.lerp(Colors.transparent, t.accentTint, a)!;
            final ringFill = Color.lerp(Colors.transparent, t.accentSoft, a)!;

            return DashedBorder(
              color: border,
              radius: 16,
              strokeWidth: 1.5,
              child: Container(
                constraints: const BoxConstraints(minHeight: 158),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DashedBorder(
                      color: border,
                      radius: 20,
                      strokeWidth: 1.5,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ringFill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, size: 18, color: fg),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      context.t.dashboard.newProject,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
