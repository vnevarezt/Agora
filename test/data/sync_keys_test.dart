import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/cck_service.dart';
import 'package:jw_program/data/sync/link_service.dart';
import 'package:jw_program/data/sync/sealed_box.dart';
import 'package:jw_program/data/sync/user_key_service.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/map_key_store.dart';

UserKeyService userKeys(MapKeyStore store, FakeKeyDocs docs,
        [String uid = 'u1']) =>
    UserKeyService(store, docs, uid: uid);

LinkService linkService(UserKeyService keys, FakeKeyDocs docs,
        [String uid = 'u1']) =>
    LinkService(docs, keys, uid: uid);

void main() {
  test('a fresh account mints its identity with no user interaction',
      () async {
    final store = MapKeyStore();
    final docs = FakeKeyDocs();
    final keys = userKeys(store, docs);
    expect(await keys.status(), UserKeyStatus.notSetUp);

    await keys.generate();
    expect(await keys.status(), UserKeyStatus.ready);
    // The cloud gets the PUBLIC half only — no wrapped private key at all.
    expect(docs.users['u1']!['pubKey'], isNotNull);
    expect(docs.users['u1']!.containsKey('wrappedPrivKey'), isFalse);
    expect(docs.users['u1']!['pubKey'],
        base64Encode(await SealedBox.publicKeyOf((await keys.seed())!)));
    // Never silently replace an identity: that would strand other devices.
    expect(keys.generate(), throwsStateError);
  });

  test('a second device has no seed and must be linked', () async {
    final docs = FakeKeyDocs();
    await userKeys(MapKeyStore(), docs).generate();

    final deviceB = userKeys(MapKeyStore(), docs);
    expect(await deviceB.status(), UserKeyStatus.needsLink);
    expect(await deviceB.seed(), isNull);
  });

  test('linking moves the identity from one device to another', () async {
    final docs = FakeKeyDocs();
    final storeA = MapKeyStore();
    final deviceA = userKeys(storeA, docs);
    await deviceA.generate();
    final identity = await deviceA.seed();

    final storeB = MapKeyStore();
    final deviceB = userKeys(storeB, docs);
    final linkB = linkService(deviceB, docs);
    final session = await linkB.start();

    // The existing device only ever sees the payload string.
    await linkService(deviceA, docs).approve(session.code);
    expect(await linkB.awaitCompletion(session), isTrue);

    expect(await deviceB.seed(), identity);
    expect(await deviceB.status(), UserKeyStatus.ready);
    // The mailbox is cleaned up after use.
    expect(docs.links['u1']?[session.payload.sessionId], isNull);
  });

  test('a forged seed is refused even though the box opens', () async {
    final docs = FakeKeyDocs();
    await userKeys(MapKeyStore(), docs).generate();

    // An attacker who holds the payload answers with a key of their own.
    final impostorStore = MapKeyStore();
    final impostorDocs = FakeKeyDocs();
    final impostor = userKeys(impostorStore, impostorDocs);
    await impostor.generate();

    final deviceB = userKeys(MapKeyStore(), docs);
    final linkB = linkService(deviceB, docs);
    final session = await linkB.start();
    await linkService(impostor, docs).approve(session.code);

    await expectLater(
        linkB.awaitCompletion(session), throwsA(isA<LinkIdentityMismatch>()));
    // Nothing was adopted: the device still needs a real link.
    expect(await deviceB.seed(), isNull);
  });

  test('approving needs a seed on this device', () async {
    final docs = FakeKeyDocs();
    await userKeys(MapKeyStore(), docs).generate();
    final deviceB = userKeys(MapKeyStore(), docs);
    final session = await linkService(deviceB, docs).start();

    // A device that was never linked cannot hand out an identity.
    expect(linkService(deviceB, docs).approve(session.code), throwsStateError);
  });

  test('sign-out forgets the seed; the account keeps its identity', () async {
    final docs = FakeKeyDocs();
    final keys = userKeys(MapKeyStore(), docs);
    await keys.generate();

    await keys.forget();
    expect(await keys.seed(), isNull);
    expect(await keys.status(), UserKeyStatus.needsLink);
    expect(docs.users['u1'], isNotNull);
  });

  test('the legacy passphrase envelope is dropped once', () async {
    final docs = FakeKeyDocs();
    final keys = userKeys(MapKeyStore(), docs);
    await keys.generate();
    docs.users['u1']!['wrappedPrivKey'] = 'legacy-blob';

    await keys.dropLegacyEnvelope();
    expect(docs.users['u1']!.containsKey('wrappedPrivKey'), isFalse);
  });

  test('CCK: founder bootstrap then recovery on a linked device', () async {
    final docs = FakeKeyDocs();
    final storeA = MapKeyStore();
    final userA = userKeys(storeA, docs);
    await userA.generate();
    final ccksA = CckService(storeA, docs, userA, uid: 'u1');

    expect(await ccksA.keyringFor('c1'), isNull); // not enabled yet

    final created = await ccksA.createCongregationSpace('c1', email: 'a@b.c');
    expect(created.currentVersion, 1);
    final memberDoc = docs.members['c1']!['u1']!;
    expect((memberDoc['capabilities'] as Map)['admin'], true);
    // Only the SEALED key is stored, never the raw one.
    expect(jsonEncode(memberDoc).contains(base64Encode(created.currentKey)),
        isFalse);
    expect((await ccksA.createCongregationSpace('c1')).currentKey,
        created.currentKey); // idempotent

    // A linked device recovers the same CCK from its member doc.
    final storeB = MapKeyStore();
    final userB = userKeys(storeB, docs);
    await userB.adopt((await userA.seed())!);
    final ccksB = CckService(storeB, docs, userB, uid: 'u1');
    expect((await ccksB.keyringFor('c1'))!.currentKey, created.currentKey);

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

    await user.generate();
    await ccks.createCongregationSpace('c1');
    expect(await ccks.isStale('c1'), isFalse);

    docs.congregations['c1']!['keyVersion'] = 2; // rotated elsewhere
    expect(await ccks.isStale('c1'), isTrue);
  });

  test('CCK cache is per uid: another account sees nothing', () async {
    final docs = FakeKeyDocs();
    final store = MapKeyStore();
    final user = userKeys(store, docs);
    await user.generate();
    final ccks = CckService(store, docs, user, uid: 'u1');
    await ccks.createCongregationSpace('c1');

    final other =
        CckService(store, docs, userKeys(store, docs, 'u2'), uid: 'u2');
    expect(await other.keyringFor('c1'), isNull);
  });
}
