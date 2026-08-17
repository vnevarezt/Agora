import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/app_button.dart';
import 'package:agora/ui/widgets/app_modal.dart';
import 'package:agora/ui/widgets/filter_pill.dart';
import 'package:agora/ui/widgets/motion.dart';

// Every animated surface has to go through Motion.of, which zeroes the
// duration when the OS asks for reduced motion. A raw duration handed to an
// animated widget silently ignores the setting.

Future<Iterable<Duration>> _durationsOf(
    WidgetTester tester, Widget child, bool disableAnimations) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(pizarra.light, Brightness.light),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  ));
  await tester.pump();
  return tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .map((w) => w.duration);
}

void main() {
  final surfaces = <String, Widget>{
    'AppButton': AppButton(label: 'Guardar', onPressed: () {}),
    'AppIconButton': AppIconButton(icon: Icons.add, onPressed: () {}),
    'FilterPill': FilterPill(label: 'Todos', active: true, onTap: () {}),
  };

  for (final entry in surfaces.entries) {
    testWidgets('${entry.key} animates normally by default', (tester) async {
      final durations = await _durationsOf(tester, entry.value, false);
      expect(durations, isNotEmpty);
      expect(durations, everyElement(isNot(Duration.zero)));
    });

    testWidgets('${entry.key} honours reduced motion', (tester) async {
      final durations = await _durationsOf(tester, entry.value, true);
      expect(durations, isNotEmpty);
      expect(durations, everyElement(Duration.zero));
    });
  }

  // Both modal presentations build their own route, so they carry the only
  // transition durations in the app that Motion.of cannot reach by
  // construction — each has to be handed the duration explicitly.
  for (final form in [
    (label: 'desktop dialog', size: const Size(1400, 900)),
    (label: 'mobile sheet', size: const Size(390, 844)),
  ]) {
    for (final reduced in [false, true]) {
      testWidgets(
          '${form.label} ${reduced ? 'honours' : 'animates without'} '
          'reduced motion', (tester) async {
        tester.view.physicalSize = form.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          theme: buildAppTheme(pizarra.light, Brightness.light),
          // copyWith, not a fresh MediaQueryData: replacing it wholesale
          // zeroes the size and every screen reads as mobile.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Abrir',
                  onPressed: () => showAppModal<void>(
                    context,
                    builder: (_, _, _) => const Text('contenido'),
                  ),
                ),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Abrir'));
        await tester.pump();

        final route =
            ModalRoute.of(tester.element(find.text('contenido')))
                as TransitionRoute;
        expect(route.transitionDuration,
            reduced ? Duration.zero : isNot(Duration.zero));
      });
    }
  }

  Future<void> pumpEnterUp(WidgetTester tester, bool disableAnimations) {
    return tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const Scaffold(
          body: Center(child: EnterUp(child: Text('Hero'))),
        ),
      ),
    ));
  }

  Finder enterUpFade() => find.descendant(
        of: find.byType(EnterUp),
        matching: find.byType(FadeTransition),
      );

  testWidgets('EnterUp fades in by default', (tester) async {
    await pumpEnterUp(tester, false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(enterUpFade(), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('EnterUp skips the fade under reduced motion', (tester) async {
    await pumpEnterUp(tester, true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Hero'), findsOneWidget);
    expect(enterUpFade(), findsNothing);
  });

  Future<Duration?> inkDuration(WidgetTester tester, bool disable) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disable),
        child: Scaffold(
          body: Center(
            child: AnimatedInk(
              color: const Color(0xFF123456),
              builder: (context, color) =>
                  Text('Link', style: TextStyle(color: color)),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    return tester
        .widget<TweenAnimationBuilder<Color?>>(
          find.byType(TweenAnimationBuilder<Color?>),
        )
        .duration;
  }

  testWidgets('AnimatedInk animates normally by default', (tester) async {
    expect(await inkDuration(tester, false), isNot(Duration.zero));
  });

  testWidgets('AnimatedInk honours reduced motion', (tester) async {
    expect(await inkDuration(tester, true), Duration.zero);
  });

  Future<void> pumpMotionSize(
    WidgetTester tester,
    bool disableAnimations,
    double height,
  ) {
    return tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(child: MotionSize(child: SizedBox(height: height))),
        ),
      ),
    ));
  }

  testWidgets('MotionSize eases a size change by default', (tester) async {
    await pumpMotionSize(tester, false, 20);
    await tester.pump();
    await pumpMotionSize(tester, false, 60);
    await tester.pump();
    expect(find.byType(AnimatedSize), findsOneWidget);
    await tester.pumpAndSettle();
  });

  // A zero-duration AnimatedSize restarts its controller from inside
  // performLayout and, because the forward() completes synchronously, marks
  // itself dirty mid-layout — which asserts. Under reduced motion the child
  // has to be sized directly instead.
  testWidgets('MotionSize resizes under reduced motion without asserting',
      (tester) async {
    await pumpMotionSize(tester, true, 20);
    await tester.pump();
    await pumpMotionSize(tester, true, 60);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(AnimatedSize), findsNothing);
  });
}
