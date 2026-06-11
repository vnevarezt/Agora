import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

/// Rasteriza la primera página del PDF a una imagen usando pdfium (pdfrx), que
/// funciona en escritorio. `scale` sube la resolución para nitidez al hacer zoom.
Future<ui.Image> rasterizarPagina(Uint8List pdf, {double scale = 3.0}) async {
  final doc = await PdfDocument.openData(pdf);
  try {
    final page = doc.pages.first;
    final w = (page.width * scale).round();
    final h = (page.height * scale).round();
    final img = await page.render(
      width: w,
      height: h,
      fullWidth: w.toDouble(),
      fullHeight: h.toDouble(),
      backgroundColor: 0xFFFFFFFF, // hoja blanca
    );
    if (img == null) throw Exception('No se pudo rasterizar la página.');
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        img.pixels,
        img.width,
        img.height,
        ui.PixelFormat.bgra8888, // pdfium entrega BGRA
        completer.complete,
      );
      return await completer.future;
    } finally {
      img.dispose();
    }
  } finally {
    await doc.dispose();
  }
}
