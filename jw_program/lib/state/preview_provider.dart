import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../pdf/pdf_rasterizer.dart';
import '../pdf/program_document.dart';
import 'program_form.dart';

/// Vista previa en vivo: rasteriza la página (pdfium) when cambian los datos,
/// con debounce para que escribir se sienta en tiempo real.
final previewProvider =
    NotifierProvider<PreviewController, AsyncValue<ui.Image>>(
        PreviewController.new);

class PreviewController extends Notifier<AsyncValue<ui.Image>> {
  Timer? _debounce;
  int _seq = 0; // descarta renders obsoletos
  double _scale = 3.0; // resolución del raster; sube con el zoom
  ui.Image? _current;

  @override
  AsyncValue<ui.Image> build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _current?.dispose();
    });
    // Re-render when cambian estructura, nombres o congregación/presidente/auxRoom.
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
      final img = await rasterizarPagina(pdf, scale: _scale);
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

  /// Re-rasteriza a mayor resolución según el nivel de zoom (nitidez).
  void adjustZoomQuality(double zoom) {
    final target = (zoom * 2.0).clamp(3.0, 6.0);
    if ((target - _scale).abs() >= 0.5) {
      _scale = target;
      _render();
    }
  }

  /// Construye el PDF con los datos actuales y lo guarda en Descargas.
  /// Devuelve la path del archivo.
  Future<String> export() async {
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
    final dir =
        (await getDownloadsDirectory()) ?? await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}programa-${f.issue}-s${f.weekIndex + 1}.pdf';
    await File(path).writeAsBytes(pdf);
    return path;
  }
}
