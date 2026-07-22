// FileSaver with injected platform calls: outcome mapping for saveAs (desktop
// dialog / mobile document picker) and share, without touching real plugins.

import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/files/file_saver.dart';
import 'package:share_plus/share_plus.dart' show ShareResultStatus;

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  Future<SaveOutcome> saveAs(FileSaver saver) => saver.saveAs(
        bytes: bytes,
        suggestedName: 'programa.pdf',
        extension: 'pdf',
        mimeType: 'application/pdf',
      );

  group('saveAs', () {
    test('desktop: picked path writes the file and reports it', () async {
      String? writtenPath;
      Uint8List? writtenBytes;
      final saver = FileSaver(
        mobile: false,
        pickSavePath: (name, type) async {
          expect(name, 'programa.pdf');
          expect(type.extensions, ['pdf']);
          return '/tmp/x/programa.pdf';
        },
        writeFile: (path, b) async {
          writtenPath = path;
          writtenBytes = b;
        },
        saveMobile: (_, _, _) async => fail('mobile picker must not open'),
        shareSheet: (_, _, _, _) async => fail('share sheet must not open'),
      );

      final outcome = await saveAs(saver);
      expect(outcome, isA<SaveDone>());
      expect((outcome as SaveDone).path, '/tmp/x/programa.pdf');
      expect(writtenPath, '/tmp/x/programa.pdf');
      expect(writtenBytes, bytes);
    });

    test('desktop: dismissed dialog cancels without writing', () async {
      var wrote = false;
      final saver = FileSaver(
        mobile: false,
        pickSavePath: (_, _) async => null,
        writeFile: (_, _) async => wrote = true,
        saveMobile: (_, _, _) async => fail('mobile picker must not open'),
        shareSheet: (_, _, _, _) async => fail('share sheet must not open'),
      );

      expect(await saveAs(saver), isA<SaveCanceled>());
      expect(wrote, false);
    });

    test('mobile: document picker path is reported (null cancels)', () async {
      FileSaver saver(String? path) => FileSaver(
            mobile: true,
            saveMobile: (name, extension, b) async {
              expect(name, 'programa.pdf');
              expect(extension, 'pdf');
              expect(b, bytes);
              return path;
            },
            pickSavePath: (_, _) async => fail('desktop dialog must not open'),
            writeFile: (_, _) async => fail('must not write directly'),
            shareSheet: (_, _, _, _) async => fail('share sheet must not open'),
          );

      final done = await saveAs(saver('/storage/programa.pdf'));
      expect((done as SaveDone).path, '/storage/programa.pdf');
      expect(await saveAs(saver(null)), isA<SaveCanceled>());
    });
  });

  group('share', () {
    Future<SaveOutcome> share(FileSaver saver) => saver.share(
          bytes: bytes,
          suggestedName: 'programa.pdf',
          mimeType: 'application/pdf',
          originRect: const Rect.fromLTWH(1, 2, 3, 4),
        );

    test('maps success/dismissed/unavailable and forwards the origin',
        () async {
      FileSaver saver(ShareResultStatus status) => FileSaver(
            mobile: true,
            shareSheet: (b, name, mime, origin) async {
              expect(b, bytes);
              expect(name, 'programa.pdf');
              expect(mime, 'application/pdf');
              expect(origin, const Rect.fromLTWH(1, 2, 3, 4));
              return status;
            },
            pickSavePath: (_, _) async => fail('dialog must not open'),
            saveMobile: (_, _, _) async => fail('picker must not open'),
            writeFile: (_, _) async => fail('must not write'),
          );

      expect(await share(saver(ShareResultStatus.success)), isA<SaveShared>());
      expect(
          await share(saver(ShareResultStatus.dismissed)), isA<SaveCanceled>());
      await expectLater(share(saver(ShareResultStatus.unavailable)),
          throwsA(isA<Exception>()));
    });
  });
}
