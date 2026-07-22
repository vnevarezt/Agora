import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/state/program_form.dart';

void main() {
  group('sheetWeekIndices', () {
    test('single-per-sheet returns just the (clamped) active week', () {
      expect(sheetWeekIndices(3, 6, false), [3]);
      expect(sheetWeekIndices(0, 6, false), [0]);
      expect(sheetWeekIndices(9, 6, false), [5]); // clamps into range
    });

    test('two-per-sheet groups aligned even pairs', () {
      expect(sheetWeekIndices(0, 6, true), [0, 1]);
      expect(sheetWeekIndices(2, 6, true), [2, 3]);
      // An odd active week prints with its even partner, never the next pair,
      // so exporting every sheet never repeats a week.
      expect(sheetWeekIndices(3, 6, true), [2, 3]);
    });

    test('two-per-sheet: a trailing odd week prints alone', () {
      expect(sheetWeekIndices(4, 5, true), [4]); // no week 5 to pair with
    });

    test('empty notebook yields no sheets', () {
      expect(sheetWeekIndices(0, 0, true), isEmpty);
      expect(sheetWeekIndices(0, 0, false), isEmpty);
    });
  });
}
