import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/app_button.dart';
import 'package:agora/ui/widgets/filter_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The catalog controls are built on Pressable, not on a Material button, and
// the theme disables the ripple. Keyboard reachability therefore lives or dies
// in Pressable alone: if it stops being focusable, nothing on desktop can be
// operated without a mouse.

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(pizarra.light, Brightness.light),
    home: Scaffold(body: Center(child: child)),
  ));
}

void main() {
  /// Border of the foreground DecoratedBox Pressable uses for the ring.
  BoxBorder? ringOf(WidgetTester tester, Finder control) {
    final box = tester.widgetList<DecoratedBox>(find.descendant(
      of: control,
      matching: find.byType(DecoratedBox),
    )).firstWhere((d) => d.position == DecorationPosition.foreground);
    return (box.decoration as BoxDecoration).border;
  }

  testWidgets('tabbing to a control shows a focus ring', (tester) async {
    await _pump(tester, AppButton(label: 'Guardar', onPressed: () {}));
    expect(ringOf(tester, find.byType(AppButton)), isNull,
        reason: 'no ring before the control is focused');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(ringOf(tester, find.byType(AppButton)), isNotNull,
        reason: 'the control must show a visible focus indicator');
  });

  testWidgets('Enter and Space activate a focused control', (tester) async {
    var taps = 0;
    await _pump(tester, AppButton(label: 'Guardar', onPressed: () => taps++));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(taps, 2);
  });

  testWidgets('a disabled control is skipped by the focus traversal',
      (tester) async {
    await _pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(label: 'Desactivado', onPressed: null),
          FilterPill(label: 'Activo', active: false, onTap: _noop),
        ],
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    // The only focusable control left is the pill, so focus must land there
    // rather than on the disabled button.
    expect(
      find.descendant(
        of: find.byType(FilterPill),
        matching: find.byType(FocusableActionDetector),
      ),
      findsOneWidget,
    );
    expect(tester.binding.focusManager.primaryFocus?.hasPrimaryFocus, isTrue);
  });

  testWidgets('the focus ring never changes the control size', (tester) async {
    await _pump(tester, AppButton(label: 'Guardar', onPressed: () {}));
    final before = tester.getSize(find.byType(AppButton));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(AppButton)), before);
  });
}

void _noop() {}
