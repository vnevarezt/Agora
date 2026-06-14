import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/week.dart';

/// Parseo del EPUB del cuaderno mwb -> list de semanas.
///
/// Port 1:1 de `parsear_epub` / `parsear_semana` / `_texto` / `_duracion`
/// de generar_programa.py:54-124. Conserva las MISMAS expresiones regulares.

// color del encabezado en el EPUB -> sección (SECCION_POR_COLOR, py:24-28)
const Map<String, Section> _seccionPorColor = {
  'teal': Section.treasures,
  'gold': Section.ministry,
  'maroon': Section.christianLife,
};

final _rePageNum = RegExp(
    r'<span[^>]*class="[^"]*pageNum[^"]*"[^>]*>.*?</span>',
    dotAll: true);
final _reSup = RegExp(r'<sup\b[^>]*>.*?</sup>', dotAll: true);
final _reTags = RegExp(r'<[^>]+>');
final _reEspacios = RegExp(r'\s+');
final _reDuracion = RegExp(r'\((\d+)\s*mins?\.?\)');
final _reEncabezados =
    RegExp(r'<(h[123])\b([^>]*)>(.*?)</\1>', dotAll: true);
final _reColor = RegExp(r'du-color--(teal|gold|maroon)');
final _reClase = RegExp(r'class="([^"]*)"');
final _reCancion = RegExp('Canci[óo]n\\s+(\\d+)');
final _reCancionSola = RegExp(r'^Canci[óo]n\s+\d+$');
final _reParteNum = RegExp(r'^(\d+)\.\s+(.*)$', dotAll: true);
final _reArchivoSemana = RegExp(r'^OEBPS/\d+\.xhtml$');

/// HTML -> texto clean (sin etiquetas, sin nº de página ni superíndices).
String _texto(String frag) {
  frag = frag.replaceAll(_rePageNum, '');
  frag = frag.replaceAll(_reSup, ''); // marcas de nota
  frag = frag.replaceAll(_reTags, ''); // conserva el texto
  // html.unescape equivalente: decodifica entidades (&amp;, &#160;, …)
  final unescaped = html_parser.parseFragment(frag).text ?? '';
  return unescaped.replaceAll(_reEspacios, ' ').trim();
}

int? _duracion(String segmento) {
  final m = _reDuracion.firstMatch(segmento);
  return m != null ? int.parse(m.group(1)!) : null;
}

Week parseWeek(String xhtml) {
  // Posiciones de todos los encabezados h1/h2/h3 en orden de aparición.
  final enc = _reEncabezados.allMatches(xhtml).toList();
  final semana = Week();
  Section? seccionActual;

  for (var i = 0; i < enc.length; i++) {
    final m = enc[i];
    final tag = m.group(1)!;
    final attrs = m.group(2)!;
    final inner = m.group(3)!;
    final fin = (i + 1 < enc.length) ? enc[i + 1].start : xhtml.length;
    final cuerpo = xhtml.substring(m.end, fin);
    final texto = _texto(inner);
    final claseMatch = _reClase.firstMatch(attrs);
    final clase = claseMatch != null ? claseMatch.group(1)! : '';

    // ----- sección (h2 de color) -----
    final col = _reColor.firstMatch(clase);
    if (tag == 'h2' && col != null) {
      seccionActual = _seccionPorColor[col.group(1)];
      continue;
    }
    // ----- canciones / palabras de introducción y conclusión -----
    final low = texto.toLowerCase();
    final mcan = _reCancion.firstMatch(texto);
    if (low.contains('palabras de introducci')) {
      if (mcan != null) semana.openingSong = mcan.group(1);
      semana.introMinutes = _duracion(texto) ?? 1;
      continue;
    }
    if (low.contains('palabras de conclusi')) {
      if (mcan != null) semana.closingSong = mcan.group(1);
      semana.conclusionMinutes = _duracion(texto) ?? 3;
      continue;
    }
    if (mcan != null &&
        (clase.contains('dc-icon--music') ||
            _reCancionSola.hasMatch(texto))) {
      semana.middleSong = mcan.group(1);
      continue;
    }
    // ----- parte numerada (h3 'N. Título') -----
    final mnum = _reParteNum.firstMatch(texto);
    if (tag == 'h3' && mnum != null && seccionActual != null) {
      final num = int.parse(mnum.group(1)!);
      final titulo = mnum.group(2)!.trim();
      final dur = _duracion(cuerpo) ?? _duracion(texto);
      semana.parts.add(Part(
        section: seccionActual,
        number: num,
        title: titulo,
        minutes: dur,
      ));
      continue;
    }
    // ----- fecha (primer h1) y lectura (h2 antes de TESOROS) -----
    if (tag == 'h1' && semana.date.isEmpty) {
      semana.date = texto.toUpperCase();
    } else if (tag == 'h2' &&
        seccionActual == null &&
        semana.reading.isEmpty &&
        texto.isNotEmpty) {
      semana.reading = texto;
    }
  }
  return semana;
}

/// Parsea el EPUB completo (bytes) y devuelve las semanas con partes.
List<Week> parseEpub(Uint8List bytes) {
  final archivo = ZipDecoder().decodeBytes(bytes);
  // Los archivos semanales son OEBPS/NNNNNNNNN.xhtml (sin '-extracted').
  final nombres = archivo.files
      .where((f) => f.isFile && _reArchivoSemana.hasMatch(f.name))
      .map((f) => f.name)
      .toList()
    ..sort();
  final semanas = <Week>[];
  for (final n in nombres) {
    final f = archivo.findFile(n)!;
    final xhtml = utf8.decode(f.content as List<int>);
    final s = parseWeek(xhtml);
    if (s.parts.isNotEmpty) semanas.add(s); // ignora portada/índices
  }
  return semanas;
}
