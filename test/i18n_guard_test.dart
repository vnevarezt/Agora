import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the rule that makes the language switch actually work in the UI.
///
/// slang exposes two accessors (lib/i18n/strings.g.dart):
///
///   * the global `t`  — a plain getter over the current translations. It
///     returns the right strings, but registers NO dependency.
///   * `context.t`     — reads the `InheritedLocaleData`, which subscribes the
///     widget so it rebuilds when the locale changes.
///
/// The tree is insulated by `const` barriers (`main.dart` passes a
/// `const ProviderScope`, `app.dart` a `const AuthGate`), so on a locale change
/// `Element.updateChild` short-circuits on those identical widgets and the
/// subtree below is never walked. Only registered dependents get rebuilt —
/// which means a widget reading the global `t` keeps rendering the previous
/// language until something unrelated happens to dirty it. That was issue #10.
///
/// Outside the widget layer (providers, models, pure helpers) the global `t` is
/// fine and expected; the helpers there take a `Translations` parameter so the
/// caller stays the one holding the subscription.
void main() {
  /// Files under lib/ui/ that legitimately read the global `t`, with the reason.
  /// Keep this list short — each entry is a widget that will NOT re-render on a
  /// language change.
  const allowed = <String, String>{
    'lib/ui/picker/person_picker.dart':
        'ModalRoute.barrierLabel has no BuildContext; read once by the a11y '
            'layer when the route is pushed, so it cannot go stale on screen.',
  };

  test('lib/ui/ uses context.t, never the global t', () {
    final catalog = jsonDecode(
      File('lib/i18n/es.i18n.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    // Only top-level translation groups: `t.text` / `t.accent` in the UI are
    // the `context.tokens` alias, not translations.
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
