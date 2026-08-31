// Looking a week up by its real date and the language it has to be in. This
// is the replacement for matching a localized heading, which could never cross
// languages.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agora/data/mwb_cache.dart';
import 'package:agora/data/mwb_repository.dart';
import 'package:agora/data/mwb_store_native.dart';

/// A one-week workbook. The heading is what the parser resolves the Monday
/// from, so each language gets its own wording for the SAME week: 1 June 2026
/// is a Monday, and mwb_202605 covers May-June.
Uint8List _epub(String heading, String talkMarker) {
  final xhtml =
      '<h1>$heading</h1>'
      '<h2 class="du-color--teal">TESOROS</h2>'
      '<h3 class="p">1. $talkMarker (10 mins.)</h3>';
  final archive = Archive()
    ..addFile(ArchiveFile.string('OEBPS/000000001.xhtml', xhtml));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late Directory tmp;
  late MwbCache cache;
  late MwbRepository repo;

  /// Any request at all is a failure: weekFor must never reach the network.
  final noNetwork = MockClient((_) async {
    fail('weekFor went to the network');
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('week_for');
    cache = MwbCache(store: DirectoryMwbStore(root: tmp));
    repo = MwbRepository(cache, client: noNetwork);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('finds the week in the language asked for', () async {
    await cache.putEpub('202605', 'S', _epub('1-7 DE JUNIO', 'Discurso'), 1);
    await cache.putEpub('202605', 'E', _epub('JUNE 1-7', 'Talk'), 1);

    final spanish = await repo.weekFor('2026-06-01', 'S');
    final english = await repo.weekFor('2026-06-01', 'E');

    expect(spanish!.date, '1-7 DE JUNIO');
    expect(english!.date, 'JUNE 1-7');
    expect(
      english.weekStart,
      spanish.weekStart,
      reason: 'one week, one identity, two labels',
    );
  });

  test(
    'a language that is not cached yields null, not the other one',
    () async {
      await cache.putEpub('202605', 'S', _epub('1-7 DE JUNIO', 'Discurso'), 1);

      expect(
        await repo.weekFor('2026-06-01', 'E'),
        isNull,
        reason: 'silently serving the wrong language is the original bug',
      );
    },
  );

  test('a week no cached workbook holds yields null', () async {
    await cache.putEpub('202605', 'S', _epub('1-7 DE JUNIO', 'Discurso'), 1);

    expect(await repo.weekFor('2026-06-08', 'S'), isNull);
  });

  test('an empty identity resolves to nothing', () async {
    expect(await repo.weekFor('', 'S'), isNull);
  });

  group('refresh', () {
    test('replaces a cached workbook with the corrected one', () async {
      await cache.putEpub('202605', 'S', _epub('1-7 DE JUNIO', 'Discurso'), 1);
      expect((await repo.weekFor('2026-06-01', 'S'))!.reading, isEmpty);

      // jw.org republishes the issue with a Bible reading it was missing.
      final corrected = _epubWithReading('1-7 DE JUNIO', 'PROVERBIOS 30');
      final serving = MwbRepository(
        cache,
        client: MockClient((req) async {
          if (req.url.host == 'app.jw-cdn.org') {
            return http.Response(
              jsonEncode({
                'files': {
                  'S': {
                    'EPUB': [
                      {
                        'file': {'url': 'https://ex.test/202605.epub'},
                      },
                    ],
                  },
                },
                'formattedDate': 'x',
              }),
              200,
            );
          }
          return http.Response.bytes(corrected, 200);
        }),
      );

      await serving.refresh('202605', 'S');

      expect(
        (await serving.weekFor('2026-06-01', 'S'))!.reading,
        'PROVERBIOS 30',
      );
    });

    test('a failed refresh leaves what was already there', () async {
      await cache.putEpub('202605', 'S', _epub('1-7 DE JUNIO', 'Discurso'), 1);
      final offline = MwbRepository(
        cache,
        client: MockClient((_) async => http.Response('nope', 503)),
      );

      await expectLater(
        offline.refresh('202605', 'S'),
        throwsA(isA<Exception>()),
      );

      expect(
        await cache.readEpub('202605', 'S'),
        isNotNull,
        reason: 'asking for an update must never cost you the workbook',
      );
      expect(await repo.weekFor('2026-06-01', 'S'), isNotNull);
    });
  });
}

/// Same shape as [_epub] plus the h2 the parser reads as the weekly reading.
Uint8List _epubWithReading(String heading, String reading) {
  final xhtml =
      '<h1>$heading</h1>'
      '<h2 class="du-fontSize--base">$reading</h2>'
      '<h2 class="du-color--teal">TESOROS</h2>'
      '<h3 class="p">1. Discurso (10 mins.)</h3>';
  final archive = Archive()
    ..addFile(ArchiveFile.string('OEBPS/000000001.xhtml', xhtml));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
