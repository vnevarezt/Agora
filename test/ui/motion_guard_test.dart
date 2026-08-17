import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the three rules that keep the app's motion homogeneous. They are
/// easy to state and easy to forget, and nothing in the analyzer catches them
/// — every violation still compiles and still animates, just not like the rest
/// of the app. See lib/ui/widgets/motion.dart.
void main() {
  final files = Directory('lib/ui')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  const motion = 'lib/ui/widgets/motion.dart';

  test('implicit animations pass a curve', () {
    // AnimatedFoo defaults to Curves.linear: constant speed from a standing
    // start to a dead stop. Nothing physical moves that way, and it is what
    // made the hover and press states read as mechanical.
    final ctor = RegExp(r'\bAnimated[A-Z]\w*\(');
    final violations = <String>[];

    for (final file in files) {
      final src = file.readAsStringSync();
      for (final m in ctor.allMatches(src)) {
        final args = _arguments(src, m.end - 1);
        if (args == null) continue;
        // AnimatedBuilder takes no duration at all, and AnimatedSwitcher
        // names its curves differently; the rule is about the widgets that
        // interpolate for us.
        if (!args.contains('duration:')) continue;
        if (args.contains('switchInCurve')) continue;
        if (args.contains('curve:')) continue;
        violations.add('${file.path}: ${m.group(0)}');
      }
    }

    expect(violations, isEmpty,
        reason: 'Pass `curve: Motion.curve` alongside the duration — without '
            'it the widget animates linearly.\n${violations.join('\n')}');
  });

  test('curves come from Motion, never from Curves', () {
    final violations = <String>[];
    for (final file in files) {
      if (file.path == motion) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (lines[i].contains('Curves.')) {
          violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(violations, isEmpty,
        reason: 'Use `Motion.curve` / `Motion.curveOut`. One ease-out for the '
            'whole app; overshoot belongs to gestures that carried momentum, '
            'and we have none.\n${violations.join('\n')}');
  });

  test('animation timings come from the Motion scale', () {
    // A literal here is both off the scale and, more importantly, opaque to
    // `Motion.of` — so it keeps animating under Reduce Motion.
    final literal = RegExp(
      r'\b(duration|delay|transitionDuration|animationDuration|reverseDuration)'
      r':\s*(const\s+)?Duration\(',
    );
    final violations = <String>[];

    for (final file in files) {
      if (file.path == motion) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (literal.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(violations, isEmpty,
        reason: 'Use `Motion.of(context, Motion.<step>)`, or `Motion.stagger` '
            'for entrance delays.\n${violations.join('\n')}');
  });
}

/// The text between the parenthesis at [open] and its match, or null if the
/// source is unbalanced. Good enough for an argument list: strings in this
/// codebase do not carry stray parens, and a false positive shows up as a
/// failing guard rather than as a silent pass.
String? _arguments(String src, int open) {
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    if (src[i] == '(') depth++;
    if (src[i] == ')') {
      depth--;
      if (depth == 0) return src.substring(open + 1, i);
    }
  }
  return null;
}
