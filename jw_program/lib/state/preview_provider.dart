import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../pdf/pdf_rasterizer.dart';
import '../pdf/program_document.dart';
import 'program_form.dart';

/// Vista previa en vivo: rasteriza la página (pdfium) cuando cambian los datos,
/// con debounce para que escribir se sienta en tiempo real.
final previewProvider =
    NotifierProvider<PreviewController, AsyncValue<ui.Image>>(
        PreviewController.new);

class PreviewController extends Notifier<AsyncValue<ui.Image>> {
  Timer? _debounce;
  int _seq = 0; // descarta renders obsoletos
  double _scale = 3.0; // resolución del raster; sube con el zoom
  ui.Image? _actual;

  @override
  AsyncValue<ui.Image> build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _actual?.dispose();
    });
    // Re-render cuando cambian estructura, nombres o congregación/presidente/aux.
    ref.listen(scheduleProvider, (_, _) => _programar());
    ref.listen(assignmentsProvider, (_, _) => _programar());
    ref.listen(
      formProvider.select((f) => (f.cong, f.presidente, f.aux)),
      (_, _) => _programar(),
    );
    _programar();
    return const AsyncValue.loading();
  }

  void _programar() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _render);
  }

  Future<void> _render() async {
    final sched = ref.read(scheduleProvider);
    final semana = ref.read(currentWeekProvider);
    if (sched == null || semana == null) return;
    final seq = ++_seq;
    final f = ref.read(formProvider);
    try {
      final pdf = await buildProgramPdf(
        cong: f.cong,
        semana: semana,
        sched: sched,
        asignaciones: ref.read(assignmentsProvider),
        presidente: f.presidente,
        aux: f.aux,
      );
      final img = await rasterizarPagina(pdf, scale: _scale);
      if (seq != _seq) {
        img.dispose();
        return;
      }
      _actual?.dispose();
      _actual = img;
      state = AsyncValue.data(img);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Re-rasteriza a mayor resolución según el nivel de zoom (nitidez).
  void ajustarCalidadZoom(double zoom) {
    final target = (zoom * 2.0).clamp(3.0, 6.0);
    if ((target - _scale).abs() >= 0.5) {
      _scale = target;
      _render();
    }
  }

  /// Construye el PDF con los datos actuales y lo guarda en Descargas.
  /// Devuelve la ruta del archivo.
  Future<String> exportar() async {
    final sched = ref.read(scheduleProvider);
    final semana = ref.read(currentWeekProvider);
    if (sched == null || semana == null) {
      throw Exception('Descarga un cuaderno y elige una semana primero.');
    }
    final f = ref.read(formProvider);
    final pdf = await buildProgramPdf(
      cong: f.cong,
      semana: semana,
      sched: sched,
      asignaciones: ref.read(assignmentsProvider),
      presidente: f.presidente,
      aux: f.aux,
    );
    final dir =
        (await getDownloadsDirectory()) ?? await getApplicationDocumentsDirectory();
    final ruta =
        '${dir.path}${Platform.pathSeparator}programa-${f.issue}-s${f.semanaIdx + 1}.pdf';
    await File(ruta).writeAsBytes(pdf);
    return ruta;
  }
}
