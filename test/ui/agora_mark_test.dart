import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/agora_mark.dart';
import 'package:agora/ui/widgets/motion.dart';

/// The mark exists twice: `tool/gen_brand_assets.py` renders every file under
/// assets/brand/ — the app icons, the favicon, the store art — and
/// lib/ui/widgets/agora_mark.dart paints the same drawing so the entrance can
/// take it apart. Nothing but this test keeps the two on the same numbers, and
/// drift between them is invisible in review: it ships as an app whose logo is
/// subtly not the logo in the stores.

List<double> _numbers(String source) => RegExp(
  r'-?\d+(?:\.\d+)?',
).allMatches(source).map((m) => double.parse(m.group(0)!)).toList();

String _capture(String source, String pattern, {bool line = false}) {
  final match = RegExp(
    pattern,
    multiLine: line,
    dotAll: !line,
  ).firstMatch(source);
  expect(match, isNotNull, reason: 'nothing matched /$pattern/');
  return match!.group(1)!;
}

void main() {
  final py = File('tool/gen_brand_assets.py').readAsStringSync();
  final dart = File('lib/ui/widgets/agora_mark.dart').readAsStringSync();

  /// The generator declares each value on one line. Its trailing comment is
  /// dropped so prose cannot pass for geometry — on ` # ` rather than on `#`,
  /// which would also cut the hex colours in half.
  String generator(String name) => _capture(
    py,
    '^$name = (.*)\$',
    line: true,
  ).split(RegExp(r'\s+#\s')).first;

  test('the planes are the ones the generator draws', () {
    expect(
      _numbers(_capture(dart, r'List<Offset> back = \[(.*?)\];')),
      _numbers(generator('BACK')),
    );
    expect(
      _numbers(_capture(dart, r'List<Offset> front = \[(.*?)\];')),
      _numbers(generator('FRONT')),
    );
    expect(
      _numbers(_capture(dart, r'art = Rect\.fromLTWH\((.*?)\);')),
      _numbers(generator('ART')),
    );
  });

  test('the inks are the ones the generator fills with', () {
    String ink(String name) =>
        _capture(dart, '$name = Color\\(0xFF([0-9A-F]{6})\\)').toLowerCase();
    List<String> palette(String name) => RegExp(
      '#([0-9a-f]{6})',
    ).allMatches(generator(name)).map((m) => m.group(1)!).toList();

    expect([ink('inkBackOnLight'), ink('inkFront')], palette('ON_LIGHT'));
    expect(ink('inkBackOnDark'), palette('ON_DARK').first);
    expect(
      [ink('wordOnLight'), ink('wordOnDark')],
      palette('WORDMARK_INK'),
      reason:
          'the lockup is built live in the app and rendered by the '
          'generator for the stores; both have to reach the same word',
    );
  });

  Widget host(Widget child, {bool reduceMotion = false}) => MaterialApp(
    theme: buildAppTheme(pizarra.light, Brightness.light),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('the entrance settles within Motion.focal', (tester) async {
    var settled = false;
    await tester.pumpWidget(
      host(AgoraMarkEntrance(onEnd: () => settled = true)),
    );
    // The ticker's clock only starts on the frame after the one that built
    // it, so the entrance is measured from here rather than from pumpWidget.
    await tester.pump();
    await tester.pump(Motion.focal ~/ 2);
    expect(settled, isFalse);
    await tester.pump(Motion.focal);
    expect(settled, isTrue);
  });

  testWidgets('the loader keeps turning under Reduce Motion', (tester) async {
    // The one animation in the app the setting does not stop: an indeterminate
    // indicator is the state, not decoration on top of one, and freezing it
    // says the work finished. See Motion.loop.
    await tester.pumpWidget(host(const AgoraLoader(), reduceMotion: true));
    await tester.pump();
    await tester.pump(Motion.loop);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('the loader takes one ink for filled grounds', (tester) async {
    await tester.pumpWidget(host(const AgoraLoader(color: Color(0xFFFFFFFF))));
    await tester.pump(Motion.loop ~/ 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduce Motion arrives settled and still reports it', (
    tester,
  ) async {
    var settled = false;
    await tester.pumpWidget(
      host(AgoraMarkEntrance(onEnd: () => settled = true), reduceMotion: true),
    );
    await tester.pump();
    expect(settled, isTrue);
  });
}
