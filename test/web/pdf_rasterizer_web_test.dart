@TestOn('browser')
library;

import 'package:agora/pdf/pdf_rasterizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';

/// Regression guard for the PDF preview on web.
///
/// Moving pdfrx's initialisation out of main(), to keep 5MB of pdfium off the
/// startup path, broke rendering: PdfDocument.openData reads
/// PdfrxEntryFunctions.instance directly, and only pdfrxFlutterInitialize
/// points that at the WASM engine. pdfrx does initialise itself lazily, but
/// only inside the PdfDocumentRef API, which the rasterizer does not use. So it
/// compiled, it started faster, and it could no longer render a page.
///
/// This asserts the engine is selected, not that a page comes out: the test
/// harness serves the package's Dart but not pdfrx's wasm assets, so the load
/// after selection always fails here. Rendering end to end needs a real build.
///
/// Run with: flutter test --platform chrome test/web
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rasterizePage selects the engine before opening the document', () async {
    final doc = pw.Document()
      ..addPage(pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (_) => pw.SizedBox(),
      ));
    final bytes = await doc.save();

    expect(
      PdfrxEntryFunctions.instance.runtimeType.toString(),
      isNot(contains('Wasm')),
      reason: 'nothing may have initialised pdfrx before this test runs',
    );

    try {
      await rasterizePage(bytes, scale: 1);
    } catch (_) {
      // Expected: the wasm assets are not served here. Selection already
      // happened by this point, which is what is under test.
    }

    expect(
      PdfrxEntryFunctions.instance.runtimeType.toString(),
      contains('Wasm'),
      reason: 'rasterizePage must call pdfrxFlutterInitialize before openData',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
