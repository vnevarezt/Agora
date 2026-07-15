import 'package:flutter/material.dart';

import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';

const _scrim = Color(0x52000000);

/// Presents an app modal: centered dialog on desktop/tablet and a bottom
/// sheet on mobile. [builder] receives whether it shows as a sheet (`sheet`)
/// and a close callback. Used by the project and participant modals.
Future<T?> showAppModal<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, bool sheet, VoidCallback close)
      builder,
  double maxWidth = 520,
}) {
  if (context.isMobile) {
    final t = context.tokens;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      barrierColor: _scrim,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Dimens.rSheet)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
          child: builder(ctx, true, () => Navigator.of(ctx).pop()),
        ),
      ),
    );
  }
  // Material 3 dialog motion: the scrim fades while the surface fades in and
  // scales up from 92% (emphasized-decelerate feel), instead of the default
  // opacity-only pop. showGeneralDialog gives us the transitionBuilder that
  // showDialog hides.
  return showGeneralDialog<T>(
    context: context,
    barrierColor: _scrim,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, _, _) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
        ),
        child: builder(ctx, false, () => Navigator.of(ctx).pop()),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
