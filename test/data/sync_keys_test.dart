import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/crypto/passphrase_envelope.dart';
import 'package:jw_program/data/sync/cck_service.dart';
import 'package:jw_program/data/sync/sealed_box.dart';
import 'package:jw_program/data/sync/user_key_service.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/map_key_store.dart';

// Cheap KDF: these tests exercise flows, not Argon2id cost.
const _fast = KdfParams(memoryKib: 64, iterations: 1, parallelism: 1);

UserKeyService userKeys(MapKeyStore store, FakeKeyDocs docs,
        [String uid = 'u1']) =>
    UserKeyService(store, docs,
        uid: uid, envelope: const PassphraseEnvelope(params: _fast));

void main() {
  test('create publishes the doc, caches the seed and reports ready',
      () async {
    final store = MapKeyStore();
    final docs = FakeKeyDocs();
    final keys = userKeys(store, docs);
    expect(await keys.status(), UserKeyStatus.notSetUp);

    await keys.create('frase segura');
    expect(await keys.status(), UserKeyStatus.ready);
    expect(docs.users['u1']!['pubKey'], isNotNull);
    // The doc never carries the clear seed.
    expect(docs.users['u1']!.values.contains(base64Encode((await keys.seed())!)),
        isFalse);
    // Published pubkey matches the cached seed.
    expect(docs.users['u1']!['pubKey'],
        base64Encode(await SealedBox.publicKeyOf((await keys.seed())!)));
    // No double-create.
    expect(() => keys.create('otra'), throwsStateError);
  });

  test('new device: locked until unlock with the right passphrase', () async {
    final docs = FakeKeyDocs();
    final deviceA = userKeys(MapKeyStore(), docs);
    await deviceA.create('frase segura');
    final seedA = await deviceA.seed();

    final deviceB = userKeys(MapKeyStore(), docs);
    expect(await deviceB.status(), UserKeyStatus.locked);
    await expectLater(deviceB.unlock('incorrecta'),
        throwsA(isA<WrongPassphraseException>()));
    expect(await deviceB.status(), UserKeyStatus.locked);

    await deviceB.unlock('frase segura');
    expect(await deviceB.status(), UserKeyStatus.ready);
    expect(await deviceB.seed(), seedA);
  });

  test('changePassphrase keeps the seed; old passphrase stops working',
      () async {
    final docs = FakeKeyDocs();
    final a = userKeys(MapKeyStore(), docs);
    await a.create('vieja');
    final seed = await a.seed();

    await a.changePassphrase('vieja', 'nueva');
    final b = userKeys(MapKeyStore(), docs);
    await expectLater(
        b.unlock('vieja'), throwsA(isA<WrongPassphraseException>()));
    await b.unlock('nueva');
    expect(await b.seed(), seed);
  });

  test('forget drops the cached seed but the cloud doc stays', () async {
    final docs = FakeKeyDocs();
    final keys = userKeys(MapKeyStore(), docs);
    await keys.create('frase');
    await keys.forget();
    expect(await keys.status(), UserKeyStatus.locked);
  });

  test('CCK: founder bootstrap then recovery on a second device', () async {
    final docs = FakeKeyDocs();
    final storeA = MapKeyStore();
    final userA = userKeys(storeA, docs);
    await userA.create('frase');
    final ccksA = CckService(storeA, docs, userA, uid: 'u1');

    // Not enabled: no keyring, outbox would stay queued.
    expect(await ccksA.keyringFor('c1'), isNull);

    final created = await ccksA.createCongregationSpace('c1', email: 'a@b.c');
    expect(created.currentVersion, 1);
    expect(docs.congregations['c1']!['keyVersion'], 1);
    final memberDoc = docs.members['c1']!['u1']!;
    expect((memberDoc['capabilities'] as Map)['admin'], true);
    // The member doc holds only the SEALED key, never the raw one.
    expect(jsonEncode(memberDoc).contains(base64Encode(created.currentKey)),
        isFalse);

    // Idempotent: enabling twice returns the same keyring.
    expect((await ccksA.createCongregationSpace('c1')).currentKey,
        created.currentKey);

    // Same account, new device: unlock + refresh recovers the same CCK.
    final storeB = MapKeyStore();
    final userB = userKeys(storeB, docs);
    await userB.unlock('frase');
    final ccksB = CckService(storeB, docs, userB, uid: 'u1');
    final recovered = await ccksB.keyringFor('c1');
    expect(recovered!.currentKey, created.currentKey);

    // Now cached: works even if the member doc disappears.
    docs.members.clear();
    expect((await ccksB.keyringFor('c1'))!.currentKey, created.currentKey);
  });

  test('CCK: no seed on device → null keyring; staleness detects rotation',
      () async {
    final docs = FakeKeyDocs();
    final store = MapKeyStore();
    final user = userKeys(store, docs);
    final ccks = CckService(store, docs, user, uid: 'u1');
    expect(await ccks.keyringFor('c1'), isNull);

    await user.create('frase');
    await ccks.createCongregationSpace('c1');
    expect(await ccks.isStale('c1'), isFalse);

    // Someone rotated elsewhere: server version is ahead of the cache.
    docs.congregations['c1']!['keyVersion'] = 2;
    expect(await ccks.isStale('c1'), isTrue);
  });

  test('CCK cache is per uid: another account sees nothing', () async {
    final docs = FakeKeyDocs();
    final store = MapKeyStore();
    final user = userKeys(store, docs);
    await user.create('frase');
    final ccks = CckService(store, docs, user, uid: 'u1');
    await ccks.createCongregationSpace('c1');

    final other = CckService(
        store, docs, userKeys(store, docs, 'u2'), uid: 'u2');
    expect(await other.keyringFor('c1'), isNull);
  });
}
