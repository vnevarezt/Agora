import 'dart:convert';

import '../../models/congregation_invite.dart';
import '../../models/congregation_member.dart';
import '../../models/member_capabilities.dart';
import '../db/db_key_manager.dart' show SecureKeyStore;
import 'content_crypto.dart';
import 'invite_code.dart';
import 'key_docs_gateway.dart';
import 'sealed_box.dart';
import 'user_key_service.dart';

/// Something the sharing flows can't do, with a message worth showing:
/// an expired/consumed invite, an already-joined congregation, a member
/// whose public key is unusable.
class SharingException implements Exception {
  const SharingException(this.reason, this.message);

  /// 'inviteMissing' | 'inviteExpired' | 'alreadyMember' | 'keysUnavailable'
  /// | 'badMemberKey' — the UI localizes off this, not off [message].
  final String reason;

  final String message;

  @override
  String toString() => message;
}

/// Congregation Content Keys: creates them (founder), recovers them from the
/// member doc (sealed boxes to the user's pubkey) and caches the keyring in
/// the OS keychain. This IS the production `keyringFor` of [SyncEngine] —
/// returning null keeps that congregation's outbox queued (4a contract).
///
/// Also owns sharing (4b-2): minting invites, redeeming them, and the
/// revoke-and-rotate batch.
class CckService {
  CckService(
    this._store,
    this._docs,
    this._userKeys, {
    required this.uid,
  });

  final SecureKeyStore _store;
  final KeyDocsGateway _docs;
  final UserKeyService _userKeys;
  final String uid;

  /// Keychain entry: JSON `{ "1": "<base64 key>", ... }` per congregation,
  /// per uid (account switches never cross keyrings).
  String _cacheKeyName(String cid) => 'jw_program.sync.cck.$uid.$cid';

  Future<CongregationKeyring?> _cached(String cid) async {
    final json = await _store.read(_cacheKeyName(cid));
    if (json == null) return null;
    try {
      final map = (jsonDecode(json) as Map<String, dynamic>).map(
          (version, b64) =>
              MapEntry(int.parse(version), base64Decode(b64 as String)));
      return map.isEmpty ? null : CongregationKeyring(map);
    } catch (_) {
      return null; // unreadable cache: fall through to the member doc
    }
  }

  Future<void> _cache(String cid, CongregationKeyring keyring) =>
      _store.write(
        _cacheKeyName(cid),
        jsonEncode(keyring.keys
            .map((version, key) => MapEntry('$version', base64Encode(key)))),
      );

  /// Keys this member holds for [cid]; null = not syncable (no seed on this
  /// device, no membership, or no cloud space). Cache-first: the network is
  /// only hit on a cache miss — [refresh] handles rotation staleness.
  Future<CongregationKeyring?> keyringFor(String cid) async =>
      await _cached(cid) ?? await refresh(cid);

  /// Re-reads the member doc and re-caches. Call when the clear
  /// `keyVersion` on `congregations/{cid}` (or the member stream) says the
  /// cache is stale, or on a cache miss.
  Future<CongregationKeyring?> refresh(String cid) async {
    final seed = await _userKeys.seed();
    if (seed == null) return null; // passphrase locked on this device
    final member = await _docs.readMemberDoc(cid, uid);
    final wrapped = member?['wrappedCcks'] as Map<String, dynamic>?;
    // No member doc / wrappedCcks = cloud not enabled here, or not a member.
    if (wrapped == null || wrapped.isEmpty) return null;
    final keys = <int, List<int>>{};
    for (final MapEntry(key: version, value: box) in wrapped.entries) {
      keys[int.parse(version)] =
          await SealedBox.open((box as Map).cast<String, dynamic>(), seed);
    }
    final keyring = CongregationKeyring(keys);
    await _cache(cid, keyring);
    return keyring;
  }

  /// True when the server announces a newer CCK version than the cache
  /// holds (rotation happened elsewhere) — callers then [refresh].
  Future<bool> isStale(String cid) async {
    final cached = await _cached(cid);
    if (cached == null) return true;
    final server = await _docs.readCongregationKeyVersion(cid);
    return server != null && server > cached.currentVersion;
  }

  /// Founder bootstrap: mint CCK v1 and create the cloud space + own member
  /// doc in one batch (the shape the rules require). Requires [UserKeyStatus.ready].
  Future<CongregationKeyring> createCongregationSpace(
    String cid, {
    String? email,
    String? displayName,
  }) async {
    final seed = await _userKeys.seed();
    if (seed == null) {
      throw StateError('Sync keys are not ready on this device.');
    }
    final existing = await keyringFor(cid);
    if (existing != null) return existing; // already enabled

    final key = CongregationKeyring.newKey();
    final pub = await SealedBox.publicKeyOf(seed);
    await _docs.createCongregationSpace(
      cid: cid,
      uid: uid,
      memberData: {
        'uid': uid,
        'email': ?email,
        'displayName': ?displayName,
        'pubKey': base64Encode(pub),
        'capabilities': MemberCapabilities.founder.toMap(),
        'wrappedCcks': {'1': await SealedBox.seal(key, pub)},
        'inviteId': null,
        'addedBy': uid,
        'status': 'active',
      },
    );
    final keyring = CongregationKeyring({1: key});
    await _cache(cid, keyring);
    return keyring;
  }

  /// Drops every cached keyring of this uid for [cids] (sign-out hygiene or
  /// revocation handling).
  Future<void> forget(Iterable<String> cids) async {
    for (final cid in cids) {
      await _store.delete(_cacheKeyName(cid));
    }
  }

  // ---- invitations ----------------------------------------------------------

  static const defaultInviteTtl = Duration(days: 7);

  /// Mints an invite for [cid] and returns the code to share. Admin-only
  /// (the rules enforce it; the UI gates it).
  ///
  /// The invite carries the WHOLE keyring, not just the current version, so
  /// the redeemer can read everything written before they joined.
  Future<InviteCode> createInvite(
    String cid, {
    required MemberCapabilities capabilities,
    Duration ttl = defaultInviteTtl,
  }) async {
    final keyring = await keyringFor(cid);
    if (keyring == null) {
      throw const SharingException('keysUnavailable',
          'This congregation has no keys on this device yet.');
    }
    final code = InviteCode.mint(cid);
    await _docs.createInvite(cid, code.tokenId, {
      'capabilities': capabilities.toMap(),
      'wrappedKeyring': await InviteKeyringBox.seal(keyring, code),
      'createdBy': uid,
      'expiresAt': DateTime.now().toUtc().add(ttl),
    });
    return code;
  }

  Future<void> cancelInvite(String cid, String tokenId) =>
      _docs.deleteInvite(cid, tokenId);

  Future<List<CongregationInvite>> listInvites(String cid) async => [
        for (final e in (await _docs.listInvites(cid)).entries)
          CongregationInvite.fromDoc(e.key, e.value),
      ];

  /// Joins the congregation [code] points at and returns its keyring.
  ///
  /// Callers must follow this with an EXPLICIT pull: nothing else triggers
  /// one — with a null cursor `decidePull` returns `lazy` at most.
  Future<CongregationKeyring> redeemInvite(
    InviteCode code, {
    String? email,
    String? displayName,
  }) async {
    // Redemption writes a member doc sealed to OUR public key, so the
    // identity keypair has to exist first.
    if (!await _userKeys.ensureAvailable()) {
      throw const SharingException('keysUnavailable',
          'The sync keys for this account are not available on this device.');
    }
    final seed = (await _userKeys.seed())!;
    final cid = code.congregationId;

    // The rules return an identical permission-denied for expired, consumed
    // and already-a-member. Pre-checking our own member doc is the only way
    // to tell the user which one it is.
    if (await _docs.readMemberDoc(cid, uid) != null) {
      throw const SharingException(
          'alreadyMember', 'You already belong to this congregation.');
    }
    final invite = await _docs.readInvite(cid, code.tokenId);
    if (invite == null) {
      throw const SharingException('inviteMissing',
          'This invitation no longer exists — it may already have been used.');
    }
    final expiresAt = invite['expiresAt'] as DateTime?;
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc())) {
      throw const SharingException(
          'inviteExpired', 'This invitation has expired.');
    }

    final keyring = await InviteKeyringBox.open(
      (invite['wrappedKeyring'] as Map).cast<String, dynamic>(),
      code,
    );
    final pub = await SealedBox.publicKeyOf(seed);
    final wrapped = <String, Map<String, String>>{
      for (final MapEntry(key: version, value: key) in keyring.keys.entries)
        '$version': await SealedBox.seal(key, pub),
    };

    await _docs.redeemInvite(
      cid: cid,
      uid: uid,
      tokenId: code.tokenId,
      memberData: {
        'uid': uid,
        'email': ?email,
        'displayName': ?displayName,
        // Self-asserted ON PURPOSE, not an oversight: whoever holds the code
        // already has the keyring in the clear, so cross-checking this
        // against `users/{uid}` would add no security and would cost a read
        // per redemption. Don't "harden" it.
        'pubKey': base64Encode(pub),
        // Verbatim from the invite — the rules compare the two maps.
        'capabilities': invite['capabilities'],
        // Every version re-sealed to us, so history opens too.
        'wrappedCcks': wrapped,
        'inviteId': code.tokenId,
        'addedBy': invite['createdBy'],
        'status': 'active',
      },
    );
    await _cache(cid, keyring);
    return keyring;
  }

  // ---- members --------------------------------------------------------------

  Future<List<CongregationMember>> listMembers(String cid) async => [
        for (final m in await _docs.listMembers(cid))
          CongregationMember.fromDoc(m),
      ];

  Future<void> setMemberCapabilities(
    String cid,
    String memberUid,
    MemberCapabilities capabilities,
  ) =>
      _docs.updateMemberCapabilities(cid, memberUid, capabilities.toMap());

  // ---- revoke + rotate ------------------------------------------------------

  /// Removes [removeUids] and rotates the CCK to a fresh version in ONE
  /// batch, so the ejected member never holds a key that opens future
  /// writes. Returns the keyring including the new version.
  ///
  /// Downgrading a member needs NO rotation (they keep the keyring, and the
  /// rules stop their writes) — only ejection does.
  ///
  /// An admin may include their OWN uid: `isAdmin` evaluates against the
  /// caller's PRE-batch doc, so self-revocation + rotation commits, and it is
  /// the only way a departing admin can rotate at all (once their doc is
  /// gone they can no longer write).
  Future<CongregationKeyring> rotateAndRevoke(
    String cid, {
    Iterable<String> removeUids = const [],
  }) async {
    final keyring = await keyringFor(cid);
    if (keyring == null) {
      throw const SharingException('keysUnavailable',
          'This congregation has no keys on this device.');
    }
    final removing = removeUids.toSet();
    final members = await listMembers(cid);
    final serverVersion = await _docs.readCongregationKeyVersion(cid) ?? 0;
    final newVersion =
        (serverVersion > keyring.currentVersion ? serverVersion : keyring.currentVersion) + 1;
    final newKey = CongregationKeyring.newKey();

    final wrappedForMember = <String, Map<String, String>>{};
    for (final member in members) {
      if (removing.contains(member.uid)) continue;
      // Skipping a member with an unreadable key would leave a permanent
      // hole in their keyring: they'd silently stop reading new writes.
      // Fail loudly, naming who, so an admin can fix it.
      final List<int> pub;
      try {
        pub = base64Decode(member.pubKey);
      } on FormatException {
        throw SharingException('badMemberKey',
            'Member ${member.displayName ?? member.uid} has an unreadable '
            'public key; rotation aborted.');
      }
      wrappedForMember[member.uid] = await SealedBox.seal(newKey, pub);
    }

    await _docs.rotateKey(
      cid: cid,
      newKeyVersion: newVersion,
      wrappedForMember: wrappedForMember,
      removeMemberUids: removing,
      // Every pending invite dies with the old key: its wrappedKeyring is
      // immutable (`update: if false`), so a later redeemer would join blind
      // to everything written after this rotation.
      deleteInviteIds: (await _docs.listInvites(cid)).keys,
    );

    if (removing.contains(uid)) {
      // We just revoked ourselves: the new key is not ours to keep.
      await forget([cid]);
      return keyring;
    }
    final rotated =
        CongregationKeyring({...keyring.keys, newVersion: newKey});
    await _cache(cid, rotated);

    // Someone may have redeemed an invite BETWEEN the member list above and
    // the commit — their doc holds every version but the one we just minted.
    // This is the only moment that gap can open, so close it here. Costs one
    // read and zero writes when there is nothing to repair.
    await reconcileKeyrings(cid);
    return rotated;
  }

  /// Repairs members who missed a rotation (they were created between the
  /// member `list` and the rotation commit).
  ///
  /// Versions are CONTIGUOUS `1..keyVersion`, so the gap is simply
  /// `{1..keyVersion} \ member.wrappedVersions` — which is why the member
  /// model exposes the SET: a max of 3 can't reveal a hole at 2.
  ///
  /// Returns the number of members repaired.
  Future<int> reconcileKeyrings(String cid) async {
    final keyring = await keyringFor(cid);
    if (keyring == null) return 0;
    final target = await _docs.readCongregationKeyVersion(cid) ??
        keyring.currentVersion;
    final all = {for (var v = 1; v <= target; v++) v};

    var repaired = 0;
    for (final member in await listMembers(cid)) {
      // Only versions we ourselves hold can be handed out.
      final missing = all.difference(member.wrappedVersions)
        ..removeWhere((v) => !keyring.keys.containsKey(v));
      if (missing.isEmpty) continue;
      final List<int> pub;
      try {
        pub = base64Decode(member.pubKey);
      } on FormatException {
        continue; // nothing we can do for this one; rotation reports it
      }
      await _docs.appendWrappedCcks(cid, member.uid, {
        for (final v in missing) v: await SealedBox.seal(keyring.keys[v]!, pub),
      });
      repaired++;
    }
    return repaired;
  }
}
