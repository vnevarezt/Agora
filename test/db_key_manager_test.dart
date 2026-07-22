import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/db_key_manager.dart';

import 'helpers/map_key_store.dart';

const testParams = testKdfParams;

DbKeyManager manager(MapKeyStore store) =>
    DbKeyManager(store: store, params: testParams);

void main() {
  test('status: empty store → none', () async {
    expect(await manager(MapKeyStore()).status(), LocalKeyStatus.none);
  });

  test('status: legacy plaintext key → legacyPlaintext', () async {
    final store = MapKeyStore();
    store.data[DbKeyManager.legacyKeyName] = 'ab' * 32;
    expect(await manager(store).status(), LocalKeyStatus.legacyPlaintext);
  });

  test('createAccount → unlock roundtrip preserves the DEK', () async {
    final store = MapKeyStore();
    final m = manager(store);
    final dek = await m.createAccount('correct horse battery staple');
    expect(dek.length, 64);
    expect(await m.status(), LocalKeyStatus.wrapped);
    expect(await m.unlock('correct horse battery staple'), dek);
  });

  test('unlock with wrong password throws WrongPasswordException', () async {
    final store = MapKeyStore();
    final m = manager(store);
    await m.createAccount('right-password');
    expect(() => m.unlock('wrong-password'),
        throwsA(isA<WrongPasswordException>()));
  });

  test('unlock with no blob throws DbKeyException', () async {
    expect(() => manager(MapKeyStore()).unlock('whatever'),
        throwsA(isA<DbKeyException>()));
  });

  test('tampered ciphertext throws WrongPasswordException', () async {
    final store = MapKeyStore();
    final m = manager(store);
    await m.createAccount('pw');
    final blob =
        jsonDecode(store.data[DbKeyManager.wrappedKeyName]!) as Map<String, dynamic>;
    final ct = base64Decode(blob['ct'] as String);
    ct[0] ^= 0xff;
    blob['ct'] = base64Encode(ct);
    store.data[DbKeyManager.wrappedKeyName] = jsonEncode(blob);
    expect(() => m.unlock('pw'), throwsA(isA<WrongPasswordException>()));
  });

  test('corrupted blob throws DbKeyException', () async {
    final store = MapKeyStore();
    final m = manager(store);
    await m.createAccount('pw');
    store.data[DbKeyManager.wrappedKeyName] = 'not-json';
    expect(() => m.unlock('pw'), throwsA(isA<DbKeyException>()));
  });

  test('migrateLegacy preserves the DEK and deletes the v1 entry', () async {
    final store = MapKeyStore();
    final legacyDek = 'cd' * 32;
    store.data[DbKeyManager.legacyKeyName] = legacyDek;
    final m = manager(store);
    final dek = await m.migrateLegacy('new-password');
    expect(dek, legacyDek);
    expect(store.data.containsKey(DbKeyManager.legacyKeyName), isFalse);
    expect(await m.unlock('new-password'), legacyDek);
  });

  test('status with both v1 and v2 present finishes migration (deletes v1)',
      () async {
    final store = MapKeyStore();
    final m = manager(store);
    final dek = await m.createAccount('pw');
    store.data[DbKeyManager.legacyKeyName] = dek; // simulated crash window
    expect(await m.status(), LocalKeyStatus.wrapped);
    expect(store.data.containsKey(DbKeyManager.legacyKeyName), isFalse);
  });

  test('changePassword keeps the DEK, old password stops working', () async {
    final store = MapKeyStore();
    final m = manager(store);
    final dek = await m.createAccount('old-password');
    await m.changePassword('old-password', 'new-password');
    expect(await m.unlock('new-password'), dek);
    expect(() => m.unlock('old-password'),
        throwsA(isA<WrongPasswordException>()));
  });

  test('changePassword with wrong current password throws and keeps the blob',
      () async {
    final store = MapKeyStore();
    final m = manager(store);
    final dek = await m.createAccount('old-password');
    expect(() => m.changePassword('nope', 'new-password'),
        throwsA(isA<WrongPasswordException>()));
    expect(await m.unlock('old-password'), dek);
  });

  test('blob echoes the KDF params it was created with', () async {
    final store = MapKeyStore();
    await manager(store).createAccount('pw');
    final blob =
        jsonDecode(store.data[DbKeyManager.wrappedKeyName]!) as Map<String, dynamic>;
    expect(blob['v'], 2);
    expect(blob['kdf'], 'argon2id');
    expect(blob['m'], testParams.memoryKib);
    expect(blob['t'], testParams.iterations);
    expect(blob['p'], testParams.parallelism);
  });

  test('unlock honours params stored in the blob, not the manager defaults',
      () async {
    final store = MapKeyStore();
    const otherParams = KdfParams(memoryKib: 32, iterations: 2, parallelism: 1);
    final dek = await DbKeyManager(store: store, params: otherParams)
        .createAccount('pw');
    // A manager configured with different (test) params still unlocks it.
    expect(await manager(store).unlock('pw'), dek);
  });

  test('getOrCreateCloudKeyHex is stable across calls', () async {
    final store = MapKeyStore();
    final m = manager(store);
    final first = await m.getOrCreateCloudKeyHex();
    expect(first.length, 64);
    expect(await m.getOrCreateCloudKeyHex(), first);
  });

  test('cloud key does not affect local status', () async {
    final store = MapKeyStore();
    final m = manager(store);
    await m.getOrCreateCloudKeyHex();
    expect(await m.status(), LocalKeyStatus.none);
  });

  test('destroyAll removes every key', () async {
    final store = MapKeyStore();
    final m = manager(store);
    final dek = await m.createAccount('pw');
    await m.getOrCreateCloudKeyHex();
    await m.enableDeviceUnlock(dek);
    store.data[DbKeyManager.legacyKeyName] = 'ef' * 32;
    await m.destroyAll();
    expect(store.data, isEmpty);
    expect(await m.status(), LocalKeyStatus.none);
  });

  test('device unlock: enable stores the DEK, read returns it back', () async {
    final store = MapKeyStore();
    final m = manager(store);
    final dek = await m.createAccount('pw');
    expect(await m.readDeviceUnlockKey(), isNull);
    await m.enableDeviceUnlock(dek);
    expect(await m.readDeviceUnlockKey(), dek);
    // The password path is untouched.
    expect(await m.unlock('pw'), dek);
  });

  test('device unlock: disable deletes the copy, read → null', () async {
    final store = MapKeyStore();
    final m = manager(store);
    final dek = await m.createAccount('pw');
    await m.enableDeviceUnlock(dek);
    await m.disableDeviceUnlock();
    expect(await m.readDeviceUnlockKey(), isNull);
    expect(store.data.containsKey(DbKeyManager.deviceUnlockKeyName), isFalse);
  });

  test('device unlock: a malformed stored value reads as null', () async {
    final store = MapKeyStore();
    store.data[DbKeyManager.deviceUnlockKeyName] = 'not-a-dek';
    expect(await manager(store).readDeviceUnlockKey(), isNull);
  });
}
