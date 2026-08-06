import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// Android and iOS route saves through the document picker instead of a
/// location dialog.
bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;

/// Native save dialog. Null when the user dismissed it.
Future<String?> pickSavePath(String suggestedName, XTypeGroup type) async {
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: [type],
  );
  return location?.path;
}

Future<void> writeFile(String path, Uint8List bytes) =>
    File(path).writeAsBytes(bytes);
