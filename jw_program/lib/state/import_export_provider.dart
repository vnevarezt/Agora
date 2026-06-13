import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/participantes_codec.dart';
import '../domain/fusion_hermanos.dart';
import '../models/hermano.dart';
import 'db_provider.dart';

/// Operación de import/export en curso (deshabilita los botones).
final personasIoBusyProvider =
    NotifierProvider<PersonasIoBusyController, bool>(
        PersonasIoBusyController.new);

class PersonasIoBusyController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final participantesIoProvider =
    Provider<ParticipantesIo>(ParticipantesIo.new);

/// Import decodificado y planificado, listo para mostrar el preview y
/// aplicarse en el modo que elija el usuario.
class ImportPreparado {
  final DecodificadoJwpp decodificado;
  final PlanFusion plan;

  const ImportPreparado({required this.decodificado, required this.plan});
}

/// Orquesta codec + DAO. La criptografía corre en un isolate (`compute`):
/// PBKDF2 a 210k iteraciones tarda ~1 s en móvil y bloquearía la UI.
class ParticipantesIo {
  ParticipantesIo(this._ref);

  final Ref _ref;

  Future<(Uint8List, int)> exportarBytes({String? password}) async {
    final hermanos = await _ref.read(hermanosDaoProvider).todos();
    final bytes =
        await compute(_codificarTask, (hermanos: hermanos, password: password));
    return (bytes, hermanos.length);
  }

  Future<ImportPreparado> prepararImport(Uint8List bytes,
      {String? password}) async {
    final dec =
        await compute(_decodificarTask, (bytes: bytes, password: password));
    final locales = await _ref.read(hermanosDaoProvider).todos();
    return ImportPreparado(
      decodificado: dec,
      plan: planFusion(locales, dec.hermanos),
    );
  }

  Future<void> aplicarFusion(ImportPreparado prep) =>
      _ref.read(hermanosDaoProvider).bulkUpsert(prep.plan.resultado);

  Future<void> aplicarReemplazo(ImportPreparado prep) => _ref
      .read(hermanosDaoProvider)
      .reemplazarTodo(prep.decodificado.hermanos);

  Future<int> contarLocales() => _ref.read(hermanosDaoProvider).contar();
}

Future<Uint8List> _codificarTask(
        ({List<Hermano> hermanos, String? password}) a) =>
    codificarJwpp(a.hermanos, password: a.password);

Future<DecodificadoJwpp> _decodificarTask(
        ({Uint8List bytes, String? password}) a) =>
    decodificarJwpp(a.bytes, password: a.password);
