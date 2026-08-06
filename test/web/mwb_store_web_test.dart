@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:agora/data/mwb_store_web.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the hand-written IndexedDB interop. Compiling proves the types
/// line up; only running proves the requests actually resolve, which is where
/// callback-based APIs wrapped in Completers tend to go wrong.
///
/// Run with: flutter test --platform chrome test/web
void main() {
  late IndexedDbMwbStore store;

  setUp(() => store = IndexedDbMwbStore());

  test('missing keys read as null rather than throwing', () async {
    expect(await store.readString('nope-${DateTime.now().microsecondsSinceEpoch}'),
        isNull);
    expect(await store.readBytes('nope-${DateTime.now().microsecondsSinceEpoch}'),
        isNull);
  });

  test('strings round-trip', () async {
    final key = 'manifest-${DateTime.now().microsecondsSinceEpoch}';
    await store.writeString(key, '{"entries":[]}');
    expect(await store.readString(key), '{"entries":[]}');
  });

  test('overwriting replaces rather than appends', () async {
    final key = 'manifest-${DateTime.now().microsecondsSinceEpoch}';
    await store.writeString(key, 'first');
    await store.writeString(key, 'second');
    expect(await store.readString(key), 'second');
  });

  test('bytes round-trip', () async {
    // IndexedDB hands a Uint8Array back as an ArrayBuffer; the store is
    // supposed to absorb that difference.
    final key = 'epub-${DateTime.now().microsecondsSinceEpoch}';
    final bytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0x00, 0xFF]);
    await store.writeBytes(key, bytes);
    expect(await store.readBytes(key), bytes);
  });

  test('a payload larger than the localStorage ceiling survives', () async {
    // The whole reason for IndexedDB over localStorage: notebook EPUBs are
    // megabytes and localStorage caps out around five for the entire origin.
    final key = 'big-${DateTime.now().microsecondsSinceEpoch}';
    final bytes = Uint8List.fromList(
        List<int>.generate(6 * 1024 * 1024, (i) => i % 256));
    await store.writeBytes(key, bytes);
    final read = await store.readBytes(key);
    expect(read, isNotNull);
    expect(read!.length, bytes.length);
    expect(read.first, bytes.first);
    expect(read.last, bytes.last);
  });
}
