import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../models/hermano.dart';

// Formato de archivo .jwpp v1 ("JW Program Participantes").
//
// JSON UTF-8 exterior: format/version/exportedAt/resumen?/cipher/payload.
// Payload interno: {"hermanos":[...]} → gzip → (opcional) AES-256-GCM con
// clave derivada por PBKDF2-HMAC-SHA256. Con cifrado se omite `resumen`
// (no filtrar datos en claro); sin cifrado la integridad la da `sha256`.
//
// Funciones top-level y argumentos sendables: aptas para `compute()`
// (PBKDF2 a 210k iteraciones tarda ~1 s en móvil).

const kJwppFormato = 'jwprogram/participantes';
const kJwppVersion = 1;
const kJwppIteracionesDefault = 210000;

final _aad = utf8.encode('$kJwppFormato|$kJwppVersion');

class JwppFormatoException implements Exception {
  const JwppFormatoException(
      [this.mensaje = 'El archivo está dañado o no es un .jwpp válido.']);
  final String mensaje;
  @override
  String toString() => mensaje;
}

class JwppVersionException implements Exception {
  const JwppVersionException(
      [this.mensaje =
          'Este archivo fue creado por una versión más reciente de la app.']);
  final String mensaje;
  @override
  String toString() => mensaje;
}

class JwppPasswordException implements Exception {
  const JwppPasswordException(
      [this.mensaje = 'Contraseña incorrecta o archivo dañado.']);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Cabecera del archivo (sin descifrar): basta para saber si pide
/// contraseña y mostrar el resumen previo al import.
class InfoJwpp {
  final int version;
  final bool cifrado;
  final DateTime? exportedAt;

  /// null cuando el archivo está cifrado (el resumen se omite).
  final int? total;
  final List<String> congregaciones;

  const InfoJwpp({
    required this.version,
    required this.cifrado,
    this.exportedAt,
    this.total,
    this.congregaciones = const [],
  });
}

/// Resultado de decodificar: hermanos válidos + registros descartados.
class DecodificadoJwpp {
  final List<Hermano> hermanos;
  final int omitidos;

  const DecodificadoJwpp({required this.hermanos, required this.omitidos});
}

Map<String, Object?> _parseRaiz(Uint8List bytes) {
  Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } catch (_) {
    throw const JwppFormatoException();
  }
  if (decoded is! Map<String, Object?> || decoded['format'] != kJwppFormato) {
    throw const JwppFormatoException();
  }
  final version = decoded['version'];
  if (version is! int) throw const JwppFormatoException();
  if (version > kJwppVersion) throw const JwppVersionException();
  return decoded;
}

InfoJwpp leerCabeceraJwpp(Uint8List bytes) {
  final raiz = _parseRaiz(bytes);
  final cipher = raiz['cipher'];
  final alg = cipher is Map ? cipher['alg'] : null;
  final resumen = raiz['resumen'];
  return InfoJwpp(
    version: raiz['version'] as int,
    cifrado: alg != null && alg != 'none',
    exportedAt: DateTime.tryParse(raiz['exportedAt'] as String? ?? ''),
    total: resumen is Map ? resumen['total'] as int? : null,
    congregaciones: resumen is Map
        ? [
            for (final c in (resumen['congregaciones'] as List? ?? const []))
              if (c is String) c,
          ]
        : const [],
  );
}

Map<String, Object?> _aJson(Hermano h) => {
      'id': h.id,
      'nombre': h.nombre,
      'sexo': h.sexo.name,
      'privilegio': h.privilegio.name,
      'congregacion': h.congregacion,
      'activo': h.activo,
      'notas': h.notas,
      'createdAt': h.createdAt.toIso8601String(),
      'updatedAt': h.updatedAt.toIso8601String(),
      'ultimoUso': h.ultimoUso?.toIso8601String(),
    };

/// Parse tolerante: campos desconocidos se ignoran (forward-compat);
/// sin id/nombre válidos → null (se cuenta como omitido).
Hermano? _deJson(Object? o) {
  if (o is! Map) return null;
  final id = o['id'];
  final nombre = o['nombre'];
  if (id is! String || id.isEmpty) return null;
  if (nombre is! String || nombre.trim().isEmpty) return null;

  T enumDe<T extends Enum>(List<T> valores, Object? v, T fallback) =>
      valores.asNameMap()[v] ?? fallback;
  DateTime fecha(Object? v) =>
      (v is String ? DateTime.tryParse(v) : null) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  final ultimoUso = o['ultimoUso'];
  return Hermano(
    id: id,
    nombre: nombre.trim(),
    sexo: enumDe(Sexo.values, o['sexo'], Sexo.noEspecificado),
    privilegio:
        enumDe(Privilegio.values, o['privilegio'], Privilegio.publicador),
    congregacion: (o['congregacion'] as String? ?? '').trim(),
    activo: o['activo'] as bool? ?? true,
    notas: o['notas'] as String? ?? '',
    createdAt: fecha(o['createdAt']),
    updatedAt: fecha(o['updatedAt']),
    ultimoUso:
        ultimoUso is String ? DateTime.tryParse(ultimoUso) : null,
  );
}

List<int> _aleatorios(int n) {
  final rnd = Random.secure();
  return List<int>.generate(n, (_) => rnd.nextInt(256));
}

Future<SecretKey> _derivarClave(
    String password, List<int> salt, int iteraciones) {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iteraciones,
    bits: 256,
  );
  return pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Future<Uint8List> codificarJwpp(
  List<Hermano> hermanos, {
  String? password,
  int iteraciones = kJwppIteracionesDefault,
}) async {
  final payloadClaro = utf8.encode(
      jsonEncode({'hermanos': [for (final h in hermanos) _aJson(h)]}));
  final comprimido = gzip.encode(payloadClaro);
  final cifrar = password != null && password.isNotEmpty;

  final Map<String, Object?> cipher;
  final List<int> payload;
  if (!cifrar) {
    final hash = await Sha256().hash(comprimido);
    cipher = {'alg': 'none', 'sha256': _hex(hash.bytes)};
    payload = comprimido;
  } else {
    final salt = _aleatorios(16);
    final clave = await _derivarClave(password, salt, iteraciones);
    final caja = await AesGcm.with256bits().encrypt(
      comprimido,
      secretKey: clave,
      nonce: _aleatorios(12),
      aad: _aad,
    );
    cipher = {
      'alg': 'aes-256-gcm',
      'kdf': {
        'alg': 'pbkdf2-hmac-sha256',
        'iterations': iteraciones,
        'salt': base64Encode(salt),
      },
      'nonce': base64Encode(caja.nonce),
      'mac': base64Encode(caja.mac.bytes),
    };
    payload = caja.cipherText;
  }

  final raiz = <String, Object?>{
    'format': kJwppFormato,
    'version': kJwppVersion,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    // El resumen filtra datos: solo va en claro cuando NO hay cifrado.
    if (!cifrar)
      'resumen': {
        'total': hermanos.length,
        'congregaciones': {
          for (final h in hermanos)
            if (h.congregacion.trim().isNotEmpty) h.congregacion.trim(),
        }.toList()
          ..sort(),
      },
    'cipher': cipher,
    'payload': base64Encode(payload),
  };
  return Uint8List.fromList(utf8.encode(jsonEncode(raiz)));
}

Future<DecodificadoJwpp> decodificarJwpp(
  Uint8List bytes, {
  String? password,
}) async {
  final raiz = _parseRaiz(bytes);
  final cipher = raiz['cipher'];
  if (cipher is! Map) throw const JwppFormatoException();
  final List<int> payload;
  try {
    payload = base64Decode(raiz['payload'] as String? ?? '');
  } catch (_) {
    throw const JwppFormatoException();
  }

  final List<int> comprimido;
  switch (cipher['alg']) {
    case 'none':
      final hash = await Sha256().hash(payload);
      if (_hex(hash.bytes) != cipher['sha256']) {
        throw const JwppFormatoException(
            'El archivo está dañado (la verificación de integridad falló).');
      }
      comprimido = payload;
    case 'aes-256-gcm':
      if (password == null || password.isEmpty) {
        throw const JwppPasswordException(
            'Este archivo está cifrado: se necesita la contraseña.');
      }
      final kdf = cipher['kdf'];
      if (kdf is! Map || kdf['alg'] != 'pbkdf2-hmac-sha256') {
        throw const JwppFormatoException();
      }
      try {
        final clave = await _derivarClave(
          password,
          base64Decode(kdf['salt'] as String),
          kdf['iterations'] as int,
        );
        comprimido = await AesGcm.with256bits().decrypt(
          SecretBox(
            payload,
            nonce: base64Decode(cipher['nonce'] as String),
            mac: Mac(base64Decode(cipher['mac'] as String)),
          ),
          secretKey: clave,
          aad: _aad,
        );
      } on SecretBoxAuthenticationError {
        throw const JwppPasswordException();
      } catch (e) {
        if (e is JwppPasswordException) rethrow;
        throw const JwppFormatoException();
      }
    default:
      throw const JwppFormatoException(
          'El archivo usa un cifrado no soportado por esta versión.');
  }

  final Object? interno;
  try {
    interno = jsonDecode(utf8.decode(gzip.decode(comprimido)));
  } catch (_) {
    throw const JwppFormatoException();
  }
  if (interno is! Map || interno['hermanos'] is! List) {
    throw const JwppFormatoException();
  }

  final hermanos = <Hermano>[];
  var omitidos = 0;
  for (final o in interno['hermanos'] as List) {
    final h = _deJson(o);
    h != null ? hermanos.add(h) : omitidos++;
  }
  return DecodificadoJwpp(hermanos: hermanos, omitidos: omitidos);
}
