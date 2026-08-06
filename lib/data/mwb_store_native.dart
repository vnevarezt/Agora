import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'mwb_store.dart';

/// Files under `<application support>/mwb_cache`, the same base as the
/// encrypted DB. [root] is injectable so tests can point at a temp directory.
class DirectoryMwbStore implements MwbStore {
  DirectoryMwbStore({Directory? root}) : _root = root;

  final Directory? _root;
  Directory? _resolved;

  Future<Directory> _dir() async {
    if (_resolved != null) return _resolved!;
    final base = _root ?? await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}mwb_cache');
    await dir.create(recursive: true);
    return _resolved = dir;
  }

  Future<File> _file(String name) async =>
      File('${(await _dir()).path}${Platform.pathSeparator}$name');

  @override
  Future<String?> readString(String name) async {
    final f = await _file(name);
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  @override
  Future<void> writeString(String name, String contents) async {
    // .tmp + rename so an abrupt exit cannot leave a half-written manifest.
    final f = await _file(name);
    final tmp = await _file('$name.tmp');
    await tmp.writeAsString(contents, flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<Uint8List?> readBytes(String name) async {
    final f = await _file(name);
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }

  @override
  Future<void> writeBytes(String name, Uint8List bytes) async {
    await (await _file(name)).writeAsBytes(bytes, flush: true);
  }
}

MwbStore defaultMwbStore() => DirectoryMwbStore();
