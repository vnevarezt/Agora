import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show InsertMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_database.dart';
import '../data/db/db_key_manager.dart' show KeychainKeyStore, SecureKeyStore;
import '../data/sync/cck_service.dart';
import '../data/sync/congregation_teardown.dart';
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
import 'auth_session.dart';
import 'cloud_auth.dart';
import 'db_provider.dart';
import 'sync_controller.dart';
import 'sync_keys.dart' show syncOwnerUidKey;

/// Cloud sync plumbing (phase 4b). Everything here is null unless the cloud
/// is configured AND a user is signed in; the SecureKeyStore mirrors
/// DbKeyManager's keychain so sync key material shares the app's keychain
/// hygiene. Tests override the leaf providers with fakes.

/// The OS keychain for sync key material (same store DbKeyManager uses).
final syncKeyStoreProvider =
    Provider<SecureKeyStore>((ref) => const KeychainKeyStore());

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

/// Signed-in uid (null while signed out / cloud disabled), and THE gate that
/// makes "local mode uploads nothing" structural: every service below hangs off
/// this, so a local-mode session cannot reach Firestore even with a live
/// Firebase user (which only the mode-migration wizard ever produces).
final syncUidProvider = Provider<String?>((ref) {
  final cloudMode = ref.watch(authSessionProvider
      .select((s) => s is SessionUnlocked && s.mode == AccountMode.cloud));
  return cloudMode ? ref.watch(cloudUserProvider).value?.uid : null;
});

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
    // Read at push time, not captured: capabilities can be downgraded (or
    // revoked) mid-session and the outbox must respect the change immediately.
    capabilitiesFor: (cid) async => ref.read(pushCapabilitiesProvider(cid)),
  );
});

final syncSeederProvider = Provider<SyncSeeder>(
    (ref) => SyncSeeder(ref.watch(dbProvider), ref.watch(syncScribeProvider)));

Query<Map<String, dynamic>> _membershipQuery(FirebaseFirestore fs, String uid) =>
    fs.collectionGroup('members').where('uid', isEqualTo: uid);

List<Membership> _membershipsOf(QuerySnapshot<Map<String, dynamic>> snap) => [
      for (final d in snap.docs)
        Membership.fromDoc(d.reference.parent.parent!.id, d.data()),
    ];

/// "My congregations": the collection-group membership stream. Drives the
/// pull target list, capability gating and the members UI. Empty when the
/// cloud is down or signed out.
final myMembershipsProvider = StreamProvider<List<Membership>>((ref) {
  final fs = ref.watch(firestoreProvider);
  final uid = ref.watch(syncUidProvider);
  if (fs == null || uid == null) return Stream.value(const []);
  return _membershipQuery(fs, uid).snapshots().map(_membershipsOf);
});

/// One-shot membership read for a uid the sync stack is not serving yet — the
/// upgrade wizard signs in while still in local mode, where [syncUidProvider]
/// (and therefore [myMembershipsProvider]) is deliberately null.
final membershipsOnceProvider =
    FutureProvider.autoDispose.family<List<Membership>, String>((ref, uid) async {
  final fs = ref.watch(firestoreProvider);
  if (fs == null) return const [];
  return _membershipsOf(await _membershipQuery(fs, uid).get());
});

/// What this user may PUSH in [congregationId] — the sync engine's write
/// filter, with the three-state resolution the raw membership can't express:
///
///  - no cloud session at all → null ("don't filter"): signed out, back in
///    local mode or Firebase down. Without this the empty membership list
///    reads as a revocation and locks the user out of their OWN data;
///  - never shared / not shared here → null (a local congregation has no
///    keyring, so the engine leaves its outbox queued);
///  - shared, membership still loading or errored → null (same "don't
///    filter": dropping outbox rows on a stale read would lose the user's
///    edits);
///  - member → their capabilities;
///  - shared before, absent now → read-only (REVOKED): [SyncEngine.pushOnce]
///    drops the forbidden docs instead of rebounding them against the rules
///    forever.
///
/// [rightsProvider] is the UI-facing view of the same resolution.
final pushCapabilitiesProvider =
    Provider.family<MemberCapabilities?, String>((ref, congregationId) {
  if (ref.watch(syncUidProvider) == null) return null;
  final shared = ref.watch(sharedCongregationIdsProvider).value;
  if (shared == null || !shared.contains(congregationId)) return null;
  final memberships = ref.watch(myMembershipsProvider);
  if (memberships.isLoading || memberships.hasError) return null;
  for (final m in memberships.value ?? const []) {
    if (m.congregationId == congregationId) return m.capabilities;
  }
  return const MemberCapabilities(); // revoked → read-only
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
/// [congregationId], right now — the UI-facing view of
/// [pushCapabilitiesProvider]. A null there (a local congregation, or a
/// membership not yet loaded) reads as full rights, so both stay fully
/// editable; only a confirmed revocation drops to read-only.
///
/// Route every gate through here rather than re-deriving it: confusing
/// "never shared" with "revoked" is the easy mistake, and they want opposite
/// answers.
final rightsProvider =
    Provider.family<MemberCapabilities, String>((ref, congregationId) =>
        ref.watch(pushCapabilitiesProvider(congregationId)) ??
        MemberCapabilities.founder);

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

/// Unlinks this device from the account: the E2E identity seed and every
/// cached congregation key leave the keychain, so a resold or lent device
/// keeps nothing. Best-effort throughout — a keychain hiccup must never trap
/// the user signed in.
///
/// Separate from the sign-out itself because the cloud → local migration has
/// to run it BEFORE the mode flips: every service below reads
/// [syncUidProvider], which local mode pins to null.
Future<void> _forgetSyncKeys(Ref ref, {Iterable<String>? congregationIds}) async {
  final cck = ref.read(cckServiceProvider);
  if (cck != null) {
    // A teardown has already deleted the member docs by the time it calls
    // this, so the live stream may have emitted an empty list: callers that
    // know which congregations were theirs must say so, or the keyrings stay
    // behind on the device.
    final cids = congregationIds ??
        <String>[
          for (final m in ref.read(myMembershipsProvider).value ?? const [])
            m.congregationId,
        ];
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
}

/// THE sign-out path. Coming back means linking this device again from one
/// that still syncs.
///
/// Every sign-out affordance must call this — never `CloudAuthService.signOut`
/// directly, or the keys stay behind.
final cloudSignOutProvider = Provider((ref) => () async {
      await _forgetSyncKeys(ref);
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

// ---- account & congregation deletion ---------------------------------------

/// The cloud-teardown primitive (gateway + transport). Null unless the cloud
/// is up and a user is signed in.
final congregationTeardownProvider = Provider<CongregationTeardown?>((ref) {
  final docs = ref.watch(keyDocsProvider);
  final transport = ref.watch(syncTransportProvider);
  final uid = ref.watch(syncUidProvider);
  if (docs == null || transport == null || uid == null) return null;
  return CongregationTeardown(docs, transport, uid: uid);
});

/// The Firebase-side "delete this user" step as a plain function, so the
/// deletion flow can be exercised without a real FirebaseAuth. Null once cloud
/// init settles with the cloud disabled.
final deleteCloudUserProvider = FutureProvider<Future<void> Function()?>(
    (ref) async => (await ref.watch(cloudAuthProvider.future))?.deleteAccount);

/// Thrown by [deleteMyAccountProvider] when the user is the sole admin of a
/// congregation that still has other members: deleting would strand them, so
/// we refuse and name the congregations to hand over or empty first.
class AccountDeletionBlocked implements Exception {
  const AccountDeletionBlocked(this.congregationIds);

  final List<String> congregationIds;

  @override
  String toString() => 'AccountDeletionBlocked($congregationIds)';
}

/// "My congregations", guaranteed loaded. Riverpod only subscribes to the
/// underlying query WHILE the provider is listened to, so reading `.future`
/// from a bare action would wait forever if nothing else happened to be
/// watching: hold a subscription across the read.
Future<List<Membership>> _awaitMemberships(Ref ref) async {
  final sub = ref.listen(myMembershipsProvider, (_, _) {});
  try {
    return await ref.read(myMembershipsProvider.future);
  } finally {
    sub.close();
  }
}

Future<void> _deleteSyncState(AppDatabase db, String cid) =>
    (db.delete(db.syncState)..where((t) => t.congregationId.equals(cid))).go();

/// Snapshots every congregation's member landscape into the deletion plan.
Future<AccountDeletionPlan> _accountDeletionPlan(
    CckService cck, String uid, List<Membership> memberships) async {
  final landscape = <String, List<MemberRole>>{};
  for (final m in memberships) {
    landscape[m.congregationId] = [
      for (final x in await cck.listMembers(m.congregationId))
        (memberUid: x.uid, admin: x.capabilities.admin),
    ];
  }
  return planAccountDeletion(uid, landscape);
}

/// Congregations that would BLOCK account deletion (I'm the sole admin and
/// other members remain). Lets the delete modal warn upfront, before asking
/// the user to reauthenticate. Empty when nothing blocks.
final accountDeletionBlockersProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final cck = ref.watch(cckServiceProvider);
  final uid = ref.watch(syncUidProvider);
  if (cck == null || uid == null) return const [];
  // Awaited, never `.value ?? []`: a stream that has not emitted yet would read
  // as "no congregations" and clear the very blockers this provider exists to
  // raise, enabling the button. Staying loading keeps the modal's spinner up.
  final memberships = await ref.watch(myMembershipsProvider.future);
  return (await _accountDeletionPlan(cck, uid, memberships)).blocked;
});

/// Admin action: hard-delete this congregation's cloud space while KEEPING the
/// local data — it reverts to a local-only congregation (un-share). Destroys
/// every other member's access, so the UI confirms first.
final deleteCongregationCloudProvider = Provider((ref) => (String cid) async {
      final teardown = ref.read(congregationTeardownProvider);
      if (teardown == null) {
        throw const SharingException(
            'keysUnavailable', 'Cloud sync is not available.');
      }
      final sync = ref.read(syncControllerProvider.notifier);
      // A push landing mid-wipe recreates item docs that nobody can delete
      // afterwards: `isAdmin(cid)` reads the member doc the wipe just removed.
      sync.pause();
      try {
        await teardown.wipe(cid);
        await ref.read(cckServiceProvider)?.forget([cid]);
        // Drop the "shared" fact so rightsProvider treats it as local again.
        await _deleteSyncState(ref.read(dbProvider), cid);
      } finally {
        // keepLocal: un-sharing removes both facts auto-enable uses to skip a
        // congregation (member doc + syncState), so without this it would
        // re-found the cloud space seconds later and undo the action.
        sync.resume(keepLocal: [cid]);
      }
    });

/// Cancels the cloud account: for every congregation, wipe (sole member &
/// admin) or leave; then delete the identity doc, delete the Firebase account,
/// and nuke ALL local data (back to the Portada).
///
/// The caller MUST have reauthenticated first — `user.delete()` needs a recent
/// login. Throws [AccountDeletionBlocked] BEFORE deleting anything when the
/// user is the sole admin of a shared congregation.
final deleteMyAccountProvider = Provider((ref) => () async {
      final teardown = ref.read(congregationTeardownProvider);
      final cck = ref.read(cckServiceProvider);
      final docs = ref.read(keyDocsProvider);
      final uid = ref.read(syncUidProvider);
      final deleteCloudUser = await ref.read(deleteCloudUserProvider.future);
      if (teardown == null ||
          cck == null ||
          docs == null ||
          uid == null ||
          deleteCloudUser == null) {
        throw const SharingException(
            'keysUnavailable', 'Cloud sync is not available.');
      }

      // Awaited, never `.value ?? []`: planning off a stream that has not
      // emitted would delete the account while leaving every congregation doc
      // behind — and no account able to delete them ever again.
      final memberships = await _awaitMemberships(ref);

      // Decide per congregation, then check FIRST (before any deletion):
      // refuse if deleting would strand other members.
      final plan = await _accountDeletionPlan(cck, uid, memberships);
      if (plan.blocked.isNotEmpty) throw AccountDeletionBlocked(plan.blocked);

      final sync = ref.read(syncControllerProvider.notifier);
      // See deleteCongregationCloudProvider: a push mid-wipe outlives the
      // teardown as undeletable docs.
      sync.pause();
      try {
        for (final cid in plan.wipe) {
          await teardown.wipe(cid);
          await cck.forget([cid]);
        }
        for (final cid in plan.leave) {
          await teardown.leave(cid);
          await cck.forget([cid]);
        }
        await docs.deleteUserDoc(uid);
        await deleteCloudUser();
      } catch (_) {
        // The account outlived the failure: the session is still live, so give
        // it its sync back instead of leaving a half-torn-down app mute.
        sync.resume();
        rethrow;
      }

      // Everything cloud-side is gone: wipe local and return to the Portada.
      await ref.read(authSessionProvider.notifier).resetAllData();
    });

// ---- account mode migration ------------------------------------------------

/// Cloud → local. Brings every congregation down BEFORE destroying the cloud
/// copy, so the local database is complete when the cord is cut, then hands the
/// session over to a password gate.
///
/// Throws [AccountDeletionBlocked] before touching anything when the user is
/// the sole admin of a congregation others still belong to, and a
/// [SharingException] when the final pull could not be confirmed — tearing the
/// cloud down on a half-synced device is how data goes missing.
///
/// [force] overrides only `syncIncomplete`, and exists so a congregation that
/// fails to pull forever cannot trap the user in cloud mode. `offline` and
/// `syncBusy` ignore it: the teardown itself needs the network, and a sync in
/// flight only needs a moment.
final downgradeToLocalProvider = Provider((ref) =>
    (String name, String password, {bool force = false}) async {
          final teardown = ref.read(congregationTeardownProvider);
          final cck = ref.read(cckServiceProvider);
          final uid = ref.read(syncUidProvider);
          if (teardown == null || cck == null || uid == null) {
            throw const SharingException(
                'keysUnavailable', 'Cloud sync is not available.');
          }

          final memberships = await _awaitMemberships(ref);
          final plan = await _accountDeletionPlan(cck, uid, memberships);
          if (plan.blocked.isNotEmpty) throw AccountDeletionBlocked(plan.blocked);

          final sync = ref.read(syncControllerProvider.notifier);
          await sync.syncNow();
          // Anything but idle means the drain is unconfirmed, and `syncing` is
          // the dangerous one: `syncNow` returns immediately when a debounced
          // push or a heartbeat pull is already in flight, so treating it as
          // success would destroy the cloud copy mid-transfer.
          final status = ref.read(syncControllerProvider);
          if (status.phase != SyncPhase.idle) {
            final reason = switch (status.phase) {
              SyncPhase.syncing => 'syncBusy',
              SyncPhase.offline => 'offline',
              _ => status.errorKey == 'offline' ? 'offline' : 'syncIncomplete',
            };
            if (!force || reason != 'syncIncomplete') {
              throw SharingException(
                  reason, 'The last sync did not complete; nothing was deleted.');
            }
          }

          sync.pause();
          try {
            for (final cid in plan.wipe) {
              await teardown.wipe(cid);
            }
            for (final cid in plan.leave) {
              await teardown.leave(cid);
            }
            await _forgetSyncKeys(ref,
                congregationIds: [...plan.wipe, ...plan.leave]);
          } catch (_) {
            sync.resume();
            rethrow;
          }

          final db = ref.read(dbProvider);
          await db.delete(db.syncState).go();
          await db.delete(db.outbox).go();

          // Before the sign-out: `_onCloudUser(null)` would otherwise route a
          // still-cloud session to the sign-in screen and unmount the caller.
          await ref
              .read(authSessionProvider.notifier)
              .downgradeToLocal(name, password);
          await (await ref.read(cloudAuthProvider.future))?.signOut();
        });
