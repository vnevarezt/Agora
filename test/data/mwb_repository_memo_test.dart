import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/data/mwb_cache.dart';
import 'package:agora/data/mwb_repository.dart';
import 'package:agora/data/mwb_store.dart';

Uint8List _fakeEpub() {
  const xhtml = '<h1>1-7 DE JUNIO DE 2026</h1>'
      '<h2 class="du-color--teal">TESOROS</h2>'
      '<h3 class="p">1. Discurso (10 mins.)</h3>';
  final archive = Archive()
    ..addFile(ArchiveFile.string('OEBPS/000000001.xhtml', xhtml));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// In-memory store that counts EPUB reads, so a test can tell a memo hit from
/// a re-parse.
class _CountingStore implements MwbStore {
  _CountingStore(this.bytes);

  final Uint8List bytes;
  final Map<String, String> strings = {};
  int epubReads = 0;

  @override
  Future<Uint8List?> readBytes(String name) async {
    epubReads++;
    return bytes;
  }

  @override
  Future<void> writeBytes(String name, Uint8List data) async {}

  @override
  Future<String?> readString(String name) async => strings[name];

  @override
  Future<void> writeString(String name, String data) async {
    strings[name] = data;
  }
}

void main() {
  late _CountingStore store;
  late MwbRepository repo;

  setUp(() {
    store = _CountingStore(_fakeEpub());
    repo = MwbRepository(MwbCache(store: store));
  });

  test('a cached notebook is parsed once, however often it is asked for',
      () async {
    final first = await repo.weeks('202606');
    expect(first, hasLength(1));
    expect(store.epubReads, 1);

    final second = await repo.weeks('202606');
    expect(identical(second, first), isTrue);
    expect(store.epubReads, 1, reason: 'the second call re-read the EPUB');
  });

  test('ensureCached reuses the parse and feeds it to weeks()', () async {
    expect(await repo.ensureCached('202606'), 1);
    expect(store.epubReads, 1);

    await repo.weeks('202606');
    expect(store.epubReads, 1);
  });

  test('each language keeps its own entry', () async {
    await repo.weeks('202606');
    await repo.weeks('202606', lang: 'E');
    expect(store.epubReads, 2);

    await repo.weeks('202606');
    await repo.weeks('202606', lang: 'E');
    expect(store.epubReads, 2);
  });
}
