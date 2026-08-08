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
final _rePartNum = RegExp(r'^(\d+)\.\s+(.*)$', dotAll: true);
final _reWeekFile = RegExp(r'^OEBPS/\d+\.xhtml$');
final _reNumber = RegExp(r'\d+');

/// Marks a heading that carries a song (the music glyph).
const _cssMusic = 'dc-icon--music';

/// Marks the two rule-separated headings: the opening line above the first
/// section and the concluding line below the last one.
const _cssRule = 'du-borderStyle-top--solid';

/// The ONE thing the workbook does not encode structurally: whether a ministry
/// part is a student talk (one student) or a demonstration (student +
/// assistant). It appears as the whole title ("Discurso" / "Talk") or as the
/// first word of the body ("(4 mins.) Discurso. …"), so it needs a keyword per
/// meeting language. Everything else the parser needs is in the markup.
const Map<String, String> _talkMarkers = {'S': 'discurso', 'E': 'talk'};

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

/// Song number in a heading, language-independently.
///
/// The opening line is "Canción 123 y oración | Palabras de introducción
/// (1 min.)" and the closing one "Palabras de conclusión (3 mins.) | Canción 61
/// y oración" — the song number comes first in one and second in the other, and
/// both also contain the duration. So the duration is stripped first and the
/// remaining run of digits is the song.
String? _songNumber(String text) {
  final withoutDuration = text.replaceAll(_reDuration, '');
  return _reNumber.firstMatch(withoutDuration)?.group(0);
}

/// True when a ministry part is a student talk rather than a demonstration.
/// See [_talkMarkers] for why this is the one text-based check left.
bool _isTalk(String title, String body, String lang) {
  final marker = _talkMarkers[lang];
  if (marker == null) return false;
  if (title.trim().toLowerCase() == marker) return true;
  // Body form: "(4 mins.) Discurso. …" — the marker is the first word after
  // the duration. Anchored so prose mentioning the word cannot trip it.
  final afterDuration = body.replaceFirst(_reDuration, '').trimLeft();
  return afterDuration.toLowerCase().startsWith('$marker.');
}

/// [lang] is the jw.org `langwritten` code of the workbook being parsed; it is
/// only consulted for [_isTalk].
Week parseWeek(String xhtml, {String lang = 'S'}) {
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
    // ----- songs / opening and concluding comments -----
    //
    // Identified by markup, not wording — the classes below are byte-identical
    // across the Spanish and English workbooks:
    //   * opening line : music glyph + top rule, ABOVE the first colored h2
    //   * middle song  : music glyph, no rule, INSIDE a section
    //   * closing line : top rule, no music glyph, BELOW the last section
    if (tag == 'h3') {
      final hasMusic = className.contains(_cssMusic);
      final hasRule = className.contains(_cssRule);
      if (hasMusic && currentSection == null) {
        week.openingSong = _songNumber(text);
        week.introMinutes = _duration(text) ?? 1;
        continue;
      }
      if (hasRule && !hasMusic && currentSection != null) {
        week.closingSong = _songNumber(text);
        week.conclusionMinutes = _duration(text) ?? 3;
        continue;
      }
      if (hasMusic) {
        week.middleSong = _songNumber(text);
        continue;
      }
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
        isTalk: currentSection == Section.ministry &&
            _isTalk(title, _text(body), lang),
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
List<Week> parseEpub(Uint8List bytes, {String lang = 'S'}) {
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
    final week = parseWeek(xhtml, lang: lang);
    if (week.parts.isNotEmpty) weeks.add(week); // ignore cover/index
  }
  return weeks;
}
