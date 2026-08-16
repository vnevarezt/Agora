import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/i18n/strings.g.dart';
import 'package:agora/ui/landing/landing_header.dart';
import 'package:agora/ui/landing/landing_layout.dart';
import 'package:agora/ui/landing/landing_page.dart';
import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';

Future<void> _pumpLanding(
  WidgetTester tester,
  VoidCallback onEnterApp, {
  Size size = const Size(1440, 900),
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: buildAppTheme(
          brightness == Brightness.light ? pizarra.light : pizarra.dark,
          brightness,
        ),
        home: LandingPage(onEnterApp: onEnterApp),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Scrolls [finder] into view and then clear of the header.
///
/// `ensureVisible` alone is not enough now that the bar floats over the page:
/// it scrolls the minimum distance, which for anything above the viewport
/// parks it at y=0 — behind the glass, where the bar swallows the tap. A real
/// visitor scrolling the page never lands there, but the harness does every
/// time.
Future<void> _revealBelowHeader(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();

  final controller = tester
      .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
      .controller!;
  final position = controller.position;
  controller.jumpTo(
    (position.pixels - LandingHeader.height - LandingSpace.s24).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders the hero, nav and CTA copy', (tester) async {
    await _pumpLanding(tester, () {});

    expect(find.text('Tú pones los nombres. Ya está.'), findsOneWidget);
    expect(find.text('Probar ahora'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Abrir Agora'), findsOneWidget);
    expect(find.text('Cómo funciona'), findsWidgets);
  });

  testWidgets('header primary CTA invokes onEnterApp', (tester) async {
    var taps = 0;
    await _pumpLanding(tester, () => taps++);

    await tester.tap(find.text('Abrir Agora'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('hero CTA invokes onEnterApp', (tester) async {
    var taps = 0;
    await _pumpLanding(tester, () => taps++);

    await tester.tap(find.text('Probar ahora'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('closing CTA invokes onEnterApp', (tester) async {
    var taps = 0;
    await _pumpLanding(tester, () => taps++);

    final cta = find.text('Abrir Agora ahora');
    await tester.ensureVisible(cta);
    await tester.pump();
    await tester.tap(cta);
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('privacy toggle swaps the comparison values', (tester) async {
    await _pumpLanding(tester, () {});

    final toggle = find.text('En equipo');
    await _revealBelowHeader(tester, toggle);

    expect(find.text('No hace falta'), findsOneWidget);
    expect(find.text('Una por congregación'), findsNothing);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('Una por congregación'), findsOneWidget);
    expect(find.text('No hace falta'), findsNothing);
  });

  testWidgets('the no-recovery warning is always reachable', (tester) async {
    await _pumpLanding(tester, () {});

    final warning = find.textContaining('no se puede recuperar');
    expect(warning, findsOneWidget);
    await tester.ensureVisible(warning);
    await tester.pump();
  });

  testWidgets('lays out without overflow on a narrow phone', (tester) async {
    await _pumpLanding(tester, () {}, size: const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without overflow at the tablet breakpoint',
      (tester) async {
    await _pumpLanding(tester, () {}, size: const Size(760, 1024));
    expect(tester.takeException(), isNull);
  });

  // The two-column sections only exist above the tablet breakpoint, so the
  // narrowest box any of their copy ever gets is on a wide window, not a
  // small one — the phone and tablet cases above cannot catch it.
  testWidgets('lays out without overflow on a desktop window', (tester) async {
    await _pumpLanding(tester, () {}, size: const Size(1280, 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in the dark theme without overflow', (tester) async {
    await _pumpLanding(tester, () {}, brightness: Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  // A Container carrying an `alignment` expands to fill any bounded width its
  // parent offers, so a badge sized that way shrink-wraps inside a Row and
  // silently stretches across the column when it is stacked. Pinned at both
  // widths because only the stacked case ever showed it.
  for (final (name, size) in [
    ('desktop', const Size(1440, 900)),
    ('phone', const Size(390, 844)),
  ]) {
    testWidgets('badges stay the width of their text on $name',
        (tester) async {
      await _pumpLanding(tester, () {}, size: size);

      final badges = find.byType(LandingBadge);
      expect(badges, findsWidgets);
      for (final badge in badges.evaluate()) {
        final width = (badge.renderObject! as RenderBox).size.width;
        expect(
          width,
          lessThan(size.width / 2),
          reason: 'a badge grew to half the viewport, so it is filling its '
              'parent rather than wrapping its label',
        );
      }
    });
  }
}
