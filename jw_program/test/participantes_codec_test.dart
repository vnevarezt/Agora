import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/data/participantes_codec.dart';
import 'package:jw_program/models/hermano.dart';

// Iteraciones bajas: PBKDF2 a 210k tardaría segundos por test.
const _iter = 1000;

List<Hermano> _muestra() => [
      Hermano(
        id: 'a',
        nombre: 'Raúl Espinoza',
        sexo: Sexo.hombre,
        privilegio: Privilegio.anciano,
        congregacion: 'CONSTITUCIÓN J.A CASTRO',
        activo: true,
        notas: 'Oración de apertura',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 6, 1),
        ultimoUso: DateTime.utc(2026, 6, 10, 18, 30),
      ),
      Hermano(
        id: 'b',
        nombre: 'Ana López',
        sexo: Sexo.mujer,
        privilegio: Privilegio.publicador,
        congregacion: '',
        activo: false,
        notas: '',
        createdAt: DateTime.utc(2026, 2, 2),
        updatedAt: DateTime.utc(2026, 2, 2),
      ),
    ];

void main() {
  test('round-trip sin contraseña conserva todos los campos', () async {
    final bytes = await codificarJwpp(_muestra());
    final info = leerCabeceraJwpp(bytes);
    expect(info.cifrado, isFalse);
    expect(info.total, 2);
    expect(info.congregaciones, ['CONSTITUCIÓN J.A CASTRO']);

    final dec = await decodificarJwpp(bytes);
    expect(dec.omitidos, 0);
    expect(dec.hermanos, hasLength(2));
    final a = dec.hermanos.firstWhere((h) => h.id == 'a');
    expect(a.nombre, 'Raúl Espinoza');
    expect(a.privilegio, Privilegio.anciano);
    expect(a.ultimoUso, DateTime.utc(2026, 6, 10, 18, 30));
    final b = dec.hermanos.firstWhere((h) => h.id == 'b');
    expect(b.activo, isFalse);
    expect(b.sexo, Sexo.mujer);
  });

  test('round-trip con contraseña + cabecera sin resumen', () async {
    final bytes = await codificarJwpp(_muestra(),
        password: 'secreta123', iteraciones: _iter);
    final info = leerCabeceraJwpp(bytes);
    expect(info.cifrado, isTrue);
    expect(info.total, isNull); // el resumen no va en claro
    expect(info.congregaciones, isEmpty);
    // el nombre no debe aparecer en claro en el archivo
    expect(utf8.decode(bytes).contains('Raúl'), isFalse);

    final dec =
        await decodificarJwpp(bytes, password: 'secreta123');
    expect(dec.hermanos, hasLength(2));
  });

  test('contraseña incorrecta → JwppPasswordException', () async {
    final bytes = await codificarJwpp(_muestra(),
        password: 'secreta123', iteraciones: _iter);
    expect(
      () => decodificarJwpp(bytes, password: 'otra'),
      throwsA(isA<JwppPasswordException>()),
    );
  });

  test('archivo cifrado sin contraseña → JwppPasswordException', () async {
    final bytes = await codificarJwpp(_muestra(),
        password: 'secreta123', iteraciones: _iter);
    expect(
      () => decodificarJwpp(bytes),
      throwsA(isA<JwppPasswordException>()),
    );
  });

  test('byte alterado en payload cifrado → excepción amistosa', () async {
    final bytes = await codificarJwpp(_muestra(),
        password: 'secreta123', iteraciones: _iter);
    final raiz = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    final payload = base64Decode(raiz['payload'] as String);
    payload[payload.length ~/ 2] ^= 0xFF;
    raiz['payload'] = base64Encode(payload);
    final corrupto = Uint8List.fromList(utf8.encode(jsonEncode(raiz)));
    expect(
      () => decodificarJwpp(corrupto, password: 'secreta123'),
      throwsA(isA<JwppPasswordException>()),
    );
  });

  test('byte alterado sin cifrado → falla la integridad', () async {
    final bytes = await codificarJwpp(_muestra());
    final raiz = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    final payload = base64Decode(raiz['payload'] as String);
    payload[payload.length ~/ 2] ^= 0xFF;
    raiz['payload'] = base64Encode(payload);
    final corrupto = Uint8List.fromList(utf8.encode(jsonEncode(raiz)));
    expect(
      () => decodificarJwpp(corrupto),
      throwsA(isA<JwppFormatoException>()),
    );
  });

  test('versión futura → JwppVersionException', () async {
    final bytes = await codificarJwpp(_muestra());
    final raiz = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    raiz['version'] = 99;
    final futuro = Uint8List.fromList(utf8.encode(jsonEncode(raiz)));
    expect(() => leerCabeceraJwpp(futuro),
        throwsA(isA<JwppVersionException>()));
    expect(() => decodificarJwpp(futuro),
        throwsA(isA<JwppVersionException>()));
  });

  test('basura → JwppFormatoException', () {
    expect(() => leerCabeceraJwpp(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<JwppFormatoException>()));
    expect(
        () => leerCabeceraJwpp(
            Uint8List.fromList(utf8.encode('{"format":"otro"}'))),
        throwsA(isA<JwppFormatoException>()));
  });

  test('registros inválidos y campos desconocidos se toleran', () async {
    final bytes = await codificarJwpp(_muestra());
    final raiz = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    // reconstruye el payload con un registro sin nombre y un campo extra
    final interno = {
      'hermanos': [
        {
          'id': 'c',
          'nombre': 'Saúl Bravo',
          'sexo': 'hombre',
          'privilegio': 'siervoMinisterial',
          'campoDelFuturo': {'x': 1},
          'createdAt': '2026-01-01T00:00:00Z',
          'updatedAt': '2026-01-01T00:00:00Z',
        },
        {'id': '', 'nombre': 'Sin Id'},
        {'nombre': 'Sin id tampoco'},
      ],
    };
    final gzipBytes = await _gzipJson(interno);
    raiz['payload'] = base64Encode(gzipBytes);
    (raiz['cipher'] as Map<String, Object?>)['sha256'] =
        await _sha256Hex(gzipBytes);
    final reescrito = Uint8List.fromList(utf8.encode(jsonEncode(raiz)));

    final dec = await decodificarJwpp(reescrito);
    expect(dec.hermanos.map((h) => h.id), ['c']);
    expect(dec.hermanos.single.privilegio, Privilegio.siervoMinisterial);
    expect(dec.omitidos, 2);
  });
}

Future<List<int>> _gzipJson(Object o) async =>
    gzip.encode(utf8.encode(jsonEncode(o)));

Future<String> _sha256Hex(List<int> bytes) async {
  final hash = await Sha256().hash(bytes);
  return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
