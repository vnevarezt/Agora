import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/firestore_transport.dart';

void main() {
  test('encode/decode roundtrips', () {
    final ts = Timestamp(1752601402, 114000000);
    expect(decodeServerTs(encodeServerTs(ts)), ts);
    expect(decodeServerTs(encodeServerTs(Timestamp(0, 0))), Timestamp(0, 0));
  });

  test('lexicographic order matches temporal order', () {
    final stamps = [
      Timestamp(0, 0),
      Timestamp(0, 1),
      Timestamp(0, 999999999),
      Timestamp(1, 0),
      Timestamp(999, 5),
      Timestamp(1752601402, 114000000),
      Timestamp(1752601402, 114000001),
      Timestamp(1752601403, 0),
      Timestamp(99999999999, 0), // year ~5138: the padding never overflows
    ];
    final encoded = [for (final t in stamps) encodeServerTs(t)];
    final sorted = [...encoded]..sort();
    expect(sorted, encoded);
  });
}
