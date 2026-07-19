import 'dart:convert';

import '../crypto/passphrase_envelope.dart' show PassphraseEnvelope;
import '../db/db_key_manager.dart' show SecureKeyStore;
import 'key_docs_gateway.dart';
import 'sealed_box.dart';

/// Where this user stands with their sync identity key.
enum UserKeyStatus {
  /// No identity yet: signing in mints one.
  notSetUp,

  /// The identity is available to this device (cached locally, or fetched
  /// from the account).
  ready,

  /// The account has an identity but this device can't reach it right now
  /// (offline / read failed). Transient — retry.
  unavailable,
}

/// The user's X25519 identity key: the key congregation content keys (CCKs)
/// are sealed to.
///
/// It is stored in `users/{uid}`, readable ONLY by that account per the
/// security rules, and cached in the device keychain. That custody choice is
/// deliberate and has a cost worth stating plainly: signing in restores
/// everything with no code or passphrase to remember, but whoever controls
/// the Firebase project can also read this key — and therefore the content.
/// The protection that remains is transport + at-rest encryption, the rules,
/// and the encrypted local database.
///
/// Moving to a model where nobody but the user can read the data means not
/// escrowing this key (and giving the user a recovery code instead); the
/// content format would not change, so that upgrade needs no migration.
class UserKeyService {
  UserKeyService(this._store, this._docs, {required this.uid});

  final SecureKeyStore _store;
  final KeyDocsGateway _docs;
  final String uid;

  /// Keychain cache: 32-byte X25519 seed, base64. Per-uid so switching
  /// accounts never crosses identities.
  String get _seedKeyName => 'jw_program.sync.userkey.$uid';

  Future<UserKeyStatus> status() async {
    if (await _cachedSeed() != null) return UserKeyStatus.ready;
    final doc = await _docs.readUserDoc(uid);
    if (doc == null) return UserKeyStatus.notSetUp;
    return doc['privKey'] is String
        ? UserKeyStatus.ready
        // A pre-escrow account (or a doc we couldn't read): nothing this
        // device can do on its own.
        : UserKeyStatus.unavailable;
  }

  /// The identity seed, fetching and caching it from the account on a device
  /// that doesn't have it yet. Null when the account has no identity, or the
  /// key can't be reached (offline).
  Future<List<int>?> seed() async {
    final cached = await _cachedSeed();
    if (cached != null) return cached;
    final escrowed = (await _docs.readUserDoc(uid))?['privKey'];
    if (escrowed is! String) return null;
    final seed = _decode(escrowed);
    if (seed == null) return null;
    await _store.write(_seedKeyName, escrowed);
    return seed;
  }

  Future<List<int>?> _cachedSeed() async {
    final b64 = await _store.read(_seedKeyName);
    return b64 == null ? null : _decode(b64);
  }

  static List<int>? _decode(String b64) {
    try {
      final bytes = base64Decode(b64);
      return bytes.length == 32 ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  /// Mints the identity for a brand-new account, with no user interaction.
  /// Refuses to overwrite an existing one — that would orphan every key
  /// already sealed to it.
  Future<void> generate() async {
    if (await _docs.readUserDoc(uid) != null) {
      throw StateError('This account already has a sync identity.');
    }
    final seed = PassphraseEnvelope.randomBytes(32);
    final encoded = base64Encode(seed);
    await _docs.createUserDoc(
      uid,
      pubKey: base64Encode(await SealedBox.publicKeyOf(seed)),
      privKey: encoded,
    );
    await _store.write(_seedKeyName, encoded);
  }

  /// Makes sure this device can use the account's identity: fetches it, or
  /// mints one the first time. Returns false when it isn't reachable.
  Future<bool> ensureAvailable() async {
    if (await seed() != null) return true;
    if (await _docs.readUserDoc(uid) != null) return false; // exists, unreachable
    await generate();
    return true;
  }

  /// One-shot cleanup of the pre-4c passphrase envelope, which no device
  /// reads any more.
  Future<void> dropLegacyEnvelope() async {
    final doc = await _docs.readUserDoc(uid);
    if (doc == null || !doc.containsKey('wrappedPrivKey')) return;
    try {
      await _docs.dropLegacyEnvelope(uid);
    } catch (_) {
      // Cosmetic: a stale field costs nothing, retry next launch.
    }
  }

  /// Drops the cached copy from this device (sign-out hygiene). The account
  /// keeps the identity, so signing back in restores it.
  Future<void> forget() => _store.delete(_seedKeyName);
}
