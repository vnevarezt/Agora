import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/db_key_manager.dart';
import 'package:jw_program/data/device_auth.dart';
import 'package:jw_program/state/auth_session.dart';
import 'package:jw_program/state/cloud_auth.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/map_key_store.dart';

/// resetAllData deletes the DB file via path_provider, whose platform channel
/// doesn't exist in unit tests: point it at a temp directory instead.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

/// Scriptable stand-in for the OS identity prompt.
class FakeDeviceAuth implements DeviceAuth {
  FakeDeviceAuth({this.supported = true, this.result = true});

  bool supported;
  bool result;
  int prompts = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return result;
  }
}

ProviderContainer containerWith(MapKeyStore store, {DeviceAuth? deviceAuth}) {
  final container = ProviderContainer(overrides: [
    dbKeyManagerProvider.overrideWithValue(
        DbKeyManager(store: store, params: testKdfParams)),
    // No Firebase in unit tests: cloud mode degrades to signed-out.
    firebaseAppProvider.overrideWith((ref) => Future.value(null)),
    if (deviceAuth != null) deviceAuthProvider.overrideWithValue(deviceAuth),
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PathProviderPlatform.instance = _FakePathProvider(
        Directory.systemTemp.createTempSync('agora_test').path);
  });

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

  test('device unlock pref + support boots Locked with the flag on', () async {
    SharedPreferences.setMockInitialValues(
        {'account_mode': 'local', 'device_unlock': true});
    final store = MapKeyStore();
    final dek = await DbKeyManager(store: store, params: testKdfParams)
        .createAccount('pw-123456');
    await DbKeyManager(store: store, params: testKdfParams)
        .enableDeviceUnlock(dek);
    final state =
        await settled(containerWith(store, deviceAuth: FakeDeviceAuth()));
    expect((state as SessionLocalLocked).deviceUnlock, isTrue);
  });

  test('device unlock pref without hardware support stays password-only',
      () async {
    SharedPreferences.setMockInitialValues(
        {'account_mode': 'local', 'device_unlock': true});
    final store = MapKeyStore();
    await DbKeyManager(store: store, params: testKdfParams)
        .createAccount('pw-123456');
    final state = await settled(
        containerWith(store, deviceAuth: FakeDeviceAuth(supported: false)));
    expect((state as SessionLocalLocked).deviceUnlock, isFalse);
  });

  test('unlockWithDeviceAuth releases the DEK after passing the prompt',
      () async {
    SharedPreferences.setMockInitialValues(
        {'account_mode': 'local', 'device_unlock': true});
    final store = MapKeyStore();
    final keys = DbKeyManager(store: store, params: testKdfParams);
    final dek = await keys.createAccount('pw-123456');
    await keys.enableDeviceUnlock(dek);
    final fake = FakeDeviceAuth();
    final container = containerWith(store, deviceAuth: fake);
    await settled(container);

    expect(
        await container
            .read(authSessionProvider.notifier)
            .unlockWithDeviceAuth('reason'),
        isTrue);
    final state = container.read(authSessionProvider);
    expect((state as SessionUnlocked).dekHex, dek);
    expect(state.deviceUnlockEnabled, isTrue);
    expect(fake.prompts, 1);
  });

  test('unlockWithDeviceAuth: cancelled prompt keeps the session locked',
      () async {
    SharedPreferences.setMockInitialValues(
        {'account_mode': 'local', 'device_unlock': true});
    final store = MapKeyStore();
    final keys = DbKeyManager(store: store, params: testKdfParams);
    await keys.enableDeviceUnlock(await keys.createAccount('pw-123456'));
    final container =
        containerWith(store, deviceAuth: FakeDeviceAuth(result: false));
    await settled(container);

    expect(
        await container
            .read(authSessionProvider.notifier)
            .unlockWithDeviceAuth('reason'),
        isFalse);
    expect(container.read(authSessionProvider), isA<SessionLocalLocked>());
  });

  test('unlockWithDeviceAuth: missing key copy turns the pref off and throws',
      () async {
    SharedPreferences.setMockInitialValues(
        {'account_mode': 'local', 'device_unlock': true});
    final store = MapKeyStore();
    await DbKeyManager(store: store, params: testKdfParams)
        .createAccount('pw-123456');
    // No enableDeviceUnlock: the copy is gone (e.g. keychain lost it).
    final container = containerWith(store, deviceAuth: FakeDeviceAuth());
    await settled(container);

    await expectLater(
        container
            .read(authSessionProvider.notifier)
            .unlockWithDeviceAuth('reason'),
        throwsA(isA<DeviceUnlockKeyMissing>()));
    final state = container.read(authSessionProvider);
    expect((state as SessionLocalLocked).deviceUnlock, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('device_unlock'), isFalse);
  });

  test('setDeviceUnlock writes the key copy and survives lock()', () async {
    final store = MapKeyStore();
    final fake = FakeDeviceAuth();
    final container = containerWith(store, deviceAuth: fake);
    await settled(container);
    final session = container.read(authSessionProvider.notifier);
    await session.createLocalProfile('Ana', 'pw-123456');

    expect(await session.setDeviceUnlock(true, 'reason'), isTrue);
    expect(fake.prompts, 1);
    final unlocked = container.read(authSessionProvider) as SessionUnlocked;
    expect(unlocked.deviceUnlockEnabled, isTrue);
    expect(store.data[DbKeyManager.deviceUnlockKeyName], unlocked.dekHex);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('device_unlock'), isTrue);

    session.lock();
    final locked = container.read(authSessionProvider);
    expect((locked as SessionLocalLocked).deviceUnlock, isTrue);
    await session.unlockWithDeviceAuth('reason');
    expect(container.read(authSessionProvider), isA<SessionUnlocked>());
  });

  test('setDeviceUnlock(true) is a no-op when the prompt is cancelled',
      () async {
    final store = MapKeyStore();
    final container =
        containerWith(store, deviceAuth: FakeDeviceAuth(result: false));
    await settled(container);
    final session = container.read(authSessionProvider.notifier);
    await session.createLocalProfile('Ana', 'pw-123456');

    expect(await session.setDeviceUnlock(true, 'reason'), isFalse);
    expect(store.data.containsKey(DbKeyManager.deviceUnlockKeyName), isFalse);
    final state = container.read(authSessionProvider);
    expect((state as SessionUnlocked).deviceUnlockEnabled, isFalse);
  });

  test('setDeviceUnlock(false) removes the key copy and the pref', () async {
    final store = MapKeyStore();
    final container = containerWith(store, deviceAuth: FakeDeviceAuth());
    await settled(container);
    final session = container.read(authSessionProvider.notifier);
    await session.createLocalProfile('Ana', 'pw-123456');
    await session.setDeviceUnlock(true, 'reason');

    expect(await session.setDeviceUnlock(false, 'reason'), isFalse);
    expect(store.data.containsKey(DbKeyManager.deviceUnlockKeyName), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('device_unlock'), isFalse);
    expect(
        (container.read(authSessionProvider) as SessionUnlocked)
            .deviceUnlockEnabled,
        isFalse);
  });

  test('resetAllData clears the device-unlock pref', () async {
    final store = MapKeyStore();
    final container = containerWith(store, deviceAuth: FakeDeviceAuth());
    await settled(container);
    final session = container.read(authSessionProvider.notifier);
    await session.createLocalProfile('Ana', 'pw-123456');
    await session.setDeviceUnlock(true, 'reason');
    await session.resetAllData();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('device_unlock'), isNull);
    expect(store.data, isEmpty);
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
