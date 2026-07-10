import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/db_key_manager.dart';
import 'package:jw_program/state/auth_session.dart';
import 'package:jw_program/state/cloud_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/map_key_store.dart';

ProviderContainer containerWith(MapKeyStore store) {
  final container = ProviderContainer(overrides: [
    dbKeyManagerProvider.overrideWithValue(
        DbKeyManager(store: store, params: testKdfParams)),
    // No Firebase in unit tests: cloud mode degrades to signed-out.
    firebaseAppProvider.overrideWith((ref) => Future.value(null)),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// `_init` runs async after build: wait until the state leaves Loading.
Future<SessionState> settled(ProviderContainer container) async {
  for (var i = 0;
      i < 100 && container.read(authSessionProvider) is SessionLoading;
      i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return container.read(authSessionProvider);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fresh install (no mode, no keys) routes to FreshChoose', () async {
    final container = containerWith(MapKeyStore());
    expect(container.read(authSessionProvider), isA<SessionLoading>());
    expect(await settled(container), isA<SessionFreshChoose>());
  });

  test('legacy plaintext key without mode forces migration', () async {
    final store = MapKeyStore();
    store.data[DbKeyManager.legacyKeyName] = 'ab' * 32;
    final state = await settled(containerWith(store));
    expect(state, isA<SessionLocalCreate>());
    expect((state as SessionLocalCreate).migration, isTrue);
  });

  test('wrapped key without mode is treated as local (pre-mode install)',
      () async {
    final store = MapKeyStore();
    await DbKeyManager(store: store, params: testKdfParams)
        .createAccount('pw-123456');
    expect(await settled(containerWith(store)), isA<SessionLocalLocked>());
  });

  test('local mode boots locked with the stored profile name', () async {
    SharedPreferences.setMockInitialValues(
        {'account_mode': 'local', 'local_profile_name': 'Andrés Beltrán'});
    final store = MapKeyStore();
    await DbKeyManager(store: store, params: testKdfParams)
        .createAccount('pw-123456');
    final state = await settled(containerWith(store));
    expect(state, isA<SessionLocalLocked>());
    expect((state as SessionLocalLocked).profileName, 'Andrés Beltrán');
  });

  test('cloud mode without Firebase routes to CloudSignedOut', () async {
    SharedPreferences.setMockInitialValues({'account_mode': 'cloud'});
    expect(await settled(containerWith(MapKeyStore())),
        isA<SessionCloudSignedOut>());
  });

  test('createLocalProfile unlocks and persists mode + name', () async {
    final container = containerWith(MapKeyStore());
    await settled(container);
    await container
        .read(authSessionProvider.notifier)
        .createLocalProfile('Ana', 'pw-123456');
    final state = container.read(authSessionProvider);
    expect(state, isA<SessionUnlocked>());
    expect((state as SessionUnlocked).mode, AccountMode.local);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('account_mode'), 'local');
    expect(prefs.getString('local_profile_name'), 'Ana');
  });

  test('migrate wraps the legacy DEK, unlocks and persists local mode',
      () async {
    final store = MapKeyStore();
    final legacyDek = 'cd' * 32;
    store.data[DbKeyManager.legacyKeyName] = legacyDek;
    final container = containerWith(store);
    await settled(container);
    await container
        .read(authSessionProvider.notifier)
        .migrate('Ana', 'new-pw-123');
    final state = container.read(authSessionProvider);
    expect((state as SessionUnlocked).dekHex, legacyDek);
    expect(store.data.containsKey(DbKeyManager.legacyKeyName), isFalse);
  });

  test('unlock: wrong password keeps Locked, right password unlocks',
      () async {
    SharedPreferences.setMockInitialValues({'account_mode': 'local'});
    final store = MapKeyStore();
    final dek = await DbKeyManager(store: store, params: testKdfParams)
        .createAccount('right-pw');
    final container = containerWith(store);
    await settled(container);
    final session = container.read(authSessionProvider.notifier);

    await expectLater(
        session.unlock('wrong-pw'), throwsA(isA<WrongPasswordException>()));
    expect(container.read(authSessionProvider), isA<SessionLocalLocked>());

    await session.unlock('right-pw');
    expect((container.read(authSessionProvider) as SessionUnlocked).dekHex,
        dek);
  });

  test('lock flips back to Locked keeping the profile name', () async {
    final container = containerWith(MapKeyStore());
    await settled(container);
    final session = container.read(authSessionProvider.notifier);
    await session.createLocalProfile('Ana', 'pw-123456');
    session.lock();
    final state = container.read(authSessionProvider);
    expect((state as SessionLocalLocked).profileName, 'Ana');
  });

  test('resetAllData wipes keys, prefs and returns to FreshChoose', () async {
    final store = MapKeyStore();
    final container = containerWith(store);
    await settled(container);
    final session = container.read(authSessionProvider.notifier);
    await session.createLocalProfile('Ana', 'pw-123456');
    await session.resetAllData();
    expect(container.read(authSessionProvider), isA<SessionFreshChoose>());
    expect(store.data, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('account_mode'), isNull);
    expect(prefs.getString('local_profile_name'), isNull);
  });
}
