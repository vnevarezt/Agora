import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The system keychain is unavailable or rejected the operation. Without the
/// key the encrypted DB can't be opened (by design there's no insecure
/// fallback): the backup is to export `.jwpp` regularly.
class DbKeyException implements Exception {
  const DbKeyException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// DB encryption key: 256 random bits generated on first launch and stored in
/// the OS keychain (Keychain/Keystore/DPAPI).
class DbKeyManager {
  DbKeyManager([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // macOS: classic keychain — the data-protection keychain requires
              // a provisioning profile (keychain-access-groups entitlement),
              // unavailable when signing with a development certificate only.
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            );

  final FlutterSecureStorage _storage;

  static const _keyName = 'jw_program.db_key.v1';

  Future<String> getOrCreateKeyHex() async {
    try {
      final existing = await _storage.read(key: _keyName);
      if (existing != null && existing.length == 64) return existing;

      final rnd = Random.secure();
      final hex = List.generate(
          32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: _keyName, value: hex);

      // Some platforms fail the write SILENTLY (e.g. macOS signed wrong):
      // verify by reading it back before encrypting anything.
      final verified = await _storage.read(key: _keyName);
      if (verified != hex) {
        throw const DbKeyException(
            'No se pudo guardar la clave en el llavero del sistema. '
            'La base de datos local no puede abrirse.');
      }
      return hex;
    } on DbKeyException {
      rethrow;
    } catch (e) {
      throw DbKeyException(
          'No se pudo acceder al llavero del sistema. '
          'La base de datos local no puede abrirse. ($e)',
          e);
    }
  }
}
