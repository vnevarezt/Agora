@TestOn('browser')
library;

import 'package:agora/data/background.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web has no isolates: `Isolate.run` throws `Unsupported operation: new
/// RawReceivePort` there. Four call sites relied on it — building a PDF,
/// deriving an Argon2id key twice, and parsing an EPUB — so the failure showed
/// up as a broken PDF preview and would have taken backups and the notebook
/// sync with it.
///
/// Run with: flutter test --platform chrome test/web
void main() {
  test('runs a synchronous body and returns its value', () async {
    expect(await runInBackground(() => 6 * 7), 42);
  });

  test('runs an asynchronous body', () async {
    expect(
      await runInBackground(() async {
        await Future<void>.delayed(Duration.zero);
        return 'done';
      }),
      'done',
    );
  });

  test('propagates errors instead of swallowing them', () async {
    await expectLater(
      runInBackground(() => throw StateError('boom')),
      throwsA(isA<StateError>()),
    );
  });

  test('carries closed-over state, which is what Isolate.run could not',
      () async {
    // Isolate.run has to copy captured values across; inline execution shares
    // them. Either way the caller sees the same result.
    final captured = [1, 2, 3];
    expect(await runInBackground(() => captured.length), 3);
  });
}
