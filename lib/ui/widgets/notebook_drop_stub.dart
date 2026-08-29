import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Nothing here can take a dropped file, so nothing should offer to.
const bool notebookDropSupported = false;

/// No-op outside the browser: dropping a file onto a desktop window is the
/// platform's business, and nothing here has an answer for it yet. The web
/// build is the one that needs this — it is the build that cannot fetch the
/// workbook itself.
class NotebookDropTarget extends StatelessWidget {
  const NotebookDropTarget({
    super.key,
    required this.onFile,
    required this.builder,
  });

  final void Function(Uint8List bytes) onFile;
  final Widget Function(BuildContext context, bool hovering) builder;

  @override
  Widget build(BuildContext context) => builder(context, false);
}
