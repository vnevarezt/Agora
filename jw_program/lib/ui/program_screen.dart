import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../data/epub_parser.dart';
import '../data/mwb_api.dart';
import '../models/week.dart';
import '../pdf/program_pdf.dart';
import '../schedule/rules.dart';

/// Pantalla principal: descarga el cuaderno mwb de jw.org, elige semana,
/// permite escribir los nombres de los participantes en campos editables con
/// vista previa EN TIEMPO REAL, y exporta el PDF (formato S-140-S).
class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final _issueCtrl = TextEditingController(text: '202605');
  final _congCtrl = TextEditingController(text: 'CONSTITUCIÓN J.A CASTRO');
  final _inicioCtrl = TextEditingController(text: '18:00');
  final _presidenteCtrl = TextEditingController();
  int _duracion = 105;

  List<Week>? _semanas;
  int _semanaIdx = 0;

  ProgramSchedule? _sched;
  // Controladores de los campos de nombre, por fila (uno por slot).
  final Map<ProgramRow, List<TextEditingController>> _nameCtrls = {};

  ui.Image? _previewImg; // página rasterizada (pdfium) para el live preview
  int _genSeq = 0; // descarta renders obsoletos
  Timer? _debounce;
  final TransformationController _tc = TransformationController();
  double _renderScale = 3.0; // resolución del raster; sube con el zoom

  bool _loading = false; // solo para descarga/exportación
  String? _error;

  @override
  void initState() {
    super.initState();
    // El nombre del presidente y la congregación también actualizan en vivo.
    _presidenteCtrl.addListener(_scheduleLive);
    _congCtrl.addListener(_scheduleLive);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _issueCtrl.dispose();
    _congCtrl.dispose();
    _inicioCtrl.dispose();
    _presidenteCtrl.dispose();
    _disposeNameCtrls();
    _previewImg?.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _disposeNameCtrls() {
    for (final list in _nameCtrls.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    _nameCtrls.clear();
  }

  int get _inicioMin {
    final p = _inicioCtrl.text.trim().split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
      _semanas = null;
      _previewImg?.dispose();
      _previewImg = null;
    });
    try {
      final bytes = await MwbApi.descargarEpub(_issueCtrl.text.trim());
      final semanas = parsearEpub(bytes);
      if (semanas.isEmpty) {
        throw Exception('No se encontraron semanas en el cuaderno.');
      }
      _semanas = semanas;
      _semanaIdx = 0;
      _prepararSemana();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Construye el horario de la semana seleccionada, crea los campos de nombre
  /// (con listeners para el live preview) y lanza un render inmediato.
  void _prepararSemana() {
    final semanas = _semanas;
    if (semanas == null) return;
    _disposeNameCtrls();
    final sched = construirFilas(semanas[_semanaIdx], _inicioMin, _duracion);
    for (final fila in [
      ...sched.apertura,
      ...sched.tesoros,
      ...sched.seamos,
      ...sched.vida,
    ]) {
      if (fila.slots > 0) {
        _nameCtrls[fila] = [
          for (var i = 0; i < fila.slots; i++)
            (TextEditingController(text: fila.nombres[i])
              ..addListener(_scheduleLive)),
        ];
      }
    }
    setState(() => _sched = sched);
    _generarLive(); // primer render sin esperar
  }

  /// Vuelca los campos editables a las filas y al nombre del presidente.
  void _aplicarNombres() {
    _nameCtrls.forEach((fila, ctrls) {
      for (var i = 0; i < ctrls.length; i++) {
        fila.nombres[i] = ctrls[i].text.trim();
      }
    });
  }

  Future<Uint8List?> _construirPdf() async {
    final semanas = _semanas;
    final sched = _sched;
    if (semanas == null || sched == null) return null;
    _aplicarNombres();
    return buildProgramPdf(
      cong: _congCtrl.text.trim(),
      semana: semanas[_semanaIdx],
      sched: sched,
      presidente: _presidenteCtrl.text.trim(),
    );
  }

  /// Al terminar un gesto de zoom, re-rasteriza a una resolución acorde al
  /// nivel de zoom para que se vea nítido (no un bitmap escalado/borroso).
  void _ajustarCalidadZoom() {
    final zoom = _tc.value.getMaxScaleOnAxis();
    final target = (zoom * 2.0).clamp(3.0, 6.0); // tope para no disparar memoria
    if ((target - _renderScale).abs() >= 0.5) {
      _renderScale = target;
      _generarLive(); // re-render más nítido sin tocar el transform (no salta)
    }
  }

  /// Debounce mínimo: coalesce pulsaciones rápidas sin perder la sensación de
  /// tiempo real (las fuentes están cacheadas, el render es de milisegundos).
  void _scheduleLive() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _generarLive);
  }

  Future<void> _generarLive() async {
    if (_sched == null) return;
    final seq = ++_genSeq;
    try {
      final pdf = await _construirPdf();
      if (pdf == null || seq != _genSeq) return; // render obsoleto
      // Rasteriza la página 1 con pdfium (pdfrx) -> funciona en escritorio.
      final img = await _rasterizar(pdf);
      if (!mounted || seq != _genSeq) {
        img.dispose();
        return;
      }
      setState(() {
        final anterior = _previewImg;
        _previewImg = img; // swap solo cuando está lista -> 0 parpadeo
        anterior?.dispose();
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  /// Renderiza la primera página del PDF a una imagen con pdfium (pdfrx).
  Future<ui.Image> _rasterizar(Uint8List pdf) async {
    final doc = await PdfDocument.openData(pdf);
    try {
      final page = doc.pages.first;
      final scale = _renderScale; // sube con el zoom para mantener nitidez
      final w = (page.width * scale).round();
      final h = (page.height * scale).round();
      final pdfImg = await page.render(
        width: w,
        height: h,
        fullWidth: w.toDouble(),
        fullHeight: h.toDouble(),
        backgroundColor: 0xFFFFFFFF, // hoja blanca
      );
      if (pdfImg == null) throw Exception('No se pudo rasterizar la página.');
      try {
        final completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          pdfImg.pixels,
          pdfImg.width,
          pdfImg.height,
          ui.PixelFormat.bgra8888, // pdfium entrega BGRA
          completer.complete,
        );
        return await completer.future;
      } finally {
        pdfImg.dispose();
      }
    } finally {
      await doc.dispose();
    }
  }

  Future<void> _exportar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pdf = await _construirPdf();
      if (pdf == null) return;
      // Carpeta de descargas (escritorio) o documentos (móvil).
      final dir =
          (await getDownloadsDirectory()) ?? await getApplicationDocumentsDirectory();
      final nombre = 'programa-${_issueCtrl.text.trim()}-s${_semanaIdx + 1}.pdf';
      final ruta = '${dir.path}${Platform.pathSeparator}$nombre';
      await File(ruta).writeAsBytes(pdf);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF exportado: $ruta')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JW Program — Vida y Ministerio')),
      body: Column(
        children: [
          _barraSuperior(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _sched == null
                ? const Center(
                    child: Text('Descarga un cuaderno para empezar.'),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 380, child: _editorNombres()),
                      const VerticalDivider(width: 1),
                      Expanded(child: _preview()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final img = _previewImg;
    if (img == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final aspect = img.width / img.height;
    return ColoredBox(
      color: const Color(0xFF9E9E9E), // fondo gris estilo Word
      child: LayoutBuilder(
        builder: (context, c) {
          const margen = 16.0;
          // La hoja arranca ajustada al ANCHO del panel -> texto en primer
          // plano. El usuario puede alejar (zoom out) para ver la hoja completa.
          final pageW = c.maxWidth - margen * 2;
          final pageH = pageW / aspect;
          final childW = c.maxWidth; // pageW + 2*margen
          final childH = pageH + margen * 2;

          // Fija una escala absoluta centrada en el viewport.
          void escalaCentrada(double s) {
            s = s.clamp(0.2, 6.0);
            final ntx = (c.maxWidth - childW * s) / 2;
            final nty = (c.maxHeight - childH * s) / 2;
            _tc.value = Matrix4.identity()
              ..translateByDouble(ntx, nty, 0, 1)
              ..scaleByDouble(s, s, s, 1);
            _ajustarCalidadZoom();
          }

          // Acerca/aleja un factor manteniendo fijo el centro del viewport.
          void zoom(double factor) {
            final m0 = _tc.value;
            final s0 = m0.getMaxScaleOnAxis();
            final ns = (s0 * factor).clamp(0.2, 6.0);
            final cx = c.maxWidth / 2, cy = c.maxHeight / 2;
            final spx = (cx - m0.storage[12]) / s0;
            final spy = (cy - m0.storage[13]) / s0;
            _tc.value = Matrix4.identity()
              ..translateByDouble(cx - ns * spx, cy - ns * spy, 0, 1)
              ..scaleByDouble(ns, ns, ns, 1);
            _ajustarCalidadZoom();
          }

          // Escala que hace caber TODA la hoja en el panel.
          final fitPage = (c.maxHeight / childH).clamp(0.2, 1.0);

          return Stack(
            children: [
              InteractiveViewer(
                constrained: false,
                minScale: 0.2, // alejar para ver toda la hoja
                maxScale: 6,
                boundaryMargin: const EdgeInsets.all(2000),
                transformationController: _tc,
                onInteractionEnd: (_) => _ajustarCalidadZoom(),
                child: Padding(
                  padding: const EdgeInsets.all(margen),
                  child: Container(
                    width: pageW,
                    height: pageH,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            spreadRadius: 1),
                      ],
                    ),
                    // RawImage solo cambia cuando la nueva imagen está lista (0 parpadeo);
                    // filterQuality.high -> mejor muestreo al hacer zoom.
                    child: RawImage(
                      image: img,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _zoomBtn(Icons.add, 'Acercar', () => zoom(1.3)),
                    const SizedBox(height: 8),
                    _zoomBtn(Icons.remove, 'Alejar', () => zoom(1 / 1.3)),
                    const SizedBox(height: 8),
                    _zoomBtn(Icons.fit_screen, 'Ver hoja completa',
                        () => escalaCentrada(fitPage)),
                    const SizedBox(height: 8),
                    _zoomBtn(Icons.width_normal, 'Ajustar al ancho',
                        () => _tc.value = Matrix4.identity()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _zoomBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return FloatingActionButton.small(
      heroTag: null,
      tooltip: tooltip,
      onPressed: onTap,
      child: Icon(icon),
    );
  }

  Widget _barraSuperior() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: _issueCtrl,
              decoration: const InputDecoration(
                labelText: 'Cuaderno (issue)',
                hintText: '202605',
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: _loading ? null : _cargar,
            child: const Text('Descargar'),
          ),
          if (_semanas != null)
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<int>(
                initialValue: _semanaIdx,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Semana'),
                items: [
                  for (var i = 0; i < _semanas!.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        '${i + 1}. ${_semanas![i].fecha}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _semanaIdx = v;
                  _prepararSemana();
                },
              ),
            ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _inicioCtrl,
              decoration: const InputDecoration(labelText: 'Inicio'),
              onSubmitted: (_) => _prepararSemana(),
            ),
          ),
          SizedBox(
            width: 110,
            child: TextFormField(
              initialValue: '$_duracion',
              decoration: const InputDecoration(labelText: 'Duración (min)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _duracion = int.tryParse(v) ?? 105,
              onFieldSubmitted: (_) => _prepararSemana(),
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              controller: _congCtrl,
              decoration: const InputDecoration(labelText: 'Congregación'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorNombres() {
    final sched = _sched!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Presidente.
              TextField(
                controller: _presidenteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Presidente',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ..._bloque('Apertura', sched.apertura),
              ..._bloque('Tesoros de la Biblia', sched.tesoros),
              ..._bloque('Seamos mejores maestros', sched.seamos),
              ..._bloque('Nuestra vida cristiana', sched.vida),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _exportar,
              icon: const Icon(Icons.ios_share),
              label: const Text('Exportar PDF'),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _bloque(String titulo, List<ProgramRow> filas) {
    final conNombre = filas.where((f) => f.slots > 0).toList();
    if (conNombre.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      for (final f in conNombre) _campoFila(f),
    ];
  }

  Widget _campoFila(ProgramRow f) {
    final ctrls = _nameCtrls[f]!;
    // Etiquetas para los dos nombres según el rol.
    final labels = ctrls.length == 2
        ? (f.rol.contains('Conductor')
            ? const ['Conductor', 'Lector']
            : const ['Estudiante', 'Ayudante'])
        : [f.rol.isNotEmpty ? f.rol.replaceAll(':', '') : 'Nombre'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${f.hora}  ${f.contenido}',
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              for (var i = 0; i < ctrls.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctrls[i],
                    decoration: InputDecoration(
                      labelText: labels[i],
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
