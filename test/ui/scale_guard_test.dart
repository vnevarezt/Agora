import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the two scales that nothing in the analyzer can see. `AppText` and
/// `AppIcon` are conventions a reviewer has to spot, and an audit found 28
/// call sites that had quietly stopped following them — including a title at
/// 21pt, a size that exists in no scale. Every violation still compiles and
/// still renders; it just renders a little apart from everything equivalent to
/// it on another screen, which is the failure the scales were introduced to
/// end. See docs/DESIGN_SYSTEM.md §4.
void main() {
  final files =
      Directory('lib/ui')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('.g.dart'))
          // The scales define themselves here; Dimens holds the layout numbers.
          .where((f) => !f.path.startsWith('lib/ui/theme/'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  /// A numeric literal anywhere in the parameter's value, not just at its
  /// head: `fontSize: isMobile ? 19 : 21` hid two of them behind a condition
  /// and read as compliant for as long as the guard only looked at the first
  /// token. Digits that are part of an identifier (`surface2`, `w600`) do not
  /// count.
  RegExp literalFor(String param) =>
      RegExp('\\b$param:[^,)\\n]*?(?<![A-Za-z0-9_.])[0-9]');

  /// Lines whose number does not belong to a scale, matched on their exact
  /// source rather than on a line number so the list cannot rot silently.
  /// Adding one is a claim that the value is derived from something else or
  /// is not ours to choose, not that the rule is inconvenient.
  const allow = {
    // Both derive from the avatar's own diameter, which is the step.
    'fontSize: size * 11.5 / Dimens.avatar,',
    'child: Icon(Icons.person_outline, size: size / 2, color: t.textMute),',
    // Google's G is drawn at the geometry the brand guidelines fix.
    'size: Size(18, 18),',
    // Known, measured and recorded as a gap rather than waved through: the
    // participant card overflows at 2x text if this goes up to the floor.
    'this.fontSize = 10,',
  };

  /// The same numbers hiding in a constructor's default value, where no call
  /// site ever writes them: `Pill` shipped every badge in the app at 10pt —
  /// under the floor the type scale calls a floor — because nobody passed a
  /// size and the guard only ever looked at what callers passed.
  RegExp defaultFor(String param) =>
      RegExp('\\bthis\\.$param = [0-9]');

  List<String> scan(RegExp pattern) {
    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (!pattern.hasMatch(line)) continue;
        if (allow.contains(line.trim())) continue;
        violations.add('${file.path}:${i + 1}: ${line.trim()}');
      }
    }
    return violations;
  }

  test('font sizes come from AppText', () {
    final violations = [
      ...scan(literalFor('fontSize')),
      ...scan(defaultFor('fontSize')),
    ];
    expect(
      violations,
      isEmpty,
      reason:
          'Use an AppText step. The free-form scale this replaced had '
          'grown to nineteen values with no rule for choosing among '
          'them.\n${violations.join('\n')}',
    );
  });

  test('icon and glyph sizes come from AppIcon', () {
    // `size:` is the spelling for Icon, AppSpinner and AppText.mono/label
    // alike, so one rule covers all of them: the number belongs to a scale,
    // not to the call site.
    final violations = [
      ...scan(literalFor('size')),
      ...scan(defaultFor('size')),
    ];
    expect(
      violations,
      isEmpty,
      reason:
          'Use an AppIcon step (or an AppText one for mono/label '
          'sizes).\n${violations.join('\n')}',
    );
  });

  test('shadows come from Elevation', () {
    // A one-off shadow is how a vocabulary of five turns into a vocabulary of
    // fifteen that nobody can name. Elevation.selectionHalo exists for the
    // ring case specifically.
    final violations = scan(RegExp(r'\bBoxShadow\('));
    expect(
      violations,
      isEmpty,
      reason: 'Use an Elevation constant.\n${violations.join('\n')}',
    );
  });
}
