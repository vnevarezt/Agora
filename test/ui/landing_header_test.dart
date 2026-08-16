import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/i18n/strings.g.dart';
import 'package:agora/ui/landing/brand_mark.dart';
import 'package:agora/ui/landing/landing_back_to_top.dart';
import 'package:agora/ui/landing/landing_header.dart';
import 'package:agora/ui/landing/landing_layout.dart';
import 'package:agora/ui/landing/landing_page.dart';
import 'package:agora/ui/landing/landing_privacy.dart';
import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/dimens.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/app_button.dart';

Future<void> _pumpLanding(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: buildAppTheme(pizarra.light, Brightness.light),
        home: LandingPage(onEnterApp: () {}),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Where the page's content column ends, which is the line every section below
/// the header is already ruled to.
double _contentRightEdge(Size size, double gutter) =>
    (size.width + LandingSection.maxWidth.clamp(0, size.width)) / 2 - gutter;

void main() {
  // The header's own right edge has to be the same line the sections below it
  // end on. It was not: the brand sat in a `Flexible` with the same flex as the
  // nav's `Expanded`, so the row split its free space in half, the brand took
  // only what its text needed, and the half it did not use stranded at the end
  // of the row — pushing the actions inboard by a gap that grew with the
  // window. On a wide screen that reads as the buttons floating near the middle.
  for (final (name, size, gutter) in [
    ('desktop', const Size(1440, 900), LandingSpace.s32),
    ('wide desktop', const Size(1920, 1080), LandingSpace.s32),
  ]) {
    testWidgets('header actions end on the content column edge on $name',
        (tester) async {
      await _pumpLanding(tester, size: size);

      // Scoped to the header: the page's own CTAs are AppButtons too, and the
      // scroll view now sits before the bar in the tree.
      final button = tester.getRect(
        find.descendant(
          of: find.byType(LandingHeader),
          matching: find.byType(AppButton),
        ),
      );

      expect(
        button.right,
        moreOrLessEquals(_contentRightEdge(size, gutter), epsilon: 1),
        reason: 'the header CTA is not flush with the content column, so it '
            'floats short of the edge every section below it lines up with',
      );
    });
  }

  // The glass is only glass if the page actually passes underneath it. In a
  // column the bar would blur the gap above the content and nothing else, so
  // this pins the overlay rather than the filter: the scroll view has to reach
  // the top of the viewport and the bar has to sit over it.
  testWidgets('the page scrolls underneath the bar', (tester) async {
    await _pumpLanding(tester, size: const Size(1440, 900));

    final scroller = tester.getRect(find.byType(SingleChildScrollView).first);
    final header = tester.getRect(find.byType(LandingHeader));

    expect(scroller.top, header.top);
    expect(header.height, LandingHeader.height);
    expect(
      find.descendant(
        of: find.byType(LandingHeader),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the hero starts below the bar, not under it', (tester) async {
    await _pumpLanding(tester, size: const Size(1440, 900));

    final hero = tester.getRect(find.byType(BrandMark).last);
    expect(
      tester.getRect(find.byType(SingleChildScrollView).first).top,
      lessThan(hero.top),
    );
  });

  group('back to top', () {
    Future<ScrollController> controllerOf(WidgetTester tester) async =>
        tester
            .widget<SingleChildScrollView>(
              find.byType(SingleChildScrollView).first,
            )
            .controller!;

    testWidgets('stays out of the way until the hero is behind you',
        (tester) async {
      await _pumpLanding(tester, size: const Size(1440, 900));

      final fab = find.byType(LandingBackToTop);
      expect(fab, findsOneWidget);
      expect(
        tester.widget<IgnorePointer>(
          find.descendant(of: fab, matching: find.byType(IgnorePointer)),
        ).ignoring,
        isTrue,
        reason: 'the hidden control is still taking taps over the footer',
      );
    });

    testWidgets('appears once scrolled and returns the page to the top',
        (tester) async {
      await _pumpLanding(tester, size: const Size(1440, 900));
      final controller = await controllerOf(tester);

      controller.jumpTo(900);
      await tester.pump();

      final fab = find.byType(LandingBackToTop);
      expect(
        tester.widget<IgnorePointer>(
          find.descendant(of: fab, matching: find.byType(IgnorePointer)),
        ).ignoring,
        isFalse,
      );

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(controller.offset, 0);
    });

    testWidgets('is at least the platform touch-target floor', (tester) async {
      await _pumpLanding(tester, size: const Size(1440, 900));
      final size = tester.getSize(find.byType(LandingBackToTop));
      expect(size.width, greaterThanOrEqualTo(Dimens.hTouchMin));
      expect(size.height, greaterThanOrEqualTo(Dimens.hTouchMin));
    });
  });

  // The nav has to clear the bar it sits in. `ensureVisible` aligns to a
  // fraction of the viewport, and the viewport now starts behind the glass, so
  // the offset is computed against the header height instead.
  testWidgets('a nav link lands its section clear of the bar', (tester) async {
    await _pumpLanding(tester, size: const Size(1440, 900));

    await tester.tap(
      find.descendant(
        of: find.byType(LandingHeader),
        matching: find.text('Tus datos'),
      ),
    );
    await tester.pumpAndSettle();

    final top = tester.getRect(find.byType(LandingPrivacy)).top;
    expect(top, greaterThanOrEqualTo(LandingHeader.height));
    expect(
      top,
      lessThan(LandingHeader.height + LandingSpace.s48),
      reason: 'the section stopped well below the bar, so the jump overshot',
    );
  });

  testWidgets('the brand stays on the content column left edge', (tester) async {
    const size = Size(1920, 1080);
    await _pumpLanding(tester, size: size);

    final brand = tester.getRect(find.byType(BrandMark).first);
    final expected =
        (size.width - LandingSection.maxWidth) / 2 + LandingSpace.s32;

    expect(brand.left, moreOrLessEquals(expected, epsilon: 1));
  });
}
