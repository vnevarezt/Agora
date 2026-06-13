import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/models/hermano.dart';

Hermano hermano(
  String id,
  String nombre, {
  Sexo sexo = Sexo.hombre,
  Privilegio privilegio = Privilegio.publicador,
  bool activo = true,
  DateTime? updatedAt,
  DateTime? ultimoUso,
}) {
  final t = DateTime.utc(2026, 6, 1);
  return Hermano(
    id: id,
    nombre: nombre,
    sexo: sexo,
    privilegio: privilegio,
    congregacion: 'CONSTITUCIÓN J.A CASTRO',
    activo: activo,
    notas: '',
    createdAt: t,
    updatedAt: updatedAt ?? t,
    ultimoUso: ultimoUso,
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('upsert + watchTodos ordena por nombre', () async {
    await db.hermanosDao.upsert(hermano('b', 'Raúl Espinoza'));
    await db.hermanosDao.upsert(hermano('a', 'Daniel Ortega'));
    final lista = await db.hermanosDao.watchTodos().first;
    expect(lista.map((h) => h.nombre).toList(),
        ['Daniel Ortega', 'Raúl Espinoza']);
  });

  test('upsert con mismo id actualiza en lugar de duplicar', () async {
    await db.hermanosDao.upsert(hermano('a', 'Daniel'));
    await db.hermanosDao
        .upsert(hermano('a', 'Daniel Ortega', privilegio: Privilegio.anciano));
    final lista = await db.hermanosDao.todos();
    expect(lista, hasLength(1));
    expect(lista.single.nombre, 'Daniel Ortega');
    expect(lista.single.privilegio, Privilegio.anciano);
  });

  test('marcarUso toca ultimoUso pero NO updatedAt (clave de la fusión)',
      () async {
    final original = hermano('a', 'Daniel');
    await db.hermanosDao.upsert(original);
    final uso = DateTime.utc(2026, 6, 10, 18);
    await db.hermanosDao.marcarUso('a', uso);
    final h = (await db.hermanosDao.todos()).single;
    expect(h.ultimoUso, uso);
    expect(h.updatedAt, original.updatedAt);
  });

  test('setActivo false lo saca de los activos y actualiza updatedAt',
      () async {
    await db.hermanosDao.upsert(hermano('a', 'Daniel'));
    await db.hermanosDao.upsert(hermano('b', 'Raúl'));
    final cuando = DateTime.utc(2026, 6, 11);
    await db.hermanosDao.setActivo('a', false, cuando);
    final todos = await db.hermanosDao.todos();
    expect(todos.where((h) => h.activo).map((h) => h.id), ['b']);
    expect(todos.firstWhere((h) => h.id == 'a').updatedAt, cuando);
  });

  test('eliminar borra definitivamente', () async {
    await db.hermanosDao.upsert(hermano('a', 'Daniel'));
    await db.hermanosDao.eliminar('a');
    expect(await db.hermanosDao.contar(), 0);
  });

  test('bulkUpsert mezcla nuevos y existentes', () async {
    await db.hermanosDao.upsert(hermano('a', 'Daniel'));
    await db.hermanosDao.bulkUpsert([
      hermano('a', 'Daniel Ortega'),
      hermano('b', 'Raúl Espinoza'),
    ]);
    final lista = await db.hermanosDao.todos();
    expect(lista, hasLength(2));
    expect(lista.map((h) => h.nombre),
        containsAll(['Daniel Ortega', 'Raúl Espinoza']));
  });

  test('reemplazarTodo deja exactamente el contenido importado', () async {
    await db.hermanosDao.upsert(hermano('a', 'Daniel'));
    await db.hermanosDao.upsert(hermano('b', 'Raúl'));
    await db.hermanosDao.reemplazarTodo([hermano('c', 'Saúl Bravo')]);
    final lista = await db.hermanosDao.todos();
    expect(lista.map((h) => h.id), ['c']);
  });

  test('ultimoUso nullable se conserva en round-trip', () async {
    final uso = DateTime.utc(2026, 6, 9, 19, 30);
    await db.hermanosDao.upsert(hermano('a', 'Daniel', ultimoUso: uso));
    await db.hermanosDao.upsert(hermano('b', 'Raúl'));
    final lista = await db.hermanosDao.todos();
    expect(lista.firstWhere((h) => h.id == 'a').ultimoUso, uso);
    expect(lista.firstWhere((h) => h.id == 'b').ultimoUso, isNull);
  });
}
