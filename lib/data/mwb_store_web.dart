import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'mwb_store.dart';

/// IndexedDB, because notebook EPUBs run to megabytes and localStorage caps out
/// around five for the whole origin.
///
/// One object store keyed by name, holding strings and byte arrays alike. Every
/// IndexedDB write is already transactional, so the `.tmp` + rename dance the
/// native store needs has no counterpart here.
class IndexedDbMwbStore implements MwbStore {
  static const _dbName = 'agora_mwb_cache';
  static const _storeName = 'blobs';

  Future<web.IDBDatabase>? _db;

  Future<web.IDBDatabase> _open() => _db ??= () async {
        final request = web.window.indexedDB.open(_dbName, 1);
        request.onupgradeneeded = ((web.Event _) {
          final db = request.result as web.IDBDatabase;
          if (!db.objectStoreNames.contains(_storeName)) {
            db.createObjectStore(_storeName);
          }
        }).toJS;
        return await _request<web.IDBDatabase>(request);
      }();

  /// IndexedDB is callback-based; every call funnels through here to become a
  /// Future.
  static Future<T> _request<T extends JSAny?>(web.IDBRequest request) {
    final completer = Completer<T>();
    request.onsuccess = ((web.Event _) {
      completer.complete(request.result as T);
    }).toJS;
    request.onerror = ((web.Event _) {
      completer.completeError(
          StateError('IndexedDB request failed: ${request.error?.message}'));
    }).toJS;
    return completer.future;
  }

  Future<JSAny?> _read(String name) async {
    final db = await _open();
    final tx = db.transaction(_storeName.toJS, 'readonly');
    final store = tx.objectStore(_storeName);
    return _request<JSAny?>(store.get(name.toJS));
  }

  Future<void> _write(String name, JSAny value) async {
    final db = await _open();
    final tx = db.transaction(_storeName.toJS, 'readwrite');
    final store = tx.objectStore(_storeName);
    await _request<JSAny?>(store.put(value, name.toJS));
  }

  @override
  Future<String?> readString(String name) async =>
      (await _read(name) as JSString?)?.toDart;

  @override
  Future<void> writeString(String name, String contents) =>
      _write(name, contents.toJS);

  @override
  Future<Uint8List?> readBytes(String name) async {
    final value = await _read(name);
    if (value == null) return null;
    // Round-trips as an ArrayBuffer, not the Uint8Array that went in.
    if (value.instanceOfString('ArrayBuffer')) {
      return (value as JSArrayBuffer).toDart.asUint8List();
    }
    return (value as JSUint8Array).toDart;
  }

  @override
  Future<void> writeBytes(String name, Uint8List bytes) =>
      _write(name, bytes.toJS);
}

MwbStore defaultMwbStore() => IndexedDbMwbStore();
