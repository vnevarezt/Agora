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
  return showDialog<T>(
    context: context,
    barrierColor: _scrim,
    builder: (ctx) => Dialog(
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
  );
}
