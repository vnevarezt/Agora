import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/domain/fusion_hermanos.dart';
import 'package:jw_program/models/hermano.dart';

Hermano _h(
  String id,
  String nombre, {
  DateTime? updatedAt,
  DateTime? ultimoUso,
}) {
  final t = DateTime.utc(2026, 6, 1);
  return Hermano(
    id: id,
    nombre: nombre,
    sexo: Sexo.hombre,
    privilegio: Privilegio.publicador,
    congregacion: 'TEST',
    activo: true,
    notas: '',
    createdAt: t,
    updatedAt: updatedAt ?? t,
    ultimoUso: ultimoUso,
  );
}

void main() {
  final t1 = DateTime.utc(2026, 6, 5);
  final t2 = DateTime.utc(2026, 6, 9);

  test('entrante con id desconocido = nuevo', () {
    final plan = planFusion([_h('a', 'Daniel')], [_h('b', 'Raúl')]);
    expect(plan.nuevos, 1);
    expect(plan.actualizados, 0);
    expect(plan.iguales, 0);
    expect(plan.resultado.map((h) => h.id), containsAll(['a', 'b']));
  });

  test('gana el updatedAt más reciente', () {
    final plan = planFusion(
      [_h('a', 'Daniel', updatedAt: t1)],
      [_h('a', 'Daniel Ortega', updatedAt: t2)],
    );
    expect(plan.actualizados, 1);
    expect(plan.resultado.single.nombre, 'Daniel Ortega');
  });

  test('el local más reciente no se pisa', () {
    final plan = planFusion(
      [_h('a', 'Daniel Ortega', updatedAt: t2)],
      [_h('a', 'Daniel', updatedAt: t1)],
    );
    expect(plan.iguales, 1);
    expect(plan.resultado.single.nombre, 'Daniel Ortega');
  });

  test('ultimoUso se conserva como el máximo de ambos lados', () {
    final usoLocal = DateTime.utc(2026, 6, 10);
    final usoEntrante = DateTime.utc(2026, 6, 8);
    final plan = planFusion(
      [_h('a', 'Daniel', updatedAt: t1, ultimoUso: usoLocal)],
      [_h('a', 'Daniel Ortega', updatedAt: t2, ultimoUso: usoEntrante)],
    );
    // gana el entrante (más editado) pero con el uso máximo (el local)
    expect(plan.resultado.single.nombre, 'Daniel Ortega');
    expect(plan.resultado.single.ultimoUso, usoLocal);
  });

  test('los locales que no vienen en el archivo se conservan', () {
    final plan = planFusion(
      [_h('a', 'Daniel'), _h('b', 'Raúl')],
      [_h('a', 'Daniel')],
    );
    expect(plan.resultado, hasLength(2));
  });
}
