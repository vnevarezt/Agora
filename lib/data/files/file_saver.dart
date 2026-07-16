import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

/// Where the bytes ended up after a save request.
sealed class SaveOutcome {
  const SaveOutcome();
}

/// Desktop: written where the user chose in the native save dialog.
class SaveDone extends SaveOutcome {
  const SaveDone(this.path);

  final String path;
}

/// Mobile: handed to the native share sheet (Files, Drive, AirDrop…).
class SaveShared extends SaveOutcome {
  const SaveShared();
}

/// The user dismissed the dialog/sheet. Not an error: no feedback needed.
class SaveCanceled extends SaveOutcome {
  const SaveCanceled();
}

/// THE standardized "save a file" mechanism (phase 1-B): native save dialog
/// on macOS/Windows/Linux (file_selector), native share sheet on
/// Android/iOS (share_plus). Every export — PDF today, backups later —
/// must go through here so all platforms behave natively.
///
/// The platform calls are injectable so unit tests can simulate
/// pick/cancel/share without plugins.
class FileSaver {
  FileSaver({
    bool? useShareSheet,
    Future<String?> Function(String suggestedName, XTypeGroup type)?
        pickSavePath,
    Future<ShareResultStatus> Function(
            Uint8List bytes, String name, String mimeType)?
        shareSheet,
    Future<void> Function(String path, Uint8List bytes)? writeFile,
  })  : _useShareSheet =
            useShareSheet ?? (Platform.isAndroid || Platform.isIOS),
        _pickSavePath = pickSavePath ?? _defaultPickSavePath,
        _shareSheet = shareSheet ?? _defaultShareSheet,
        _writeFile = writeFile ?? _defaultWriteFile;

  final bool _useShareSheet;
  final Future<String?> Function(String, XTypeGroup) _pickSavePath;
  final Future<ShareResultStatus> Function(Uint8List, String, String)
      _shareSheet;
  final Future<void> Function(String, Uint8List) _writeFile;

  Future<SaveOutcome> save({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
    String? typeLabel,
  }) async {
    if (_useShareSheet) {
      final status = await _shareSheet(bytes, suggestedName, mimeType);
      return switch (status) {
        ShareResultStatus.success => const SaveShared(),
        ShareResultStatus.dismissed => const SaveCanceled(),
        ShareResultStatus.unavailable =>
          throw Exception('Share sheet unavailable on this device.'),
      };
    }

    final path = await _pickSavePath(
      suggestedName,
      XTypeGroup(label: typeLabel ?? extension, extensions: [extension]),
    );
    if (path == null) return const SaveCanceled();
    await _writeFile(path, bytes);
    return SaveDone(path);
  }

  static Future<String?> _defaultPickSavePath(
      String suggestedName, XTypeGroup type) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [type],
    );
    return location?.path;
  }

  static Future<ShareResultStatus> _defaultShareSheet(
      Uint8List bytes, String name, String mimeType) async {
    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType)],
      fileNameOverrides: [name],
    ));
    return result.status;
  }

  static Future<void> _defaultWriteFile(String path, Uint8List bytes) =>
      File(path).writeAsBytes(bytes);
}
