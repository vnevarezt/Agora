import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The global `t` registers no dependency, and `const` barriers in main.dart /
/// app.dart stop a locale change from walking the tree — so a widget reading it
/// keeps the previous language until something unrelated dirties it (issue #10).
/// Outside the widget layer it is fine; see lib/i18n/README.md.
void main() {
  /// Each entry is a widget that will NOT re-render on a language change.
  /// Keep it short.
  const allowed = <String, String>{
    'lib/ui/picker/person_picker.dart':
        'ModalRoute.barrierLabel has no BuildContext; read once by the a11y '
            'layer when the route is pushed, so it cannot go stale on screen.',
  };

  test('lib/ui/ uses context.t, never the global t', () {
    final catalog = jsonDecode(
      File('lib/i18n/es.i18n.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    // Top-level groups only: `t.text` / `t.accent` are the tokens alias.
    final groups = catalog.keys.toList()..sort();
    final offender = RegExp(r'(?<![\w.])t\.(' + groups.join('|') + r')\b');

    final violations = <String>[];
    final files = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'));

    for (final file in files) {
      if (allowed.containsKey(file.path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (offender.hasMatch(line)) {
          violations.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Use `context.t` in widgets so they rebuild when the language '
          'changes. For code with no BuildContext, take a `Translations` '
          'parameter instead. See lib/i18n/README.md.\n'
          '${violations.join('\n')}',
    );
  });

  test('every allowlisted file still exists', () {
    for (final path in allowed.keys) {
      expect(File(path).existsSync(), isTrue,
          reason: '$path is allowlisted in this guard but no longer exists — '
              'drop the entry.');
    }
  });
}
