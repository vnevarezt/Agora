import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/files/file_saver.dart';
import '../pdf/pdf_rasterizer.dart';
import '../pdf/program_document.dart';
import 'app_settings.dart';
import 'program_form.dart';
import 'weeks_provider.dart';

/// Output file kind the user picked in the export menu.
enum ExportFormat { pdf, png }

/// What to do with the exported bytes.
enum ExportAction {
  /// Pick a location and write the file there (dialog / document picker).
  saveAs,

  /// Hand to the native share sheet (WhatsApp, Mail, Drive, AirDrop…).
  share,
}

/// Native save mechanism (dialog on desktop, document picker on mobile) and
/// the share sheet.
final fileSaverProvider = Provider<FileSaver>((ref) => FileSaver());

/// Live preview: rasterizes the page (pdfium) when the data changes, with a
/// debounce so typing feels real-time.
final previewProvider =
    NotifierProvider<PreviewController, AsyncValue<ui.Image>>(
        PreviewController.new);

class PreviewController extends Notifier<AsyncValue<ui.Image>> {
  Timer? _debounce;
  int _seq = 0; // discards stale renders
  double _scale = 3.0; // raster resolution; grows with zoom
  ui.Image? _current;

  @override
  AsyncValue<ui.Image> build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _current?.dispose();
    });
    // Re-render when the sheet's content changes. [sheetEntriesProvider] already
    // covers the week(s), schedule, names, chairman and the two-per-sheet flag;
    // congregation and auxRoom are document-level, watched separately.
    ref.listen(sheetEntriesProvider, (_, _) => _scheduleRender());
    ref.listen(
      formProvider.select((f) => (f.congregationId, f.auxRoom)),
      (_, _) => _scheduleRender(),
    );
    _scheduleRender();
    return const AsyncValue.loading();
  }

  void _scheduleRender() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _render);
  }

  Future<void> _render() async {
    final entries = ref.read(sheetEntriesProvider);
    if (entries.isEmpty) return;
    final seq = ++_seq;
    final f = ref.read(formProvider);
    final twoUp = ref.read(twoPerSheetProvider);
    try {
      final pdf = await buildProgramSheetPdf(
        congregation: f.congregationId,
        entries: entries,
        auxRoom: f.auxRoom,
        twoPerSheet: twoUp,
      );
      final img = await rasterizePage(pdf, scale: _scale);
      if (seq != _seq) {
        img.dispose();
        return;
      }
      _current?.dispose();
      _current = img;
      state = AsyncValue.data(img);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Re-rasterizes at higher resolution based on the zoom level (sharpness).
  void adjustZoomQuality(double zoom) {
    final target = (zoom * 2.0).clamp(3.0, 6.0);
    if ((target - _scale).abs() >= 0.5) {
      _scale = target;
      _render();
    }
  }

  /// Builds the current sheet in [format] and either saves it where the user
  /// chooses or opens the share sheet, per [action]. [shareOrigin] anchors the
  /// share popover on iPad/macOS (global rect of the button that opened it).
  Future<SaveOutcome> export({
    required ExportFormat format,
    required ExportAction action,
    ui.Rect? shareOrigin,
  }) async {
    final entries = ref.read(sheetEntriesProvider);
    if (entries.isEmpty) {
      throw Exception('Descarga un cuaderno y elige una semana primero.');
    }
    final f = ref.read(formProvider);
    final twoUp = ref.read(twoPerSheetProvider);
    final pdf = await buildProgramSheetPdf(
      congregation: f.congregationId,
      entries: entries,
      auxRoom: f.auxRoom,
      twoPerSheet: twoUp,
    );

    final Uint8List bytes;
    final String extension;
    final String mimeType;
    switch (format) {
      case ExportFormat.pdf:
        bytes = pdf;
        extension = 'pdf';
        mimeType = 'application/pdf';
      case ExportFormat.png:
        bytes = await renderPagePng(pdf);
        extension = 'png';
        mimeType = 'image/png';
    }

    final name = _suggestedName(f, twoUp, extension);
    final saver = ref.read(fileSaverProvider);
    return switch (action) {
      ExportAction.saveAs => saver.saveAs(
          bytes: bytes,
          suggestedName: name,
          extension: extension,
          mimeType: mimeType,
          typeLabel: extension.toUpperCase(),
        ),
      ExportAction.share => saver.share(
          bytes: bytes,
          suggestedName: name,
          mimeType: mimeType,
          originRect: shareOrigin,
        ),
    };
  }

  /// e.g. `programa-202605-s3.pdf` (one week) or `programa-202605-s3-s4.png`
  /// (two-per-sheet). The suffix lists every week printed on the sheet.
  String _suggestedName(FormModel f, bool twoUp, String extension) {
    final weeks = ref.read(weeksProvider).asData?.value ?? const [];
    final indices = sheetWeekIndices(f.weekIndex, weeks.length, twoUp);
    final label = indices.map((i) => 's${i + 1}').join('-');
    return 'programa-${f.issue}-$label.$extension';
  }
}
