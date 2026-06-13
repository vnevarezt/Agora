// Verifica EN LA APP REAL (macOS) la BD cifrada: llavero del sistema,
// archivo ilegible en disco y persistencia entre procesos.
//
// Ejecutar DOS veces: flutter test integration_test/db_cifrada_test.dart -d macos
// La 1ª siembra el canario; la 2ª (proceso nuevo) debe encontrarlo
// (imprime CANARIO_EXISTIA: true) y lo elimina.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jw_program/models/hermano.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:path_provider/path_provider.dart';

const _canarioId = 'canario-db-cifrada-test';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BD cifrada: llavero + archivo ilegible + persistencia',
      (tester) async {
    await tester.runAsync(() async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dao = container.read(hermanosDaoProvider);

      final existia =
          (await dao.todos()).any((h) => h.id == _canarioId);
      // ignore: avoid_print
      print('CANARIO_EXISTIA: $existia');

      if (existia) {
        await dao.eliminar(_canarioId);
      } else {
        final ahora = DateTime.now().toUtc();
        await dao.upsert(Hermano(
          id: _canarioId,
          nombre: 'Canario Persistencia',
          sexo: Sexo.hombre,
          privilegio: Privilegio.publicador,
          congregacion: 'TEST',
          activo: true,
          notas: '',
          createdAt: ahora,
          updatedAt: ahora,
        ));
        expect((await dao.todos()).any((h) => h.id == _canarioId), isTrue);
      }

      // El archivo en disco NO debe tener la cabecera SQLite en claro.
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}hermanos.db');
      expect(file.existsSync(), isTrue);
      final cabecera = String.fromCharCodes(
          (await file.openRead(0, 15).first));
      // ignore: avoid_print
      print('CABECERA: $cabecera');
      expect(cabecera.startsWith('SQLite format'), isFalse,
          reason: 'la BD está EN CLARO: el cifrado no se aplicó');
    });
  });
}
