// The parser must read a workbook in ANY meeting language, keying off markup
// rather than wording. See test/fixtures/mwb/README.md.

import 'dart:io';

import 'package:agora/data/epub_parser.dart';
import 'package:agora/models/week.dart';
import 'package:flutter_test/flutter_test.dart';

Week _fixture(String name, String lang) =>
    parseWeek(File('test/fixtures/mwb/$name').readAsStringSync(), lang: lang);

void main() {
  final es = _fixture('es_week.xhtml', 'S');
  final en = _fixture('en_week.xhtml', 'E');

  group('structure is read identically in both languages', () {
    test('songs', () {
      for (final w in [es, en]) {
        expect(w.openingSong, '123');
        expect(w.middleSong, '49');
        expect(w.closingSong, '61');
      }
    });

    test('opening / concluding comment durations', () {
      for (final w in [es, en]) {
        expect(w.introMinutes, 1);
        expect(w.conclusionMinutes, 3);
      }
    });

    test('parts land in the right sections, in order', () {
      for (final w in [es, en]) {
        expect(w.parts.map((p) => p.section).toList(), [
          Section.treasures,
          Section.treasures,
          Section.treasures,
          Section.ministry,
          Section.ministry,
          Section.ministry,
          Section.christianLife,
          Section.christianLife,
        ]);
        expect(w.parts.map((p) => p.number).toList(), [1, 2, 3, 4, 5, 6, 7, 8]);
      }
    });

    test('durations', () {
      for (final w in [es, en]) {
        expect(w.parts.map((p) => p.minutes).toList(),
            [10, 10, 4, 3, 4, 5, 15, 30]);
      }
    });
  });

  group('song numbers survive the duration in the same heading', () {
    // The closing line puts the duration before the song, so "first number
    // wins" would read 3 here.
    test('the closing song is not the concluding-comment duration', () {
      expect(es.closingSong, isNot('3'));
      expect(en.closingSong, isNot('3'));
    });
  });

  group('ministry talk marker', () {
    // Part 5 is a talk marked in the BODY, not the title — the case the old
    // title-only match read as a demonstration and gave two slots.
    test('is found in the body, not just the title', () {
      expect(es.parts[4].isTalk, isTrue);
      expect(en.parts[4].isTalk, isTrue);
    });

    test('demonstrations are not flagged', () {
      expect(es.parts[3].isTalk, isFalse); // Empiece conversaciones
      expect(es.parts[5].isTalk, isFalse); // Haga discípulos
      expect(en.parts[3].isTalk, isFalse);
      expect(en.parts[5].isTalk, isFalse);
    });

    test('only ministry parts are ever flagged', () {
      for (final w in [es, en]) {
        for (final p in w.parts.where((p) => p.section != Section.ministry)) {
          expect(p.isTalk, isFalse, reason: '${p.section} ${p.title}');
        }
      }
    });

    test('an unknown meeting language simply yields no talks', () {
      final unknown = _fixture('es_week.xhtml', 'ZZ');
      expect(unknown.parts.any((p) => p.isTalk), isFalse);
      // …but everything structural still parses.
      expect(unknown.openingSong, '123');
      expect(unknown.parts, hasLength(8));
    });
  });

  test('date and Bible reading', () {
    expect(es.date, '6-12 DE JULIO');
    expect(es.reading, 'JEREMÍAS 13-15');
    expect(en.date, 'JULY 6-12');
    expect(en.reading, 'JEREMIAH 13-15');
  });

  test('Part.isTalk round-trips through JSON, defaulting to false', () {
    final talk = es.parts[4];
    expect(Part.fromJson(talk.toJson()).isTalk, isTrue);
    // A snapshot written before the field existed.
    final legacy = Map<String, dynamic>.from(talk.toJson())..remove('isTalk');
    expect(Part.fromJson(legacy).isTalk, isFalse);
  });
}
