// FileSaver with injected platform calls: outcome mapping for the desktop
// save dialog and the mobile share sheet, without touching real plugins.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/files/file_saver.dart';
import 'package:share_plus/share_plus.dart' show ShareResultStatus;

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  Future<SaveOutcome> run(FileSaver saver) => saver.save(
        bytes: bytes,
        suggestedName: 'programa.pdf',
        extension: 'pdf',
        mimeType: 'application/pdf',
      );

  test('desktop: picked path writes the file and reports it', () async {
    String? writtenPath;
    Uint8List? writtenBytes;
    final saver = FileSaver(
      useShareSheet: false,
      pickSavePath: (name, type) async {
        expect(name, 'programa.pdf');
        expect(type.extensions, ['pdf']);
        return '/tmp/x/programa.pdf';
      },
      writeFile: (path, b) async {
        writtenPath = path;
        writtenBytes = b;
      },
      shareSheet: (_, _, _) async => fail('share sheet must not open'),
    );

    final outcome = await run(saver);
    expect(outcome, isA<SaveDone>());
    expect((outcome as SaveDone).path, '/tmp/x/programa.pdf');
    expect(writtenPath, '/tmp/x/programa.pdf');
    expect(writtenBytes, bytes);
  });

  test('desktop: dismissed dialog cancels without writing', () async {
    var wrote = false;
    final saver = FileSaver(
      useShareSheet: false,
      pickSavePath: (_, _) async => null,
      writeFile: (_, _) async => wrote = true,
      shareSheet: (_, _, _) async => fail('share sheet must not open'),
    );

    expect(await run(saver), isA<SaveCanceled>());
    expect(wrote, false);
  });

  test('mobile: share sheet maps success/dismissed/unavailable', () async {
    FileSaver saver(ShareResultStatus status) => FileSaver(
          useShareSheet: true,
          shareSheet: (_, _, _) async => status,
          pickSavePath: (_, _) async => fail('dialog must not open'),
          writeFile: (_, _) async => fail('must not write'),
        );

    expect(await run(saver(ShareResultStatus.success)), isA<SaveShared>());
    expect(await run(saver(ShareResultStatus.dismissed)), isA<SaveCanceled>());
    await expectLater(
        run(saver(ShareResultStatus.unavailable)), throwsA(isA<Exception>()));
  });
}
