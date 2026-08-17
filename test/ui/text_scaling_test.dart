import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/dimens.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A significant share of the people who prepare programs are older users, so
// the largest system text size is a real setting here, not an edge case. A
// control with a fixed height clips its own label at that size.

Future<Size> _buttonAt(WidgetTester tester, double scale,
    {String label = 'Guardar cambios'}) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(pizarra.light, Brightness.light),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: Center(child: AppButton(label: label, onPressed: () {})),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(AppButton));
}

void main() {
  testWidgets('the button keeps its designed height at normal text size',
      (tester) async {
    final size = await _buttonAt(tester, 1.0);
    expect(size.height, Dimens.hControl);
  });

  testWidgets('the button grows instead of clipping at 2x text size',
      (tester) async {
    final normal = await _buttonAt(tester, 1.0);
    final huge = await _buttonAt(tester, 2.0);

    expect(huge.height, greaterThan(normal.height),
        reason: 'a fixed height would clip the label');
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at the largest text size on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _buttonAt(tester, 2.0);
    expect(tester.takeException(), isNull);
  });
}
