import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The browser can hand a dropped file straight over.
const bool notebookDropSupported = true;

/// Takes an `.epub` dropped anywhere on the page and hands back its bytes.
///
/// Listens on the document rather than on its own box: Flutter paints to a
/// canvas, so there is no element under the modal for the browser to aim a
/// drop at, and a target the size of the drop zone would miss every drop that
/// lands an inch off. While this is mounted the whole page takes the file.
///
/// The bytes come from a [web.FileReader], not from the file's `blob:` URL.
/// Reading through the URL is what the file picker does, and it costs an XHR
/// that `connect-src` has to be widened for; a FileReader reads the dropped
/// File object directly and never touches the network at all.
class NotebookDropTarget extends StatefulWidget {
  const NotebookDropTarget({
    super.key,
    required this.onFile,
    required this.builder,
  });

  final void Function(Uint8List bytes) onFile;

  /// `hovering` is true while a dragged file is over the page, so the drop
  /// zone can light up — otherwise there is nothing telling the person that
  /// letting go will do something.
  final Widget Function(BuildContext context, bool hovering) builder;

  @override
  State<NotebookDropTarget> createState() => _NotebookDropTargetState();
}

class _NotebookDropTargetState extends State<NotebookDropTarget> {
  bool _hovering = false;

  late final JSFunction _onDragOver;
  late final JSFunction _onDragLeave;
  late final JSFunction _onDrop;

  @override
  void initState() {
    super.initState();
    // Without preventDefault on BOTH, the browser handles the drop itself and
    // navigates to the file — which on a single-page app means the app is
    // gone, unsaved work and all. dragover in particular: not cancelling it
    // tells the browser this is not a drop target, and no drop event follows.
    _onDragOver = ((web.Event event) {
      event.preventDefault();
      if (!_hovering) setState(() => _hovering = true);
    }).toJS;
    _onDragLeave = ((web.Event _) {
      if (_hovering) setState(() => _hovering = false);
    }).toJS;
    _onDrop = ((web.Event event) {
      event.preventDefault();
      if (_hovering) setState(() => _hovering = false);
      final files = (event as web.DragEvent).dataTransfer?.files;
      if (files == null) return;
      for (var i = 0; i < files.length; i++) {
        final file = files.item(i);
        if (file != null && file.name.toLowerCase().endsWith('.epub')) {
          unawaited(_read(file));
          return;
        }
      }
    }).toJS;

    web.document.addEventListener('dragover', _onDragOver);
    web.document.addEventListener('dragleave', _onDragLeave);
    web.document.addEventListener('drop', _onDrop);
  }

  Future<void> _read(web.File file) async {
    final completer = Completer<Uint8List?>();
    final reader = web.FileReader();
    reader.onload = ((web.Event _) {
      final result = reader.result;
      completer.complete(result == null
          ? null
          : (result as JSArrayBuffer).toDart.asUint8List());
    }).toJS;
    reader.onerror = ((web.Event _) => completer.complete(null)).toJS;
    reader.readAsArrayBuffer(file);

    final bytes = await completer.future;
    if (bytes != null && mounted) widget.onFile(bytes);
  }

  @override
  void dispose() {
    web.document.removeEventListener('dragover', _onDragOver);
    web.document.removeEventListener('dragleave', _onDragLeave);
    web.document.removeEventListener('drop', _onDrop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _hovering);
}
