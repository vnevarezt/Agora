import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/files/file_saver.dart';
import '../../i18n/strings.g.dart';
import '../../state/preview_provider.dart';
import '../../state/ui_state.dart';

/// Runs one export (build → save-as or share) and reports the outcome via a
/// snackbar. Shared by the desktop export menu and the mobile export sheet so
/// both behave identically. [context] must stay mounted for the messenger, so
/// pass a bar/screen context, not a menu item that closes first.
Future<void> runExport(
  BuildContext context,
  WidgetRef ref, {
  required ExportFormat format,
  required ExportAction action,
  Rect? shareOrigin,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final tr = context.t;
  ref.read(exportBusyProvider.notifier).set(true);
  try {
    final outcome = await ref.read(previewProvider.notifier).export(
          format: format,
          action: action,
          shareOrigin: shareOrigin,
        );
    switch (outcome) {
      case SaveDone(:final path):
        messenger.showSnackBar(
            SnackBar(content: Text(tr.export.success(path: path))));
      case SaveShared():
        messenger.showSnackBar(SnackBar(content: Text(tr.export.shared)));
      case SaveCanceled():
        break; // user's choice, no feedback needed
    }
  } catch (e) {
    messenger
        .showSnackBar(SnackBar(content: Text(tr.export.error(error: e))));
  } finally {
    ref.read(exportBusyProvider.notifier).set(false);
  }
}

/// Global rect of the widget at [context], used to anchor the share popover on
/// iPad/macOS. Null when the box isn't laid out yet.
Rect? originRectOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
