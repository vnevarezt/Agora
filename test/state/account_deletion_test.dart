import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora/data/db/db_key_manager.dart';
import 'package:agora/data/sync/cck_service.dart';
import 'package:agora/data/sync/user_key_service.dart';
import 'package:agora/models/member_capabilities.dart';
import 'package:agora/models/membership.dart';
import 'package:agora/state/auth_session.dart';
import 'package:agora/state/cloud_auth.dart';
import 'package:agora/state/sync_controller.dart';
import 'package:agora/state/sync_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/in_memory_transport.dart';
import '../helpers/map_key_store.dart';

/// resetAllData deletes the DB file via path_provider, whose platform channel
/// doesn't exist in unit tests: point it at a temp directory instead.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

/// Records pause/resume into the shared trace instead of driving real timers.
class _RecordingSync extends SyncController {
  _RecordingSync(this.trace);

  final List<String> trace;

  @override
  SyncStatus build() => const SyncStatus(phase: SyncPhase.disabled);

  @override
  void pause() => trace.add('pause');

  @override
  void resume({Iterable<String> keepLocal = const []}) =>
      trace.add('resume(${keepLocal.join(',')})');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeKeyDocs docs;
  late InMemoryTransport transport;
  late MapKeyStore store;
  late StreamController<List<Membership>> memberships;
  late List<String> trace;
  late Future<void> Function() deleteCloudUser;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PathProviderPlatform.instance = _FakePathProvider(
        Directory.systemTemp.createTempSync('agora_test').path);
    docs = FakeKeyDocs();
    transport = InMemoryTransport();
    store = MapKeyStore();
    memberships = StreamController<List<Membership>>();
    trace = [];
    deleteCloudUser = () async => trace.add('deleteCloudUser');
    docs.onDeleteMember = (uid) => trace.add('deleteMember:$uid');
  });

  tearDown(() => memberships.close());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      dbKeyManagerProvider.overrideWithValue(
          DbKeyManager(store: MapKeyStore(), params: testKdfParams)),
      firebaseAppProvider.overrideWith((ref) => Future.value(null)),
      keyDocsProvider.overrideWithValue(docs),
      syncTransportProvider.overrideWithValue(transport),
      syncUidProvider.overrideWithValue('me'),
      cckServiceProvider.overrideWithValue(
          CckService(store, docs, UserKeyService(store, docs, uid: 'me'),
              uid: 'me')),
      myMembershipsProvider.overrideWith((ref) => memberships.stream),
      deleteCloudUserProvider.overrideWith((ref) async => deleteCloudUser),
      syncControllerProvider.overrideWith(() => _RecordingSync(trace)),
    ]);
    addTearDown(container.dispose);
    // AuthGate watches the session for the whole app life; without a listener
    // here the notifier is disposed between reads and resetAllData throws.
    container.listen(authSessionProvider, (_, _) {});
    return container;
  }

  /// The identity doc every test starts signed in with.
  void seedAccount() => docs.users['me'] = {'pubKey': 'pk', 'privKey': 'sk'};

  void seedCongregation(String cid, Map<String, MemberCapabilities> members) {
    docs.congregations[cid] = {'createdBy': 'me', 'keyVersion': 1};
    docs.members[cid] = {
      for (final MapEntry(key: uid, value: caps) in members.entries)
        uid: {
          'uid': uid,
          'pubKey': 'pk-$uid',
          'capabilities': caps.toMap(),
          'wrappedCcks': {'1': <String, String>{}},
          'status': 'active',
        },
    };
    transport.docs[cid] = {};
    transport.activity[cid] = {'scopes': <String, String>{}};
  }

  Membership membership(String cid, MemberCapabilities caps) => Membership(
      congregationId: cid, uid: 'me', capabilities: caps, keyVersion: 1);

  /// Lets pending microtasks and the session's async init run.
  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('waits for the memberships stream instead of planning for zero',
      () async {
    final container = makeContainer();
    await pump();
    seedAccount();
    seedCongregation('c1', {'me': MemberCapabilities.founder});

    var done = false;
    final deletion = container.read(deleteMyAccountProvider)();
    unawaited(deletion.then((_) => done = true));
    await pump();

    // The stream has not emitted yet: nothing may have been decided, let alone
    // deleted. Before the fix this planned for zero congregations and deleted
    // the account, orphaning c1 forever.
    expect(done, isFalse);
    expect(docs.users, contains('me'));
    expect(docs.congregations, contains('c1'));
    expect(trace, isEmpty);

    memberships.add([membership('c1', MemberCapabilities.founder)]);
    await deletion;

    expect(docs.congregations, isNot(contains('c1')));
    expect(docs.users, isNot(contains('me')));
  });

  test('pauses sync before the first delete and tears the space down',
      () async {
    final container = makeContainer();
    await pump();
    seedAccount();
    seedCongregation('c1', {'me': MemberCapabilities.founder});
    memberships.add([membership('c1', MemberCapabilities.founder)]);

    await container.read(deleteMyAccountProvider)();

    // A push between the first delete and the last one recreates items nobody
    // can delete afterwards, so the pause must come first.
    expect(trace.first, 'pause');
    expect(trace, contains('deleteMember:me'));
    expect(trace.last, 'deleteCloudUser');
    expect(transport.docs, isNot(contains('c1')));
    expect(transport.activity, isNot(contains('c1')));
    expect(docs.users, isNot(contains('me')));
  });

  test('sole admin with other members: refuses without touching anything',
      () async {
    final container = makeContainer();
    await pump();
    seedAccount();
    seedCongregation('c1', {
      'me': MemberCapabilities.founder,
      'bob': const MemberCapabilities(people: true),
    });
    memberships.add([membership('c1', MemberCapabilities.founder)]);

    await expectLater(container.read(deleteMyAccountProvider)(),
        throwsA(isA<AccountDeletionBlocked>()));

    expect(docs.congregations, contains('c1'));
    expect(docs.users, contains('me'));
    expect(trace, isEmpty);
  });

  test('a failing cloud delete gives sync back', () async {
    deleteCloudUser = () async => throw StateError('requires-recent-login');
    final container = makeContainer();
    await pump();
    seedAccount();
    memberships.add(const []);

    await expectLater(
        container.read(deleteMyAccountProvider)(), throwsStateError);

    expect(trace, ['pause', 'resume()']);
  });

  group('accountDeletionBlockersProvider', () {
    test('stays loading until the memberships have actually loaded', () async {
      final container = makeContainer();
      container.listen(accountDeletionBlockersProvider, (_, _) {});
      await pump();

      // An empty list here would clear the blockers and enable the button.
      expect(container.read(accountDeletionBlockersProvider).isLoading, isTrue);

      seedCongregation('c1', {
        'me': MemberCapabilities.founder,
        'bob': const MemberCapabilities(people: true),
      });
      memberships.add([membership('c1', MemberCapabilities.founder)]);
      await pump();

      expect(container.read(accountDeletionBlockersProvider).value, ['c1']);
    });
  });
}
