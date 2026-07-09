import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_program/ui/theme/app_theme.dart';
import 'package:jw_program/ui/theme/tokens.dart';
import 'package:jw_program/ui/widgets/progress_meter.dart';

void main() {
  // Regression: a 0% meter (widthFactor 0) reported a non-finite intrinsic
  // width and crashed inside an IntrinsicWidth (e.g. the week selector's
  // MenuAnchor overlay).
  testWidgets('ProgressMeter al 0% no rompe dentro de IntrinsicWidth',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: const Scaffold(
        body: Center(
          child: IntrinsicWidth(
            child: Row(
              children: [
                Text('x'),
                Expanded(child: ProgressMeter(value: 0)),
              ],
            ),
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.byType(ProgressMeter), findsOneWidget);
  });
}
