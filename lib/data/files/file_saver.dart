import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

/// Where the bytes ended up after a save request.
sealed class SaveOutcome {
  const SaveOutcome();
}

/// Written where the user chose (desktop dialog or mobile document picker).
class SaveDone extends SaveOutcome {
  const SaveDone(this.path);

  final String path;
}

/// Handed to the native share sheet (WhatsApp, Mail, Drive, AirDrop…).
class SaveShared extends SaveOutcome {
  const SaveShared();
}

/// The user dismissed the dialog/sheet. Not an error: no feedback needed.
class SaveCanceled extends SaveOutcome {
  const SaveCanceled();
}

/// THE standardized file-out mechanism. Two explicit actions the user picks
/// between, both available on every platform:
///
/// * [saveAs] — the user chooses WHERE to save: native save dialog on
///   macOS/Windows/Linux (file_selector), document picker / SAF on
///   Android/iOS (file_picker).
/// * [share] — the native share sheet on every platform (share_plus).
///
/// The platform calls are injectable so unit tests can simulate
/// pick/cancel/share/save without plugins.
class FileSaver {
  FileSaver({
    bool? mobile,
    Future<String?> Function(String suggestedName, XTypeGroup type)?
        pickSavePath,
    Future<void> Function(String path, Uint8List bytes)? writeFile,
    Future<String?> Function(
            String suggestedName, String extension, Uint8List bytes)?
        saveMobile,
    Future<ShareResultStatus> Function(
            Uint8List bytes, String name, String mimeType, Rect? origin)?
        shareSheet,
  })  : _mobile = mobile ?? (Platform.isAndroid || Platform.isIOS),
        _pickSavePath = pickSavePath ?? _defaultPickSavePath,
        _writeFile = writeFile ?? _defaultWriteFile,
        _saveMobile = saveMobile ?? _defaultSaveMobile,
        _shareSheet = shareSheet ?? _defaultShareSheet;

  final bool _mobile;
  final Future<String?> Function(String, XTypeGroup) _pickSavePath;
  final Future<void> Function(String, Uint8List) _writeFile;
  final Future<String?> Function(String, String, Uint8List) _saveMobile;
  final Future<ShareResultStatus> Function(Uint8List, String, String, Rect?)
      _shareSheet;

  /// Prompts for a location and writes the bytes there.
  Future<SaveOutcome> saveAs({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
    String? typeLabel,
  }) async {
    if (_mobile) {
      final path = await _saveMobile(suggestedName, extension, bytes);
      return path == null ? const SaveCanceled() : SaveDone(path);
    }
    final path = await _pickSavePath(
      suggestedName,
      XTypeGroup(label: typeLabel ?? extension, extensions: [extension]),
    );
    if (path == null) return const SaveCanceled();
    await _writeFile(path, bytes);
    return SaveDone(path);
  }

  /// Opens the native share sheet. [originRect] anchors the popover on iPad and
  /// macOS (ignored elsewhere); pass the global rect of the button that opened it.
  Future<SaveOutcome> share({
    required Uint8List bytes,
    required String suggestedName,
    required String mimeType,
    Rect? originRect,
  }) async {
    final status = await _shareSheet(bytes, suggestedName, mimeType, originRect);
    return switch (status) {
      ShareResultStatus.success => const SaveShared(),
      ShareResultStatus.dismissed => const SaveCanceled(),
      ShareResultStatus.unavailable =>
        throw Exception('Share sheet unavailable on this device.'),
    };
  }

  static Future<String?> _defaultPickSavePath(
      String suggestedName, XTypeGroup type) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [type],
    );
    return location?.path;
  }

  static Future<void> _defaultWriteFile(String path, Uint8List bytes) =>
      File(path).writeAsBytes(bytes);

  static Future<String?> _defaultSaveMobile(
      String suggestedName, String extension, Uint8List bytes) {
    // On mobile `bytes` makes saveFile write through the document picker and
    // return the resulting path (null when the user backs out).
    return FilePicker.saveFile(
      fileName: suggestedName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
  }

  static Future<ShareResultStatus> _defaultShareSheet(
      Uint8List bytes, String name, String mimeType, Rect? origin) async {
    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType)],
      fileNameOverrides: [name],
      sharePositionOrigin: origin,
    ));
    return result.status;
  }
}
