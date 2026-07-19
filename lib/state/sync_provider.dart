import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/db_key_manager.dart' show KeychainKeyStore;
import '../data/sync/cck_service.dart';
import '../data/sync/content_crypto.dart';
import '../data/sync/firestore_key_docs.dart';
import '../data/sync/firestore_transport.dart';
import '../data/sync/key_docs_gateway.dart';
import '../data/sync/link_service.dart';
import '../data/sync/sync_engine.dart';
import '../data/sync/sync_seeder.dart';
import '../data/sync/sync_transport.dart';
import '../data/sync/user_key_service.dart';
import '../models/membership.dart';
import 'app_settings.dart';
import 'cloud_auth.dart';
import 'db_provider.dart';
import 'sync_keys.dart' show syncOwnerUidKey;

/// Cloud sync plumbing (phase 4b). Everything here is null unless the cloud
/// is configured AND a user is signed in; the SecureKeyStore mirrors
/// DbKeyManager's keychain so sync key material shares the app's keychain
/// hygiene. Tests override the leaf providers with fakes.

/// The OS keychain for sync key material (same store DbKeyManager uses).
final syncKeyStoreProvider =
    Provider((ref) => const KeychainKeyStore());

/// Firestore instance, or null when the cloud is unconfigured. Own cache
/// disabled: this app IS the offline layer (a second cache only creates
/// stale-read hazards, see FirestoreTransport).
final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final app = ref.watch(firebaseAppProvider).value;
  if (app == null) return null;
  final fs = FirebaseFirestore.instanceFor(app: app);
  fs.settings = const Settings(persistenceEnabled: false);
  return fs;
});

/// Signed-in uid (null while signed out / cloud disabled).
final syncUidProvider = Provider<String?>(
    (ref) => ref.watch(cloudUserProvider).value?.uid);

final keyDocsProvider = Provider<KeyDocsGateway?>((ref) {
  final fs = ref.watch(firestoreProvider);
  return fs == null ? null : FirestoreKeyDocs(fs);
});

final userKeyServiceProvider = Provider<UserKeyService?>((ref) {
  final docs = ref.watch(keyDocsProvider);
  final uid = ref.watch(syncUidProvider);
  if (docs == null || uid == null) return null;
  return UserKeyService(ref.watch(syncKeyStoreProvider), docs, uid: uid);
});

/// Moves the identity seed between the user's own devices (QR / pasted
/// code). Null until the cloud is up and someone is signed in.
final linkServiceProvider = Provider<LinkService?>((ref) {
  final docs = ref.watch(keyDocsProvider);
  final userKeys = ref.watch(userKeyServiceProvider);
  final uid = ref.watch(syncUidProvider);
  if (docs == null || userKeys == null || uid == null) return null;
  return LinkService(docs, userKeys, uid: uid);
});

final cckServiceProvider = Provider<CckService?>((ref) {
  final docs = ref.watch(keyDocsProvider);
  final userKeys = ref.watch(userKeyServiceProvider);
  final uid = ref.watch(syncUidProvider);
  if (docs == null || userKeys == null || uid == null) return null;
  return CckService(ref.watch(syncKeyStoreProvider), docs, userKeys, uid: uid);
});

final syncTransportProvider = Provider<SyncTransport?>((ref) {
  final fs = ref.watch(firestoreProvider);
  return fs == null ? null : FirestoreTransport(fs);
});

/// The push/pull engine, wired to the real transport + CCK key storage.
/// Null unless the DB is open, the cloud is up and a user is signed in.
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final transport = ref.watch(syncTransportProvider);
  final cck = ref.watch(cckServiceProvider);
  if (transport == null || cck == null) return null;
  return SyncEngine(
    ref.watch(dbProvider),
    transport,
    ContentCrypto(),
    deviceId: deviceId(),
    keyringFor: cck.keyringFor,
  );
});

final syncSeederProvider = Provider<SyncSeeder>(
    (ref) => SyncSeeder(ref.watch(dbProvider), ref.watch(syncScribeProvider)));

/// "My congregations": the collection-group membership stream. Drives the
/// pull target list, capability gating and the members UI. Empty when the
/// cloud is down or signed out.
final myMembershipsProvider = StreamProvider<List<Membership>>((ref) {
  final fs = ref.watch(firestoreProvider);
  final uid = ref.watch(syncUidProvider);
  if (fs == null || uid == null) return Stream.value(const []);
  return fs
      .collectionGroup('members')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snap) => [
            for (final d in snap.docs)
              Membership.fromDoc(d.reference.parent.parent!.id, d.data()),
          ]);
});

/// This user's capabilities in [congregationId] (null = not a member): gates
/// edit affordances so a view-only member never enqueues writes rules bounce.
final myCapabilitiesProvider = Provider.family((ref, String congregationId) {
  final memberships = ref.watch(myMembershipsProvider).value ?? const [];
  for (final m in memberships) {
    if (m.congregationId == congregationId) return m.capabilities;
  }
  return null;
});

/// Whether [congregationId] already has a cloud space this user belongs to.
final isCongregationSyncedProvider =
    Provider.family<bool, String>((ref, congregationId) {
  final memberships = ref.watch(myMembershipsProvider).value ?? const [];
  return memberships.any((m) => m.congregationId == congregationId);
});

/// THE sign-out path. Signing out unlinks this device: the E2E identity seed
/// and every cached congregation key are wiped from the keychain, so a
/// resold or lent device keeps nothing. Coming back means linking this
/// device again from one that still syncs.
///
/// Every sign-out affordance must call this — never `CloudAuthService.signOut`
/// directly, or the keys stay behind.
final cloudSignOutProvider = Provider((ref) => () async {
      final cck = ref.read(cckServiceProvider);
      if (cck != null) {
        final cids = <String>[
          for (final m in ref.read(myMembershipsProvider).value ?? const [])
            m.congregationId,
        ];
        // Best-effort: a keychain hiccup must never trap the user signed in.
        try {
          await cck.forget(cids);
        } catch (_) {}
      }
      try {
        await ref.read(userKeyServiceProvider)?.forget();
      } catch (_) {}
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(syncOwnerUidKey);
      } catch (_) {}
      await (await ref.read(cloudAuthProvider.future))?.signOut();
    });

/// Orchestrates enabling cloud sync for a congregation (founder path):
/// mint the CCK + create the cloud space, seed the whole subtree into the
/// outbox, then kick a sync. Requires the sync keys to be ready and the user
/// signed in. Returns false when preconditions aren't met.
final enableCongregationSyncProvider =
    Provider((ref) => (String congregationId) async {
          final cck = ref.read(cckServiceProvider);
          if (cck == null) return false;
          await cck.createCongregationSpace(congregationId);
          await ref.read(syncSeederProvider).seedCongregation(congregationId);
          return true;
        });
