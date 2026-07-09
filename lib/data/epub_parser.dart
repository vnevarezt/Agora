import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/week.dart';

/// Parsing of the mwb notebook EPUB -> list of weeks.
///
/// 1:1 port of `parsear_epub` / `parsear_semana` / `_text` / `_duration` from
/// generar_programa.py:54-124. Keeps the SAME regular expressions.

// EPUB heading color -> section (SECCION_POR_COLOR, py:24-28).
const Map<String, Section> _sectionByColor = {
  'teal': Section.treasures,
  'gold': Section.ministry,
  'maroon': Section.christianLife,
};

final _rePageNum = RegExp(
    r'<span[^>]*class="[^"]*pageNum[^"]*"[^>]*>.*?</span>',
    dotAll: true);
final _reSup = RegExp(r'<sup\b[^>]*>.*?</sup>', dotAll: true);
final _reTags = RegExp(r'<[^>]+>');
final _reSpaces = RegExp(r'\s+');
final _reDuration = RegExp(r'\((\d+)\s*mins?\.?\)');
final _reHeadings =
    RegExp(r'<(h[123])\b([^>]*)>(.*?)</\1>', dotAll: true);
final _reColor = RegExp(r'du-color--(teal|gold|maroon)');
final _reClass = RegExp(r'class="([^"]*)"');
final _reSong = RegExp('Canci[óo]n\\s+(\\d+)');
final _reSongOnly = RegExp(r'^Canci[óo]n\s+\d+$');
final _rePartNum = RegExp(r'^(\d+)\.\s+(.*)$', dotAll: true);
final _reWeekFile = RegExp(r'^OEBPS/\d+\.xhtml$');

/// HTML -> clean text (no tags, no page numbers or superscripts).
String _text(String frag) {
  frag = frag.replaceAll(_rePageNum, '');
  frag = frag.replaceAll(_reSup, ''); // footnote marks
  frag = frag.replaceAll(_reTags, ''); // keeps the text
  // html.unescape equivalent: decodes entities (&amp;, &#160;, …).
  final unescaped = html_parser.parseFragment(frag).text ?? '';
  return unescaped.replaceAll(_reSpaces, ' ').trim();
}

int? _duration(String segment) {
  final m = _reDuration.firstMatch(segment);
  return m != null ? int.parse(m.group(1)!) : null;
}

Week parseWeek(String xhtml) {
  // Positions of every h1/h2/h3 heading in order of appearance.
  final headings = _reHeadings.allMatches(xhtml).toList();
  final week = Week();
  Section? currentSection;

  for (var i = 0; i < headings.length; i++) {
    final m = headings[i];
    final tag = m.group(1)!;
    final attrs = m.group(2)!;
    final inner = m.group(3)!;
    final end = (i + 1 < headings.length) ? headings[i + 1].start : xhtml.length;
    final body = xhtml.substring(m.end, end);
    final text = _text(inner);
    final classMatch = _reClass.firstMatch(attrs);
    final className = classMatch != null ? classMatch.group(1)! : '';

    // ----- section (colored h2) -----
    final colorMatch = _reColor.firstMatch(className);
    if (tag == 'h2' && colorMatch != null) {
      currentSection = _sectionByColor[colorMatch.group(1)];
      continue;
    }
    // ----- songs / intro and conclusion words -----
    final low = text.toLowerCase();
    final songMatch = _reSong.firstMatch(text);
    if (low.contains('palabras de introducci')) {
      if (songMatch != null) week.openingSong = songMatch.group(1);
      week.introMinutes = _duration(text) ?? 1;
      continue;
    }
    if (low.contains('palabras de conclusi')) {
      if (songMatch != null) week.closingSong = songMatch.group(1);
      week.conclusionMinutes = _duration(text) ?? 3;
      continue;
    }
    if (songMatch != null &&
        (className.contains('dc-icon--music') ||
            _reSongOnly.hasMatch(text))) {
      week.middleSong = songMatch.group(1);
      continue;
    }
    // ----- numbered part (h3 'N. Title') -----
    final partMatch = _rePartNum.firstMatch(text);
    if (tag == 'h3' && partMatch != null && currentSection != null) {
      final number = int.parse(partMatch.group(1)!);
      final title = partMatch.group(2)!.trim();
      final duration = _duration(body) ?? _duration(text);
      week.parts.add(Part(
        section: currentSection,
        number: number,
        title: title,
        minutes: duration,
      ));
      continue;
    }
    // ----- date (first h1) and reading (h2 before TESOROS) -----
    if (tag == 'h1' && week.date.isEmpty) {
      week.date = text.toUpperCase();
    } else if (tag == 'h2' &&
        currentSection == null &&
        week.reading.isEmpty &&
        text.isNotEmpty) {
      week.reading = text;
    }
  }
  return week;
}

/// Parses the whole EPUB (bytes) and returns the weeks with parts.
List<Week> parseEpub(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  // Weekly files are OEBPS/NNNNNNNNN.xhtml (without '-extracted').
  final names = archive.files
      .where((f) => f.isFile && _reWeekFile.hasMatch(f.name))
      .map((f) => f.name)
      .toList()
    ..sort();
  final weeks = <Week>[];
  for (final n in names) {
    final f = archive.findFile(n)!;
    final xhtml = utf8.decode(f.content as List<int>);
    final week = parseWeek(xhtml);
    if (week.parts.isNotEmpty) weeks.add(week); // ignore cover/index
  }
  return weeks;
}
