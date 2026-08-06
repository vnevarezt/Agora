import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:web/web.dart' as web;

/// Browsers have no document picker; [pickSavePath] plus [writeFile] cover the
/// whole flow.
bool get isMobilePlatform => false;

/// There is no location to pick: the browser decides where downloads land, and
/// asks the user itself when configured to. Returning the suggested name keeps
/// [FileSaver.saveAs] on its normal path — a null here would read as a cancel —
/// and gives the "saved" message something to show. [type] is unused: the
/// download carries its extension in the file name.
Future<String?> pickSavePath(String suggestedName, XTypeGroup type) async =>
    suggestedName;

/// Hands the bytes to the browser as a download named [path].
///
/// The object URL is revoked on the next task rather than immediately: Safari
/// abandons the download if the URL dies while the click is still being
/// dispatched.
Future<void> writeFile(String path, Uint8List bytes) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = path
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(Duration.zero, () => web.URL.revokeObjectURL(url));
}
