import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps docs/DESIGN_SYSTEM.md honest.
///
/// The document restates values that live in code — every colour, every step
/// of every scale, every duration, every breakpoint. Between 2026-08-16 and
/// 2026-08-29 twenty-one of those cells went stale without anything noticing:
/// the palette moved twice and §3 kept describing the one from before the app
/// had a logo. A reader has no way to tell a current value from a fossil, so
/// the most concrete part of the document was also its least trustworthy.
///
/// This reads the constants out of the source and asserts that the document
/// says the same thing. It does not parse the tables — it only requires that
/// *some* line naming a constant also carries its value, which is tolerant of
/// prose and layout while still catching the failure that actually happened.
void main() {
  final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
  final lines = doc.split('\n');

  /// Lines that mention `name` in backticks — the document's own spelling for
  /// a code identifier. Backticks are what keep `accent` from matching
  /// `accentStrong`.
  List<String> mentioning(String name) =>
      lines.where((l) => l.contains('`$name`')).toList();

  void expectDocumented(String name, String value, String where) {
    final found = mentioning(name);
    expect(found, isNotEmpty,
        reason: '$where.$name is not mentioned in DESIGN_SYSTEM.md at all. '
            'A constant the document does not name is a constant nobody can '
            'look up.');
    expect(found.any((l) => l.contains(value)), isTrue,
        reason: 'DESIGN_SYSTEM.md names `$name` but never gives its current '
            'value $value. The code is the source — fix the document.\n'
            '${found.map((l) => '  $l').join('\n')}');
  }

  String source(String path) => File(path).readAsStringSync();

  // ---- colours ------------------------------------------------------------

  /// `name: Color(0xFFRRGGBB),` inside one scheme of the palette.
  Map<String, String> colorsIn(String block) {
    final re = RegExp(r'(\w+): Color\(0x[Ff][Ff]([0-9A-Fa-f]{6})\)');
    return {
      for (final m in re.allMatches(block))
        m.group(1)!: '#${m.group(2)!.toUpperCase()}',
    };
  }

  /// The body of `light: AppTokens(…)` / `dark: AppTokens(…)` in the palette.
  /// Scanned to the matching paren rather than the first `),`, which every
  /// `Color(0xFF…),` inside would otherwise satisfy.
  String scheme(String src, String key) {
    final open = src.indexOf('$key: AppTokens(');
    expect(open, isNot(-1), reason: 'pizarra has no $key scheme any more');
    var depth = 0;
    for (var i = src.indexOf('(', open); i < src.length; i++) {
      if (src[i] == '(') depth++;
      if (src[i] == ')') {
        depth--;
        if (depth == 0) return src.substring(open, i);
      }
    }
    fail('pizarra.$key has an unbalanced argument list');
  }

  test('every palette colour in the document is the one in the code', () {
    final src = source('lib/ui/theme/tokens.dart');
    final light = colorsIn(scheme(src, 'light'));
    final dark = colorsIn(scheme(src, 'dark'));

    expect(light.keys.toSet(), dark.keys.toSet(),
        reason: 'the two schemes must carry the same roles');
    expect(light, isNotEmpty);

    for (final role in light.keys) {
      expectDocumented(role, light[role]!, 'pizarra.light');
      expectDocumented(role, dark[role]!, 'pizarra.dark');
    }
  });

  test('the S-140 band colours match kSectionColors', () {
    final src = source('lib/ui/theme/dimens.dart');
    final map = src.substring(src.indexOf('kSectionColors'));
    for (final m
        in RegExp(r'Section\.(\w+): Color\(0x[Ff][Ff]([0-9A-Fa-f]{6})\)')
            .allMatches(map)) {
      final hex = '#${m.group(2)!.toUpperCase()}';
      expect(doc.contains(hex), isTrue,
          reason: 'kSectionColors[${m.group(1)}] is $hex, which appears '
              'nowhere in DESIGN_SYSTEM.md §3.4');
    }
  });

  test('the brand inks match the ones the mark paints', () {
    final src = source('lib/ui/widgets/agora_mark.dart');
    for (final m in RegExp(r'static const Color (\w+) = '
            r'Color\(0x[Ff][Ff]([0-9A-Fa-f]{6})\)')
        .allMatches(src)) {
      final hex = '#${m.group(2)!.toUpperCase()}';
      expect(doc.contains(hex), isTrue,
          reason: '_Mark.${m.group(1)} is $hex, which appears nowhere in '
              'DESIGN_SYSTEM.md §3.5');
    }
  });

  // ---- numeric scales -----------------------------------------------------

  /// `static const double name = 12.5;` inside one class of a file.
  Map<String, String> doublesIn(String src, String className) {
    final start = src.indexOf('class $className {');
    expect(start, isNot(-1), reason: '$className is gone');
    var depth = 0;
    var end = start;
    for (var i = src.indexOf('{', start); i < src.length; i++) {
      if (src[i] == '{') depth++;
      if (src[i] == '}') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    final body = src.substring(start, end);
    return {
      for (final m
          in RegExp(r'static const double (\w+) = ([\d.]+);').allMatches(body))
        m.group(1)!: m.group(2)!,
    };
  }

  for (final scale in [
    (file: 'lib/ui/theme/app_theme.dart', name: 'AppText'),
    (file: 'lib/ui/theme/app_theme.dart', name: 'AppIcon'),
    (file: 'lib/ui/theme/dimens.dart', name: 'Dimens'),
  ]) {
    test('${scale.name} matches the document', () {
      final steps = doublesIn(source(scale.file), scale.name);
      expect(steps, isNotEmpty);
      steps.forEach((name, value) => expectDocumented(name, value, scale.name));
    });
  }

  test('the spacing scale in the document is the one in Space', () {
    final steps = doublesIn(source('lib/ui/theme/dimens.dart'), 'Space');
    final written = steps.values.join(' · ');
    expect(doc.contains(written), isTrue,
        reason: 'Space is $written; §5.1 lists something else. The steps are '
            'written as a run of magnitudes because spacing has no roles, so '
            'the document has to carry the run verbatim.');
  });

  // ---- motion -------------------------------------------------------------

  test('every duration on the Motion scale is documented at its value', () {
    final src = source('lib/ui/widgets/motion.dart');
    final durations = {
      for (final m in RegExp(r'static const Duration (\w+) = '
              r'Duration\(milliseconds: (\d+)\)')
          .allMatches(src))
        m.group(1)!: m.group(2)!,
    };
    expect(durations, isNotEmpty);
    durations.forEach((name, ms) => expectDocumented(name, ms, 'Motion'));

    for (final m
        in RegExp(r'static const double (\w+) = (\.\d+);').allMatches(src)) {
      expectDocumented(m.group(1)!, m.group(2)!, 'Motion');
    }
  });

  test('the one curve the document quotes is the one Motion defines', () {
    final src = source('lib/ui/widgets/motion.dart');
    for (final m in RegExp(r'static const Curve (\w+) = (Cubic\([^)]*\))')
        .allMatches(src)) {
      expectDocumented(m.group(1)!, m.group(2)!, 'Motion');
    }
  });

  // ---- layout -------------------------------------------------------------

  test('breakpoints and container queries match responsive.dart', () {
    final src = source('lib/ui/responsive.dart');
    for (final m in RegExp(r'const double k(Mobile|Tablet)Breakpoint = (\d+);')
        .allMatches(src)) {
      expect(doc.contains(m.group(2)!), isTrue,
          reason: 'the ${m.group(1)!.toLowerCase()} breakpoint is '
              '${m.group(2)}, which §8 does not mention');
    }
    for (final v
        in doublesIn(src, 'ContainerWidth').values) {
      expect(doc.contains(v), isTrue,
          reason: 'a ContainerWidth threshold of $v is missing from §8');
    }
  });
}
