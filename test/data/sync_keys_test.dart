import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/cck_service.dart';
import 'package:jw_program/data/sync/sealed_box.dart';
import 'package:jw_program/data/sync/user_key_service.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/map_key_store.dart';

UserKeyService userKeys(MapKeyStore store, FakeKeyDocs docs,
        [String uid = 'u1']) =>
    UserKeyService(store, docs, uid: uid);

void main() {
  test('a fresh account mints its identity with no user interaction',
      () async {
    final store = MapKeyStore();
    final docs = FakeKeyDocs();
    final keys = userKeys(store, docs);
    expect(await keys.status(), UserKeyStatus.notSetUp);

    expect(await keys.ensureAvailable(), isTrue);
    expect(await keys.status(), UserKeyStatus.ready);
    // The published public key matches the seed the device holds.
    expect(docs.users['u1']!['pubKey'],
        base64Encode(await SealedBox.publicKeyOf((await keys.seed())!)));
    // Never silently replace an identity: that would orphan every CCK.
    expect(keys.generate(), throwsStateError);
  });

  test('a second device restores the identity from the account alone',
      () async {
    final docs = FakeKeyDocs();
    final deviceA = userKeys(MapKeyStore(), docs);
    await deviceA.ensureAvailable();
    final identity = await deviceA.seed();

    // No code, no passphrase, no other device involved.
    final deviceB = userKeys(MapKeyStore(), docs);
    expect(await deviceB.status(), UserKeyStatus.ready);
    expect(await deviceB.seed(), identity);
  });

  test('the fetched key is cached, so later reads work offline', () async {
    final docs = FakeKeyDocs();
    await userKeys(MapKeyStore(), docs).ensureAvailable();

    final store = MapKeyStore();
    final device = userKeys(store, docs);
    final identity = await device.seed();
    expect(store.data['jw_program.sync.userkey.u1'], isNotNull);

    // The cloud becomes unreachable: the cached copy still serves.
    docs.users.clear();
    expect(await device.seed(), identity);
  });

  test('an account whose key cannot be reached reports unavailable', () async {
    final docs = FakeKeyDocs();
    // A pre-escrow doc: exists, but holds no usable private key.
    docs.users['u1'] = {'pubKey': 'whatever'};
    final device = userKeys(MapKeyStore(), docs);

    expect(await device.status(), UserKeyStatus.unavailable);
    expect(await device.ensureAvailable(), isFalse);
    // It must NOT mint a second identity over the existing one.
    expect(docs.users['u1']!.containsKey('privKey'), isFalse);
  });

  test('sign-out clears this device but the account keeps the identity',
      () async {
    final docs = FakeKeyDocs();
    final store = MapKeyStore();
    final keys = userKeys(store, docs);
    await keys.ensureAvailable();

    await keys.forget();
    expect(store.data['jw_program.sync.userkey.u1'], isNull);
    // Signing back in restores it — that is the whole point of escrowing.
    expect(await keys.status(), UserKeyStatus.ready);
  });

  test('the legacy passphrase envelope is dropped once', () async {
    final docs = FakeKeyDocs();
    final keys = userKeys(MapKeyStore(), docs);
    await keys.ensureAvailable();
    docs.users['u1']!['wrappedPrivKey'] = 'legacy-blob';

    await keys.dropLegacyEnvelope();
    expect(docs.users['u1']!.containsKey('wrappedPrivKey'), isFalse);
  });

  test('CCK: founder bootstrap, then any other device of the same account',
      () async {
    final docs = FakeKeyDocs();
    final storeA = MapKeyStore();
    final userA = userKeys(storeA, docs);
    await userA.ensureAvailable();
    final ccksA = CckService(storeA, docs, userA, uid: 'u1');

    expect(await ccksA.keyringFor('c1'), isNull); // not enabled yet

    final created = await ccksA.createCongregationSpace('c1', email: 'a@b.c');
    expect(created.currentVersion, 1);
    final memberDoc = docs.members['c1']!['u1']!;
    expect((memberDoc['capabilities'] as Map)['admin'], true);
    // The member doc stores only the SEALED key, never the raw one.
    expect(jsonEncode(memberDoc).contains(base64Encode(created.currentKey)),
        isFalse);
    expect((await ccksA.createCongregationSpace('c1')).currentKey,
        created.currentKey); // idempotent

    // A brand-new device recovers the same CCK with nothing but the account.
    final storeB = MapKeyStore();
    final userB = userKeys(storeB, docs);
    final ccksB = CckService(storeB, docs, userB, uid: 'u1');
    expect((await ccksB.keyringFor('c1'))!.currentKey, created.currentKey);
  });

  test('CCK: no identity → null keyring; staleness detects rotation',
      () async {
    final docs = FakeKeyDocs();
    final store = MapKeyStore();
    final user = userKeys(store, docs);
    final ccks = CckService(store, docs, user, uid: 'u1');
    expect(await ccks.keyringFor('c1'), isNull);

    await user.ensureAvailable();
    await ccks.createCongregationSpace('c1');
    expect(await ccks.isStale('c1'), isFalse);

    docs.congregations['c1']!['keyVersion'] = 2; // rotated elsewhere
    expect(await ccks.isStale('c1'), isTrue);
  });

  test('CCK cache is per uid: another account sees nothing', () async {
    final docs = FakeKeyDocs();
    final store = MapKeyStore();
    final user = userKeys(store, docs);
    await user.ensureAvailable();
    final ccks = CckService(store, docs, user, uid: 'u1');
    await ccks.createCongregationSpace('c1');

    final other =
        CckService(store, docs, userKeys(store, docs, 'u2'), uid: 'u2');
    expect(await other.keyringFor('c1'), isNull);
  });
}
