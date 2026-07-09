import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/mwb_cache.dart';

void main() {
  late Directory tmp;
  late MwbCache cache;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mwb_cache_test');
    cache = MwbCache(root: tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('putEpub then readEpub returns the bytes and a manifest entry',
      () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    await cache.putEpub('202605', 'S', bytes, 9);

    expect(await cache.readEpub('202605', 'S'), bytes);
    final m = await cache.readManifest();
    expect(cache.has(m, '202605', 'S'), isTrue);
    expect(m.entries.single.issue, '202605');
    expect(m.entries.single.weekCount, 9);
  });

  test('readEpub returns null for a missing issue', () async {
    expect(await cache.readEpub('209901', 'S'), isNull);
  });

  test('recordFailure + inBackoff respect the window; putEpub clears it',
      () async {
    final t0 = DateTime(2026, 6, 14);
    await cache.recordFailure('202607', 'S', '404', at: t0);

    var m = await cache.readManifest();
    expect(cache.inBackoff(m, '202607', 'S', now: t0), isTrue);
    expect(
        cache.inBackoff(m, '202607', 'S',
            now: t0.add(const Duration(days: 2))),
        isFalse);

    await cache.putEpub('202607', 'S', Uint8List.fromList([9]), 1);
    m = await cache.readManifest();
    expect(m.failures, isEmpty);
  });

  test('readManifest tolerates a corrupt file', () async {
    await cache.putEpub('202605', 'S', Uint8List.fromList([1]), 1);
    final file = File(
        '${tmp.path}${Platform.pathSeparator}mwb_cache${Platform.pathSeparator}manifest.json');
    await file.writeAsString('{ not json');

    final m = await cache.readManifest();
    expect(m.entries, isEmpty);
  });
}
