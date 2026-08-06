import 'dart:async';

/// Runs [body] inline: the web has no isolates to move it to.
///
/// Awaiting the result keeps the signature honest — callers already treat this
/// as asynchronous — but the work itself occupies the UI thread, so anything
/// slow enough to matter will be felt as a freeze rather than a stutter.
Future<T> runInBackground<T>(FutureOr<T> Function() body) async => await body();
