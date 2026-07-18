import 'dart:convert';

import '../crypto/passphrase_envelope.dart';
import '../db/db_key_manager.dart' show SecureKeyStore;
import 'key_docs_gateway.dart';
import 'sealed_box.dart';

/// Where this user stands with their sync identity key.
enum UserKeyStatus {
  /// `users/{uid}` doesn't exist: sync was never set up → create flow.
  notSetUp,

  /// The cloud doc exists but this device holds no seed → passphrase prompt.
  locked,

  /// The seed is cached in the keychain: sealed boxes can be opened.
  ready,
}

/// The user's X25519 identity key for E2E sync (DATA_ARCHITECTURE.md §5):
/// public key published in `users/{uid}`, private seed wrapped under the
/// sync passphrase in the same doc, and cached CLEAR in the OS keychain of
/// devices that unlocked it. Forgetting the passphrase is recoverable only
/// by re-inviting (there is deliberately no server-side escrow).
class UserKeyService {
  UserKeyService(
    this._store,
    this._docs, {
    required this.uid,
    PassphraseEnvelope envelope = const PassphraseEnvelope(),
  }) : _envelope = envelope;

  final SecureKeyStore _store;
  final KeyDocsGateway _docs;
  final String uid;
  final PassphraseEnvelope _envelope;

  /// Keychain entry: 32-byte X25519 seed, base64. Per-uid so switching
  /// accounts never crosses identities.
  String get _seedKeyName => 'jw_program.sync.userkey.$uid';

  Future<UserKeyStatus> status() async {
    if (await seed() != null) return UserKeyStatus.ready;
    final doc = await _docs.readUserDoc(uid);
    return doc == null ? UserKeyStatus.notSetUp : UserKeyStatus.locked;
  }

  /// Cached seed, or null when this device hasn't unlocked (or set up) yet.
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

  Future<List<int>?> publicKey() async {
    final s = await seed();
    return s == null ? null : SealedBox.publicKeyOf(s);
  }

  /// First-time setup: generate the keypair, publish `users/{uid}` and cache
  /// the seed. Refuses to overwrite an existing doc (that would strand every
  /// other device — use [unlock] or [changePassphrase]).
  Future<void> create(String passphrase) async {
    if (await _docs.readUserDoc(uid) != null) {
      throw StateError('Sync keys already exist for this account.');
    }
    final seed = PassphraseEnvelope.randomBytes(32);
    await _docs.writeUserDoc(uid, {
      'pubKey': base64Encode(await SealedBox.publicKeyOf(seed)),
      'wrappedPrivKey': await _envelope.wrap(seed, passphrase),
    });
    await _store.write(_seedKeyName, base64Encode(seed));
  }

  /// New device: open the wrapped seed with the passphrase and cache it.
  /// Throws [WrongPassphraseException] / [CorruptEnvelopeException]; throws
  /// [StateError] when the account has no keys yet.
  Future<void> unlock(String passphrase) async {
    final doc = await _docs.readUserDoc(uid);
    if (doc == null) throw StateError('No sync keys exist for this account.');
    final seed =
        await _envelope.unwrap(doc['wrappedPrivKey'] as String, passphrase);
    await _store.write(_seedKeyName, base64Encode(seed));
  }

  /// Re-wraps the SAME seed under a new passphrase (the public key — and
  /// every wrappedCck sealed to it — stays valid).
  Future<void> changePassphrase(String current, String next) async {
    final doc = await _docs.readUserDoc(uid);
    if (doc == null) throw StateError('No sync keys exist for this account.');
    final seed =
        await _envelope.unwrap(doc['wrappedPrivKey'] as String, current);
    await _docs.writeUserDoc(uid, {
      'pubKey': doc['pubKey'],
      'wrappedPrivKey': await _envelope.wrap(seed, next),
    });
    await _store.write(_seedKeyName, base64Encode(seed));
  }

  /// Drops the cached seed (sign-out hygiene). The cloud doc stays: any
  /// device can re-unlock with the passphrase.
  Future<void> forget() => _store.delete(_seedKeyName);
}
