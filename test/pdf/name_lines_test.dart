// How a slot's two names are laid out, and above all in what order.
//
// The renderer used to decide this inline with hand-written indices, and had
// them backwards in the stacked branch: the same pair printed student-first
// when it fitted on one line and assistant-first when it did not. Two weeks per
// sheet made it the normal case, because the names column there is narrow
// enough that almost every pair stacks.

import 'package:flutter_test/flutter_test.dart';

import 'package:agora/i18n/strings.g.dart';
import 'package:agora/models/program_row.dart';
import 'package:agora/pdf/column_layout.dart';

/// Stands in for the font metrics: one unit per character.
double _measure(String s) => s.length.toDouble();

void main() {
  const student = 'Maximiliano';
  const assistant = 'Bartolomea';
  const pair = [student, assistant];

  test('a pair that fits prints on one line, student first', () {
    final layout = nameLines(SlotRole.studentAssistant, pair, 1000, _measure);

    expect(layout.stacked, isFalse);
    expect(layout.lines.single, '$student / $assistant');
  });

  test('a pair that does not fit stacks in the SAME order', () {
    final layout = nameLines(SlotRole.studentAssistant, pair, 5, _measure);

    expect(layout.stacked, isTrue);
    expect(layout.lines, [student, assistant],
        reason: 'stacking is a line break, not a reordering');
  });

  test('both forms agree on who comes first', () {
    // The property the bug broke, stated directly: the column width decides
    // how the names are broken, never which one leads.
    final wide = nameLines(SlotRole.studentAssistant, pair, 1000, _measure);
    final narrow = nameLines(SlotRole.studentAssistant, pair, 5, _measure);

    expect(wide.lines.single.startsWith(student), isTrue);
    expect(narrow.lines.first, student);
  });

  test('the order matches the role label the cell sits next to', () {
    // The names have to read in the order the label promises, in whichever
    // language the sheet is printed. If the label is ever reordered, this is
    // what says the names must move with it.
    expect(SlotRole.studentAssistant.label(AppLocale.es.buildSync()),
        'Estudiante/Ayudante:');
    expect(SlotRole.studentAssistant.label(AppLocale.en.buildSync()),
        startsWith('Student'));
  });

  test('a single name never stacks, whatever the width', () {
    final layout = nameLines(SlotRole.student, const [student], 1, _measure);

    expect(layout.stacked, isFalse);
    expect(layout.lines.single, student);
  });

  test('a pair role with only one name stays on one line', () {
    final layout =
        nameLines(SlotRole.studentAssistant, const [student], 1, _measure);

    expect(layout.stacked, isFalse,
        reason: 'there is nothing to stack against');
    expect(layout.lines.single, student);
  });
}
