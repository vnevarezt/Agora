import 'package:agora/i18n/strings.g.dart';
import 'package:agora/ui/auth/widgets/auth_error_text.dart';
import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:agora/ui/widgets/app_button.dart';
import 'package:agora/ui/widgets/filter_pill.dart';
import 'package:agora/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Everything here is invisible on screen and invisible in review: a missing
/// `selected` or `header` renders identically and reads as a flat, anonymous
/// list of buttons to anyone using a screen reader. Nothing but a semantics
/// assertion catches it going away again.
///
/// `isSemantics` rather than `matchesSemantics`: these assert the one property
/// each was added for, and leave the rest of the node — the tap action, the
/// button role, the focusability — to the widgets that own it.
void main() {
  Widget host(Widget child) => TranslationProvider(
    child: MaterialApp(
      theme: buildAppTheme(pizarra.light, Brightness.light),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('a filter pill says whether it is the chosen one', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      host(
        Column(
          children: [
            FilterPill(label: 'On', active: true, onTap: () {}),
            FilterPill(label: 'Off', active: false, onTap: () {}),
          ],
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('On')),
      isSemantics(label: 'On', isSelected: true),
    );
    expect(
      tester.getSemantics(find.text('Off')),
      isSemantics(label: 'Off', isSelected: false),
    );

    handle.dispose();
  });

  testWidgets('a section header announces itself as a heading', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(host(const SectionHeader(title: 'Tesoros')));

    expect(
      tester.getSemantics(find.text('TESOROS')),
      isSemantics(label: 'TESOROS', isHeader: true),
    );

    handle.dispose();
  });

  testWidgets('a busy button says why it stopped responding', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      host(AppButton(label: 'Exportar', busy: true, onPressed: () {})),
    );

    // Disabled with no reason is what a screen reader got before: the hint is
    // the reason, and the live region is what delivers it without waiting for
    // focus to arrive.
    expect(
      tester.getSemantics(find.text('Exportar')),
      isSemantics(hint: 'Cargando', isLiveRegion: true, isEnabled: false),
    );

    handle.dispose();
  });

  testWidgets('an inline field error is a live region', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(host(const AuthErrorText('Wrong password')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Wrong password')),
      isSemantics(label: 'Wrong password', isLiveRegion: true),
    );

    handle.dispose();
  });
}
