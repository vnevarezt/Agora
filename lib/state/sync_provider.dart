import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show InsertMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_database.dart';
import '../data/db/db_key_manager.dart' show KeychainKeyStore;
import '../data/sync/cck_service.dart';
import '../data/sync/content_crypto.dart';
import '../data/sync/firestore_key_docs.dart';
import '../data/sync/firestore_transport.dart';
import '../data/sync/invite_code.dart';
import '../data/sync/key_docs_gateway.dart';
import '../data/sync/sync_engine.dart';
import '../data/sync/sync_seeder.dart';
import '../data/sync/sync_transport.dart';
import '../data/sync/user_key_service.dart';
import '../models/congregation_invite.dart';
import '../models/congregation_member.dart';
import '../models/member_capabilities.dart';
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
    // Read at push time, not captured: capabilities can be downgraded
    // mid-session and the outbox must respect the change immediately.
    capabilitiesFor: (cid) async => ref.read(myCapabilitiesProvider(cid)),
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

/// This user's capabilities in [congregationId] (null = not a member).
///
/// Do NOT gate the UI on this directly — null means two OPPOSITE things (a
/// local-only congregation, where you have every right, and a revoked
/// membership, where you have none). Use [rightsProvider], which resolves
/// that with a local fact.
final myCapabilitiesProvider = Provider.family((ref, String congregationId) {
  final memberships = ref.watch(myMembershipsProvider).value ?? const [];
  for (final m in memberships) {
    if (m.congregationId == congregationId) return m.capabilities;
  }
  return null;
});

/// Congregations this device has ever had a cloud presence for. A `syncState`
/// row is written the moment one is enabled or joined, and is never removed
/// — which is exactly what tells a never-shared congregation apart from one
/// we were thrown out of.
final sharedCongregationIdsProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(dbProvider);
  return db
      .select(db.syncState)
      .watch()
      .map((rows) => {for (final r in rows) r.congregationId});
});

/// THE gate for every edit affordance: what this user may do in
/// [congregationId], right now.
///
/// Three states that [myCapabilitiesProvider] alone cannot tell apart:
///
///  - never shared → full rights (it is your own local congregation);
///  - shared, membership still loading → optimistically full (blocking the
///    UI on an in-flight query would read as a bug, and the push filter plus
///    the rules catch anything we get wrong);
///  - shared before, not a member now → read-only (revoked).
///
/// Route every gate through here rather than re-deriving it: getting the
/// first and third confused is the easy mistake, and they want opposite
/// answers.
final rightsProvider =
    Provider.family<MemberCapabilities, String>((ref, congregationId) {
  const readOnly = MemberCapabilities();
  final shared = ref.watch(sharedCongregationIdsProvider).value;
  if (shared == null || !shared.contains(congregationId)) {
    return MemberCapabilities.founder;
  }
  final memberships = ref.watch(myMembershipsProvider);
  if (memberships.isLoading || memberships.hasError) {
    return MemberCapabilities.founder;
  }
  for (final m in memberships.value ?? const []) {
    if (m.congregationId == congregationId) return m.capabilities;
  }
  return readOnly;
});

/// The members admin screen's live list.
///
/// `autoDispose` is load-bearing, not tidiness: zero reads at rest is a
/// product goal, and this listener costs one read per member per change for
/// as long as it is open. It must die with the screen.
final congregationMembersProvider = StreamProvider.autoDispose
    .family<List<CongregationMember>, String>((ref, congregationId) {
  final docs = ref.watch(keyDocsProvider);
  if (docs == null) return Stream.value(const []);
  return docs.watchMembers(congregationId).map(
      (rows) => [for (final r in rows) CongregationMember.fromDoc(r)]);
});

/// Pending invites of a congregation (admin-only per the rules). Same
/// autoDispose reasoning as [congregationMembersProvider].
final congregationInvitesProvider = StreamProvider.autoDispose
    .family<List<CongregationInvite>, String>((ref, congregationId) {
  final docs = ref.watch(keyDocsProvider);
  if (docs == null) return Stream.value(const []);
  return docs.watchInvites(congregationId).map((rows) => [
        for (final e in rows.entries) CongregationInvite.fromDoc(e.key, e.value),
      ]);
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
          await markCongregationShared(
              ref.read(dbProvider), congregationId);
          await ref.read(syncSeederProvider).seedCongregation(congregationId);
          return true;
        });

/// Records that [congregationId] has a cloud presence on this device.
///
/// It is the local fact [rightsProvider] reads to tell "never shared" from
/// "revoked", so it must be written when sharing STARTS, not as a side
/// effect of a first successful pull — a congregation with nothing to pull
/// would otherwise look local-only forever.
///
/// insertOrIgnore, never a plain upsert: an existing row carries the pull
/// cursor, and resetting that would silently re-download the world.
Future<void> markCongregationShared(AppDatabase db, String congregationId) =>
    db.into(db.syncState).insert(
          SyncStateCompanion.insert(
            congregationId: congregationId,
            updatedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );

/// Joins the congregation an invite code points at: redeem, mark it shared,
/// then pull explicitly — nothing else would (with a null cursor
/// `decidePull` returns `lazy` at most, so the data would trickle in
/// minutes later, if at all).
final redeemInviteProvider = Provider((ref) => (InviteCode code) async {
      final cck = ref.read(cckServiceProvider);
      if (cck == null) {
        throw const SharingException(
            'keysUnavailable', 'Cloud sync is not available.');
      }
      final user = ref.read(cloudUserProvider).value;
      await cck.redeemInvite(code,
          email: user?.email, displayName: user?.displayName);
      final cid = code.congregationId;
      await markCongregationShared(ref.read(dbProvider), cid);

      final engine = ref.read(syncEngineProvider);
      if (engine != null) {
        PullResult page;
        do {
          page = await engine.pullOnce(cid);
        } while (page.fetched >= FirestoreTransport.pageSize);
      }
      return cid;
    });
