import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

/// Rasterizes the first PDF page and encodes it as PNG bytes for export /
/// sharing. [dpi] sets the output resolution: 300 dpi on Letter ≈ 2550×3300 px
/// (3300×2550 landscape for two-per-sheet), sharp enough to print or send.
Future<Uint8List> renderPagePng(Uint8List pdf, {double dpi = 300}) async {
  final img = await rasterizePage(pdf, scale: dpi / 72);
  try {
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw Exception('No se pudo codificar la imagen.');
    return data.buffer.asUint8List();
  } finally {
    img.dispose();
  }
}

/// Rasterizes the first PDF page to an image using pdfium (pdfrx), which works
/// on desktop. `scale` raises the resolution for sharpness when zooming.
Future<ui.Image> rasterizePage(Uint8List pdf, {double scale = 3.0}) async {
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
      backgroundColor: 0xFFFFFFFF, // white sheet
    );
    if (img == null) throw Exception('Could not rasterize the page.');
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        img.pixels,
        img.width,
        img.height,
        ui.PixelFormat.bgra8888, // pdfium delivers BGRA
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
