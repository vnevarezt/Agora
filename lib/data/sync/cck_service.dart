import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../models/member_capabilities.dart';
import '../db/db_key_manager.dart' show SecureKeyStore;
import 'content_crypto.dart';
import 'key_docs_gateway.dart';
import 'sealed_box.dart';
import 'user_key_service.dart';

/// Congregation Content Keys: creates them (founder), recovers them from the
/// member doc (sealed boxes to the user's pubkey) and caches the keyring in
/// the OS keychain. This IS the production `keyringFor` of [SyncEngine] —
/// returning null keeps that congregation's outbox queued (4a contract).
///
/// Rotation (revocation) lands with the members UI in 4b-2.
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
    if (seed == null) {
      debugPrint('sync/cck: no seed on this device (passphrase locked) '
          '→ no keyring for $cid');
      return null;
    }
    final member = await _docs.readMemberDoc(cid, uid);
    final wrapped = member?['wrappedCcks'] as Map<String, dynamic>?;
    if (wrapped == null || wrapped.isEmpty) {
      debugPrint('sync/cck: no member doc / wrappedCcks for $cid '
          '(cloud not enabled on this congregation, or not a member) '
          '→ no keyring');
      return null;
    }
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
}
