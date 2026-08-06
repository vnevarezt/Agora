import 'dart:async';
import 'dart:isolate';

/// Runs [body] on a fresh isolate, keeping the UI one free.
Future<T> runInBackground<T>(FutureOr<T> Function() body) => Isolate.run(body);
