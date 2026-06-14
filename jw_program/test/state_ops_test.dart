import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/models/program_row.dart';
import 'package:jw_program/state/assignment_ops.dart';
import 'package:jw_program/state/program_form.dart';

void main() {
  group('listWithName', () {
    test('rellena hasta el nº de slots y coloca el nombre en su posición',
        () {
      expect(listWithName(null, 2, 0, 'Ana'), ['Ana', '']);
      expect(listWithName(null, 2, 1, 'Luis'), ['', 'Luis']);
    });

    test('conserva los demás valores existentes', () {
      expect(listWithName(['Ana', 'Luis'], 2, 1, 'Eva'), ['Ana', 'Eva']);
    });

    test('limpiar = escribir cadena vacía', () {
      expect(listWithName(['Ana', 'Luis'], 2, 0, ''), ['', 'Luis']);
    });
  });

  group('SlotRef', () {
    const fila = ProgramRow(
        id: 'se1', hora: '18:31', contenido: 'Demostración', slots: 2);

    test('claves estables para principal y auxiliar', () {
      expect(const ChairmanSlot().key, 'presidente');
      expect(const RowSlot(fila, 0).key, 'se1:0');
      expect(const RowSlot(fila, 1, aux: true).key, 'se1:aux:1');
    });

    test('igualdad por clave (instancias recreadas en cada build)', () {
      expect(const RowSlot(fila, 0), const RowSlot(fila, 0));
      expect(const RowSlot(fila, 0) == const RowSlot(fila, 0, aux: true),
          isFalse);
    });
  });

  group('slotName / filledNames', () {
    const fila = ProgramRow(
        id: 'te0', hora: '18:06', contenido: 'Discurso', slots: 1);

    test('lee del mapa correcto y tolera listas cortas', () {
      final f = FormModel.inicial.copyWith(
        presidente: 'Andrés',
        principal: {
          'te0': ['Daniel'],
        },
      );
      expect(slotName(f, const ChairmanSlot()), 'Andrés');
      expect(slotName(f, const RowSlot(fila, 0)), 'Daniel');
      expect(slotName(f, const RowSlot(fila, 0, aux: true)), '');
    });

    test('cuenta solo entradas no vacías dentro del nº de slots', () {
      expect(filledNames(null, 2), 0);
      expect(filledNames(['Ana', ''], 2), 1);
      expect(filledNames(['Ana', 'Luis'], 2), 2);
      expect(filledNames(['  '], 1), 0);
    });
  });
}
