import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Acceso a la API pública de medios de jw.org para obtener el EPUB del
/// cuaderno "Guía de actividades para la reunión Vida y Ministerio Cristianos".
///
/// Port de `url_epub` / `descargar_epub` de generar_programa.py:33-49.
class MwbApi {
  static const String _api =
      'https://app.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS';

  /// Devuelve (url, fechaFormateada) del EPUB para el [issue] dado (YYYYMM).
  static Future<({String url, String fecha})> epubUrl(
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
      final fecha = (data['formattedDate'] as String?) ?? '';
      return (url: url, fecha: fecha);
    } catch (_) {
      throw Exception('No se encontró el EPUB para issue=$issue lang=$lang.');
    }
  }

  /// Descarga el EPUB completo en memoria (bytes).
  static Future<Uint8List> downloadEpub(String issue, {String lang = 'S'}) async {
    final info = await epubUrl(issue, lang: lang);
    final resp = await http.get(Uri.parse(info.url));
    if (resp.statusCode != 200) {
      throw Exception('Error al descargar el EPUB (HTTP ${resp.statusCode}).');
    }
    return resp.bodyBytes;
  }
}
