import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/content_crypto.dart';

void main() {
  final crypto = ContentCrypto();
  final keyring = CongregationKeyring({1: CongregationKeyring.newKey()});

  Future<String> seal(Map<String, dynamic> payload,
          {String cid = 'c1', String eid = 'e1'}) =>
      crypto.encrypt(
          keyring: keyring,
          congregationId: cid,
          entityId: eid,
          payload: payload);

  test('roundtrip', () async {
    final blob = await seal({'name': 'Ana', 'active': true});
    final back = await crypto.decrypt(
        keyring: keyring,
        keyVersion: 1,
        congregationId: 'c1',
        entityId: 'e1',
        blob: blob);
    expect(back, {'name': 'Ana', 'active': true});
  });

  test('AAD binds the blob to its congregation/entity path', () async {
    final blob = await seal({'x': 1});
    await expectLater(
      crypto.decrypt(
          keyring: keyring,
          keyVersion: 1,
          congregationId: 'c1',
          entityId: 'OTHER',
          blob: blob),
      throwsA(isA<ContentDecryptException>()),
    );
  });

  test('tampered blob and unknown key version are rejected', () async {
    final blob = await seal({'x': 1});
    final tampered =
        blob.replaceRange(10, 11, blob[10] == 'A' ? 'B' : 'A');
    await expectLater(
      crypto.decrypt(
          keyring: keyring,
          keyVersion: 1,
          congregationId: 'c1',
          entityId: 'e1',
          blob: tampered),
      throwsA(isA<ContentDecryptException>()),
    );
    await expectLater(
      crypto.decrypt(
          keyring: keyring,
          keyVersion: 9,
          congregationId: 'c1',
          entityId: 'e1',
          blob: blob),
      throwsA(isA<ContentDecryptException>()),
    );
  });

  test('keyring rotation: new writes use the highest version, old blobs open',
      () async {
    final rotated = CongregationKeyring({
      ...keyring.keys,
      2: CongregationKeyring.newKey(),
    });
    expect(rotated.currentVersion, 2);

    final oldBlob = await seal({'x': 1}); // sealed under v1
    final back = await crypto.decrypt(
        keyring: rotated,
        keyVersion: 1,
        congregationId: 'c1',
        entityId: 'e1',
        blob: oldBlob);
    expect(back, {'x': 1});
  });
}
