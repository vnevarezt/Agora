import 'dart:io';

import 'package:agora/i18n/strings.g.dart';
import 'package:agora/ui/dev/gallery.dart';
import 'package:agora/ui/theme/app_theme.dart';
import 'package:agora/ui/theme/dimens.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override is not on flutter_riverpod's main entrypoint.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the faces pubspec.yaml bundles. Without this the test renderer draws
/// every glyph as a filled box, which makes a golden that cannot tell a
/// changed weight from a changed word — and the type scale is most of what
/// these images exist to defend.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        File('assets/fonts/$f').readAsBytes().then(ByteData.sublistView),
      );
    }
    await loader.load();
  }

  await load('Manrope', [
    'Manrope-Regular.ttf',
    'Manrope-Medium.ttf',
    'Manrope-SemiBold.ttf',
    'Manrope-Bold.ttf',
    'Manrope-ExtraBold.ttf',
  ]);
  await load('JetBrainsMono', ['JetBrainsMono-SemiBold.ttf']);

  // MaterialIcons is not in this package's manifest — it comes from the SDK,
  // and without it every icon in the catalogue renders as an empty box. The
  // path is derived from the running Dart rather than written down, since it
  // is a different one on every machine.
  // Walked up from the running binary rather than counting directories: the
  // test runner sits at a different depth than `dart` does, and both move
  // between SDK releases.
  File? icons;
  for (
    var dir = File(Platform.resolvedExecutable).parent;
    dir.path != dir.parent.path;
    dir = dir.parent
  ) {
    final candidate = File(
      '${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) {
      icons = candidate;
      break;
    }
  }
  if (icons == null) {
    fail(
      'MaterialIcons-Regular.otf not found under ${Platform.resolvedExecutable}'
      "'s SDK. The goldens were generated with it; without it every icon "
      'renders as a box and every image differs.',
    );
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
}

/// One page of the catalog, on the app's real theme.
///
/// Providers and translations are in scope so a widget that reaches for either
/// can be dropped in without the harness changing shape.
class GoldenPage extends StatelessWidget {
  const GoldenPage({
    super.key,
    required this.brightness,
    required this.children,
    this.overrides = const [],
  });

  final Brightness brightness;
  final List<Widget> children;

  /// Providers a widget under test reads. Everything in the catalogue that
  /// needs one reads a plain `Provider`, so a value override is enough — none
  /// of these images needs a database or a workbook behind it.
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    final tokens = brightness == Brightness.light
        ? pizarra.light
        : pizarra.dark;
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(tokens, brightness),
          home: Builder(
            builder: (context) => Scaffold(
              backgroundColor: context.tokens.bg,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Space.s18,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [GalleryRow] for a section composed in a test rather than in the gallery —
/// the surfaces that need a route or an override are not part of the
/// catalogue screen, but they are laid out the same way.
Widget goldenRow(String label, List<Widget> children) =>
    GalleryRow((label: label, children: children));

/// Renders [page] at a fixed size and compares it with
/// `test/ui/golden/<name>.png`. The size is pinned rather than wrapped so a
/// layout change shows up as a moved element instead of a resized image.
Future<void> expectGolden(
  WidgetTester tester,
  Widget page,
  String name, {
  Size size = const Size(760, 520),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(page);
  // Not pumpAndSettle: the spinners never settle, by design. A fixed number of
  // milliseconds from mount lands every looping animation on the same frame,
  // which is what makes the image reproducible.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  await expectLater(find.byType(MaterialApp), matchesGoldenFile('$name.png'));
}
