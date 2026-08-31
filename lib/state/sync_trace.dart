import 'package:flutter/foundation.dart';

/// Debug-only tracing of the first-restore path.
///
/// Every failure found here so far was silent by construction — a pull
/// request dropped by a busy flag, an empty page that actually meant "no key
/// for this congregation", a listener that died without a word. Reasoning
/// about the code found three of them and still left one standing, so this
/// exists to watch the thing happen instead.
///
/// Compiled out of release builds. Delete once the restore is trusted.
void syncTrace(String message) {
  if (kDebugMode) debugPrint('[sync] $message');
}
