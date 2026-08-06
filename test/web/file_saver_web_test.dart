@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:agora/data/files/file_saver.dart';
import 'package:agora/data/files/file_saver_platform_web.dart' as platform;
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

/// The failure this guards against is not a wrong result but an exception:
/// FileSaver used to read Platform.isAndroid in its constructor, which throws
/// in a browser, so every export died before it started.
///
/// Run with: flutter test --platform chrome test/web
void main() {
  test('constructing with real platform defaults does not throw', () {
    expect(FileSaver.new, returnsNormally);
  });

  test('saveAs reports the file name, since the browser owns the location',
      () async {
    final outcome = await FileSaver().saveAs(
      bytes: Uint8List.fromList([1, 2, 3]),
      suggestedName: 'programa.pdf',
      extension: 'pdf',
      mimeType: 'application/pdf',
    );
    expect(outcome, isA<SaveDone>());
    expect((outcome as SaveDone).path, 'programa.pdf');
  });

  test('pickSavePath never reports a cancel', () async {
    // Returning null here would make saveAs report SaveCanceled and silently
    // skip the download.
    expect(
      await platform.pickSavePath(
          'copia.agora', const XTypeGroup(label: 'agora', extensions: ['agora'])),
      'copia.agora',
    );
  });

  test('writeFile leaves no anchor behind in the document', () async {
    final before = web.document.querySelectorAll('a').length;
    await platform.writeFile(
        'x.bin', Uint8List.fromList(List<int>.filled(1024, 7)));
    expect(web.document.querySelectorAll('a').length, before,
        reason: 'the download anchor must be removed after the click');
  });
}
