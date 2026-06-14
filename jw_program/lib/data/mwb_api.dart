import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Access to jw.org's public media API to fetch the EPUB of the "Christian
/// Life and Ministry Meeting Workbook".
///
/// Port of `url_epub` / `descargar_epub` from generar_programa.py:33-49.
class MwbApi {
  static const String _api =
      'https://app.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS';

  /// Returns (url, formattedDate) of the EPUB for the given [issue] (YYYYMM).
  static Future<({String url, String date})> epubUrl(
    String issue, {
    String lang = 'S',
  }) async {
    final uri = Uri.parse(
      '$_api?langwritten=$lang&pub=mwb&fileformat=EPUB&issue=$issue',
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception(
        'No se encontró el EPUB para issue=$issue lang=$lang '
        '(HTTP ${resp.statusCode}).',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    try {
      final url = (((data['files'] as Map)[lang] as Map)['EPUB'] as List)[0]
          ['file']['url'] as String;
      final date = (data['formattedDate'] as String?) ?? '';
      return (url: url, date: date);
    } catch (_) {
      throw Exception('No se encontró el EPUB para issue=$issue lang=$lang.');
    }
  }

  /// Downloads the whole EPUB into memory (bytes).
  static Future<Uint8List> downloadEpub(String issue, {String lang = 'S'}) async {
    final info = await epubUrl(issue, lang: lang);
    final resp = await http.get(Uri.parse(info.url));
    if (resp.statusCode != 200) {
      throw Exception('Error al descargar el EPUB (HTTP ${resp.statusCode}).');
    }
    return resp.bodyBytes;
  }
}
