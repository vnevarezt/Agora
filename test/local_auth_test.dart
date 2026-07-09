import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/db_key_manager.dart';
import 'package:jw_program/state/local_auth.dart';

import 'helpers/map_key_store.dart';

ProviderContainer containerWith(MapKeyStore store) {
  final container = ProviderContainer(overrides: [
    dbKeyManagerProvider.overrideWithValue(
        DbKeyManager(store: store, params: testKdfParams)),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// `_init` runs async after build: wait until the state leaves Loading.
Future<LocalAuthState> settled(ProviderContainer container) async {
  for (var i = 0;
      i < 100 && container.read(localAuthProvider) is LocalAuthLoading;
      i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return container.read(localAuthProvider);
}

void main() {
  test('boot with empty keychain routes to FreshSetup', () async {
    final container = containerWith(MapKeyStore());
    expect(container.read(localAuthProvider), isA<LocalAuthLoading>());
    expect(await settled(container), isA<LocalAuthFreshSetup>());
  });

  test('boot with legacy plaintext key routes to Migration', () async {
    final store = MapKeyStore();
    store.data[DbKeyManager.legacyKeyName] = 'ab' * 32;
    final container = containerWith(store);
    expect(await settled(container), isA<LocalAuthMigration>());
  });

  test('boot with wrapped key routes to Locked', () async {
    final store = MapKeyStore();
    await DbKeyManager(store: store, params: testKdfParams)
        .createAccount('pw-123456');
    final container = containerWith(store);
    expect(await settled(container), isA<LocalAuthLocked>());
  });

  test('createAccount unlocks the session with the new DEK', () async {
    final store = MapKeyStore();
    final container = containerWith(store);
    await settled(container);
    await container
        .read(localAuthProvider.notifier)
        .createAccount('pw-123456');
    final state = container.read(localAuthProvider);
    expect(state, isA<LocalAuthUnlocked>());
    expect((state as LocalAuthUnlocked).dekHex.length, 64);
  });

  test('unlock with right password succeeds, wrong password keeps Locked',
      () async {
    final store = MapKeyStore();
    final dek = await DbKeyManager(store: store, params: testKdfParams)
        .createAccount('right-pw');
    final container = containerWith(store);
    await settled(container);
    final auth = container.read(localAuthProvider.notifier);

    await expectLater(
        auth.unlock('wrong-pw'), throwsA(isA<WrongPasswordException>()));
    expect(container.read(localAuthProvider), isA<LocalAuthLocked>());

    await auth.unlock('right-pw');
    final state = container.read(localAuthProvider);
    expect(state, isA<LocalAuthUnlocked>());
    expect((state as LocalAuthUnlocked).dekHex, dek);
  });

  test('migrate wraps the legacy DEK and unlocks', () async {
    final store = MapKeyStore();
    final legacyDek = 'cd' * 32;
    store.data[DbKeyManager.legacyKeyName] = legacyDek;
    final container = containerWith(store);
    await settled(container);
    await container.read(localAuthProvider.notifier).migrate('new-pw-123');
    final state = container.read(localAuthProvider);
    expect((state as LocalAuthUnlocked).dekHex, legacyDek);
    expect(store.data.containsKey(DbKeyManager.legacyKeyName), isFalse);
  });

  test('lock flips back to Locked', () async {
    final store = MapKeyStore();
    final container = containerWith(store);
    await settled(container);
    final auth = container.read(localAuthProvider.notifier);
    await auth.createAccount('pw-123456');
    auth.lock();
    expect(container.read(localAuthProvider), isA<LocalAuthLocked>());
  });
}
