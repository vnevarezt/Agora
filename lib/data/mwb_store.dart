import 'dart:typed_data';

/// Where [MwbCache] keeps the notebook EPUBs and its manifest.
///
/// A named-blob store rather than a filesystem, because the browser has no
/// filesystem: native backs this with a directory, web with IndexedDB. Writes
/// must be atomic — an abrupt exit halfway through the manifest would leave the
/// cache describing files that are not there.
abstract interface class MwbStore {
  /// Null when [name] was never written.
  Future<String?> readString(String name);

  Future<void> writeString(String name, String contents);

  /// Null when [name] was never written.
  Future<Uint8List?> readBytes(String name);

  Future<void> writeBytes(String name, Uint8List bytes);
}
