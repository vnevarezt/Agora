// Importing a workbook the user picked off their own disk.
//
// The web build has no other way in: jw.org's lookup API sends
// `access-control-allow-origin: *`, but every file it points at — EPUB, JWPUB
// and PDF alike — comes from a host that sends no CORS header at all and
// answers 403 to a preflight, so the browser cannot read it whatever the page's
// policy says.
//
// A picked file arrives with no label on it, so the archive is ASKED which
// publication it is rather than told. The answer is the cover image's own name,
// which is the only place in the archive that carries the publication code:
// `dc:identifier` is a random UUID and `dc:title` spells the period out in the
// workbook's own language. Verified against the real files from jw.org —
// `mwb_S_202607.epub` holds `OEBPS/images/mwb_S_202607.jpg` and the English
// edition holds `OEBPS/images/mwb_E_202607.jpg`.

import 'dart:io';
import 'dart:typed_data';

import 'package:agora/data/epub_parser.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

/// A workbook shaped like the real ones: a cover image named after the
/// publication, and one week.
Uint8List _workbook({
  required String fixture,
  String? cover,
}) {
  final archive = Archive()
    ..addFile(ArchiveFile.string('OEBPS/000000001.xhtml',
        File('test/fixtures/mwb/$fixture').readAsStringSync()));
  if (cover != null) {
    archive.addFile(ArchiveFile('OEBPS/images/$cover', 3, [1, 2, 3]));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  test('the file says which publication it is', () {
    final parsed = parseWorkbookEpub(
        _workbook(fixture: 'es_week.xhtml', cover: 'mwb_S_202607.jpg'));

    expect(parsed, isNotNull);
    expect(parsed!.lang, 'S');
    expect(parsed.issue, '202607');
    expect(parsed.weeks, hasLength(1));
  });

  test('the issue it declares is the one its weeks are dated against', () {
    // The point of reading the identity instead of taking it from the caller:
    // a week only resolves its Monday against the right period, so filing a
    // workbook under a neighbouring issue would quietly cost it its identity.
    final parsed = parseWorkbookEpub(
        _workbook(fixture: 'es_week.xhtml', cover: 'mwb_S_202607.jpg'));

    expect(parsed!.weeks.single.weekStart, '2026-07-06');
  });

  test('the English edition is read the same way', () {
    final parsed = parseWorkbookEpub(
        _workbook(fixture: 'en_week.xhtml', cover: 'mwb_E_202607.jpg'));

    expect(parsed!.lang, 'E');
    expect(parsed.issue, '202607');
    expect(parsed.weeks.single.weekStart, '2026-07-06',
        reason: 'one identity, two languages');
  });

  test('a file that is not a workbook is refused rather than filed', () {
    // Anything else the user might pick: a book, a Watchtower, a stray zip.
    // Without the cover there is nothing to file it under, and guessing would
    // put it in the cache under an issue it is not.
    expect(parseWorkbookEpub(_workbook(fixture: 'es_week.xhtml')), isNull);
  });

  test('a cover that is not a workbook cover does not count as one', () {
    expect(
        parseWorkbookEpub(
            _workbook(fixture: 'es_week.xhtml', cover: 'w_S_202607.jpg')),
        isNull,
        reason: 'w is the Watchtower; only mwb is this program');
  });
}
