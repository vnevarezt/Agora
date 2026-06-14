import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// El llavero del sistema no está disponible o rechazó la operación.
/// Sin la clave, la BD cifrada no puede abrirse (por diseño no hay
/// alternativa insegura): el respaldo es exportar `.jwpp` regularmente.
class ClaveDbException implements Exception {
  const ClaveDbException(this.mensaje, [this.causa]);

  final String mensaje;
  final Object? causa;

  @override
  String toString() => mensaje;
}

/// Clave de cifrado de la BD: 256 bits aleatorios generados en el primer
/// arranque y guardados en el llavero del SO (Keychain/Keystore/DPAPI).
class DbKeyManager {
  DbKeyManager([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // macOS: llavero clásico — el data-protection keychain exige
              // provisioning profile (entitlement keychain-access-groups),
              // no disponible firmando solo con certificado de desarrollo.
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            );

  final FlutterSecureStorage _storage;

  static const _kClave = 'jw_program.db_key.v1';

  Future<String> getOrCreateKeyHex() async {
    try {
      final existente = await _storage.read(key: _kClave);
      if (existente != null && existente.length == 64) return existente;

      final rnd = Random.secure();
      final hex = List.generate(
          32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: _kClave, value: hex);

      // Algunas plataformas fallan la escritura EN SILENCIO (p. ej. macOS
      // mal firmado): verificar leyendo de vuelta antes de cifrar nada.
      final verificada = await _storage.read(key: _kClave);
      if (verificada != hex) {
        throw const ClaveDbException(
            'No se pudo save la clave en el llavero del sistema. '
            'La base de datos local no puede abrirse.');
      }
      return hex;
    } on ClaveDbException {
      rethrow;
    } catch (e) {
      throw ClaveDbException(
          'No se pudo acceder al llavero del sistema. '
          'La base de datos local no puede abrirse. ($e)',
          e);
    }
  }
}
