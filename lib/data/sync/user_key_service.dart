import 'dart:convert';

import '../crypto/passphrase_envelope.dart' show PassphraseEnvelope;
import '../db/db_key_manager.dart' show SecureKeyStore;
import 'key_docs_gateway.dart';
import 'sealed_box.dart';

/// Where this user stands with their sync identity key.
enum UserKeyStatus {
  /// `users/{uid}` doesn't exist: brand-new account → generate a key.
  notSetUp,

  /// The account has an identity but THIS device doesn't hold the seed →
  /// it must be linked from a device that already syncs.
  needsLink,

  /// The seed is in this device's keychain: sealed boxes can be opened.
  ready,
}

/// The user's X25519 identity key for E2E sync.
///
/// The public half is published in `users/{uid}`; the private seed is
/// generated on the first device, kept ONLY in device keychains, and reaches
/// further devices by direct transfer (see `device_link.dart`). It is never
/// derivable from anything the server holds — which is exactly why nobody
/// with database access can read congregation content, and also why losing
/// every device means losing access (an admin re-invite is the way back).
class UserKeyService {
  UserKeyService(this._store, this._docs, {required this.uid});

  final SecureKeyStore _store;
  final KeyDocsGateway _docs;
  final String uid;

  /// Keychain entry: 32-byte X25519 seed, base64. Per-uid so switching
  /// accounts never crosses identities.
  String get _seedKeyName => 'jw_program.sync.userkey.$uid';

  Future<UserKeyStatus> status() async {
    if (await seed() != null) return UserKeyStatus.ready;
    final doc = await _docs.readUserDoc(uid);
    return doc == null ? UserKeyStatus.notSetUp : UserKeyStatus.needsLink;
  }

  /// Cached seed, or null when this device hasn't been linked yet.
  Future<List<int>?> seed() async {
    final b64 = await _store.read(_seedKeyName);
    if (b64 == null) return null;
    try {
      final bytes = base64Decode(b64);
      return bytes.length == 32 ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  /// The account's published public key, used to verify a transferred seed.
  Future<List<int>?> publishedPublicKey() async {
    final b64 = (await _docs.readUserDoc(uid))?['pubKey'] as String?;
    if (b64 == null) return null;
    try {
      return base64Decode(b64);
    } on FormatException {
      return null;
    }
  }

  /// First device of a brand-new account: mint the identity with no user
  /// interaction at all. Refuses to overwrite an existing identity — that
  /// would strand every other device and every key sealed to the old one.
  Future<void> generate() async {
    if (await _docs.readUserDoc(uid) != null) {
      throw StateError('This account already has a sync identity.');
    }
    final seed = PassphraseEnvelope.randomBytes(32);
    await _docs.createUserDoc(uid,
        pubKey: base64Encode(await SealedBox.publicKeyOf(seed)));
    await _store.write(_seedKeyName, base64Encode(seed));
  }

  /// Stores a seed received from another device. The caller must already
  /// have verified it against [publishedPublicKey].
  Future<void> adopt(List<int> seed) =>
      _store.write(_seedKeyName, base64Encode(seed));

  /// One-shot cleanup of the pre-4c passphrase envelope. Best-effort: only
  /// meaningful from a device that already holds the seed.
  Future<void> dropLegacyEnvelope() async {
    final doc = await _docs.readUserDoc(uid);
    if (doc == null || !doc.containsKey('wrappedPrivKey')) return;
    try {
      await _docs.dropLegacyEnvelope(uid);
    } catch (_) {
      // Cosmetic: a stale field costs nothing, retry next launch.
    }
  }

  /// Drops the seed from this device (sign-out unlinks it). The account keeps
  /// its identity; coming back means linking from another device.
  Future<void> forget() => _store.delete(_seedKeyName);
}
