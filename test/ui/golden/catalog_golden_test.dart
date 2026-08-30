import 'package:agora/ui/dev/gallery.dart';
import 'package:agora/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog.dart';

/// The catalogue's appearance, which until now was verified only by reading
/// it. Behaviour has had tests for a while — contrast, motion, text scaling,
/// keyboard, semantics — and every one of them passes on a control that looks
/// wrong.
///
/// The composition itself lives in lib/ui/dev/gallery.dart, shared with the
/// screen a developer opens. Composing it twice would give the gallery and the
/// images every chance to drift, and a gallery that has drifted from the
/// images defending it looks like coverage without being any.
///
/// Both themes, because half the token contract only exists in the other one:
/// a value that reads on white and vanishes on near-black is the single most
/// common defect these images are here to catch.
///
/// Regenerate with `fvm flutter test --update-goldens test/ui/golden`, and
/// look at the diff before accepting it — an updated golden is a claim that
/// the new appearance is the intended one.
void main() {
  setUpAll(loadAppFonts);

  List<Widget> rows(List<GallerySection> sections) => [
    for (final s in sections) GalleryRow(s),
  ];

  for (final mode in [
    (name: 'light', brightness: Brightness.light, tokens: pizarra.light),
    (name: 'dark', brightness: Brightness.dark, tokens: pizarra.dark),
  ]) {
    testWidgets('controls · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(
          brightness: mode.brightness,
          children: rows(galleryControls()),
        ),
        'controls_${mode.name}',
      );
    });

    testWidgets('markers · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(
          brightness: mode.brightness,
          children: rows(galleryMarkers(mode.tokens)),
        ),
        'markers_${mode.name}',
        size: const Size(760, 400),
      );
    });

    testWidgets('structure · ${mode.name}', (tester) async {
      await expectGolden(
        tester,
        GoldenPage(
          brightness: mode.brightness,
          children: rows(galleryStructure()),
        ),
        'structure_${mode.name}',
        size: const Size(760, 520),
      );
    });
  }
}
