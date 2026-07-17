import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/files/file_saver.dart';
import '../pdf/pdf_rasterizer.dart';
import '../pdf/program_document.dart';
import 'program_form.dart';

/// Native save mechanism (dialog on desktop, share sheet on mobile).
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
    // Re-render when the structure, names or congregation/chairman/auxRoom change.
    ref.listen(scheduleProvider, (_, _) => _scheduleRender());
    ref.listen(assignmentsProvider, (_, _) => _scheduleRender());
    ref.listen(
      formProvider.select((f) => (f.congregationId, f.chairman, f.auxRoom)),
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
    final schedule = ref.read(scheduleProvider);
    final week = ref.read(currentWeekProvider);
    if (schedule == null || week == null) return;
    final seq = ++_seq;
    final f = ref.read(formProvider);
    try {
      final pdf = await buildProgramPdf(
        congregation: f.congregationId,
        week: week,
        schedule: schedule,
        assignments: ref.read(assignmentsProvider),
        chairman: f.chairman,
        auxRoom: f.auxRoom,
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

  /// Builds the PDF with the current data and hands it to the native save
  /// mechanism ([FileSaver]): save dialog on desktop, share sheet on mobile.
  Future<SaveOutcome> export() async {
    final schedule = ref.read(scheduleProvider);
    final week = ref.read(currentWeekProvider);
    if (schedule == null || week == null) {
      throw Exception('Descarga un cuaderno y elige una semana primero.');
    }
    final f = ref.read(formProvider);
    final pdf = await buildProgramPdf(
      congregation: f.congregationId,
      week: week,
      schedule: schedule,
      assignments: ref.read(assignmentsProvider),
      chairman: f.chairman,
      auxRoom: f.auxRoom,
    );
    return ref.read(fileSaverProvider).save(
          bytes: pdf,
          suggestedName: 'programa-${f.issue}-s${f.weekIndex + 1}.pdf',
          extension: 'pdf',
          mimeType: 'application/pdf',
          typeLabel: 'PDF',
        );
  }
}
