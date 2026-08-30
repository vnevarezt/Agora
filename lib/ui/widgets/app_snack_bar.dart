import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import 'motion.dart';

/// Which way an action went. There is no neutral kind on purpose: a snackbar
/// only ever appears after something the person committed to has finished, and
/// "finished" always resolves one way or the other.
enum AppSnackKind { success, failure }

/// The app's only snackbar.
///
/// Every call site used to build a bare `SnackBar(content: Text(…))`, so a
/// backup restored and a backup that failed to decrypt were the same grey
/// rectangle with different words in it — the outcome was legible only by
/// reading, at the one moment the person is least likely to be reading.
///
/// It takes the messenger rather than a context because every caller is on the
/// far side of an await, where its own context may be gone. The surface is
/// painted here rather than through `snackBarTheme`, which is why the theme's
/// entry is gone: the bar sits on [AppTokens.surface] like every other
/// floating surface, not on inverted ink. That is not a preference — the
/// inverted ground swaps between themes, so a status colour that clears 3:1
/// against it in one theme lands at 2.77:1 in the other, and there is no
/// single value for either mark.
/// [messenger] is nullable because a caller that reached here through
/// `ScaffoldMessenger.maybeOf` has no messenger to report to and no way to
/// make one; the work still happened, it just cannot be announced.
void showAppSnack(
  ScaffoldMessengerState? messenger, {
  required String message,
  required AppSnackKind kind,
}) {
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      // Flutter already wraps the bar in Semantics(liveRegion: true), so the
      // message is announced without anything here.
      content: Builder(
        builder: (context) => _Body(message: message, kind: kind),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: kind == AppSnackKind.failure
          ? Motion.messageLong
          : Motion.message,
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.message, required this.kind});

  final String message;
  final AppSnackKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final failed = kind == AppSnackKind.failure;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s14,
        vertical: Space.s12,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(Dimens.rControl),
        border: Border.all(color: t.border),
        boxShadow: Elevation.popover,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shape as well as colour: the two are told apart at a glance by
          // somebody who cannot tell them apart by hue.
          Icon(
            failed ? Icons.error_outline : Icons.check_circle_outline,
            size: AppIcon.control,
            color: failed
                ? Theme.of(context).colorScheme.error
                : t.successStrong,
          ),
          const SizedBox(width: Space.s10),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppText.body,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
