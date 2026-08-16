import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widgets of ours whose name matches the AnimatedFoo shape but which hand
/// [Motion.curve] to the implicit animation inside them. Adding one here is a
/// claim that the widget cannot animate linearly, not that the rule is
/// inconvenient.
const _ownsItsCurve = {'AnimatedInk('};

/// Blanks out `//` comments and `/* */` blocks, keeping the source's length
/// and line structure so offsets still line up.
String _withoutComments(String src) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < src.length) {
    if (src.startsWith('//', i)) {
      while (i < src.length && src[i] != '\n') {
        buffer.write(' ');
        i++;
      }
    } else if (src.startsWith('/*', i)) {
      final end = src.indexOf('*/', i + 2);
      final stop = end == -1 ? src.length : end + 2;
      for (; i < stop; i++) {
        buffer.write(src[i] == '\n' ? '\n' : ' ');
      }
    } else {
      buffer.write(src[i]);
      i++;
    }
  }
  return buffer.toString();
}

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
      // Comments are stripped first. A doc comment quoting the spelling it
      // exists to warn against — which is exactly what MotionSize's does —
      // reads to the regex as a violation, and rewording good prose to get
      // past a lint is the wrong end to fix it from.
      final src = _withoutComments(file.readAsStringSync());
      for (final m in ctor.allMatches(src)) {
        final args = _arguments(src, m.end - 1);
        if (args == null) continue;
        // AnimatedBuilder takes no duration at all, and AnimatedSwitcher
        // names its curves differently; the rule is about the widgets that
        // interpolate for us.
        if (!args.contains('duration:')) continue;
        if (args.contains('switchInCurve')) continue;
        if (args.contains('curve:')) continue;
        // Our own animated widgets fix Motion.curve internally and take no
        // curve, on purpose: the point of wrapping is that the call site
        // cannot get it wrong. Only widgets that would otherwise run linear
        // are in scope here.
        if (_ownsItsCurve.contains(m.group(0))) continue;
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
