import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_transport.dart';

/// Why a transport call failed — the controller reacts differently to a
/// revocation (stop that congregation, keep data) than to a dead network
/// (back off and retry).
enum SyncTransportErrorKind { permissionDenied, offline, unknown }

class SyncTransportException implements Exception {
  const SyncTransportException(this.kind, this.message, [this.cause]);

  final SyncTransportErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// `serverTs` wire form is a native Firestore [Timestamp]; the 4a contract
/// (and `SyncState.pullCursor`) wants a lexicographically sortable STRING.
/// `'{seconds pad 12}.{nanos pad 9}'` is both sortable and losslessly
/// parseable back for the `where serverTs >` query.
String encodeServerTs(Timestamp ts) =>
    '${ts.seconds.toString().padLeft(12, '0')}.'
    '${ts.nanoseconds.toString().padLeft(9, '0')}';

Timestamp decodeServerTs(String cursor) {
  final dot = cursor.indexOf('.');
  return Timestamp(
    int.parse(cursor.substring(0, dot)),
    int.parse(cursor.substring(dot + 1)),
  );
}

/// The 4b [SyncTransport]: one doc per entity under
/// `congregations/{cid}/items/{entityId}` (DATA_ARCHITECTURE.md §4).
class FirestoreTransport implements SyncTransport {
  FirestoreTransport(this._db);

  final FirebaseFirestore _db;

  /// Page size for [pullSince]; callers drain by looping while a page is
  /// non-empty.
  static const pageSize = 300;

  /// With Firestore's own cache disabled, an offline write neither fails
  /// fast nor completes: bound it so pushOnce surfaces `offline` instead of
  /// hanging (the outbox entry stays and re-pushes later).
  static const _writeTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _items(String cid) =>
      _db.collection('congregations').doc(cid).collection('items');

  /// The tiny heartbeat doc peers listen to instead of the items firehose:
  /// `{scopes: {scope: serverTs}, srcDevice}`.
  DocumentReference<Map<String, dynamic>> _activity(String cid) => _db
      .collection('congregations')
      .doc(cid)
      .collection('meta')
      .doc('activity');

  /// Firestore caps a batch at 500 ops; keep headroom for the activity bump.
  static const _batchLimit = 450;

  @override
  Future<void> upsertItems(
    String congregationId,
    List<ItemDoc> docs,
    Set<String> activityScopes,
  ) =>
      _guard(() async {
        for (var start = 0; start < docs.length; start += _batchLimit) {
          final chunk = docs.sublist(
              start,
              start + _batchLimit > docs.length
                  ? docs.length
                  : start + _batchLimit);
          final batch = _db.batch();
          for (final doc in chunk) {
            batch.set(_items(congregationId).doc(doc.entityId), {
              'entity': doc.entity,
              'programTypeId': doc.programTypeId,
              'hlc': doc.hlc,
              'srcDevice': doc.srcDevice,
              'keyVersion': doc.keyVersion,
              'blob': doc.blob,
              'serverTs': FieldValue.serverTimestamp(),
            });
          }
          // Same batch: peers get ONE cheap signal per push, and the rules
          // member-doc get() is cached across the whole request.
          batch.set(
            _activity(congregationId),
            {
              'scopes': {
                for (final scope in activityScopes)
                  scope: FieldValue.serverTimestamp(),
              },
              'srcDevice': chunk.first.srcDevice,
            },
            SetOptions(merge: true),
          );
          await batch.commit().timeout(_writeTimeout);
        }
      });

  @override
  Future<List<ItemDoc>> pullSince(String congregationId, String? cursor) =>
      _guard(() async {
        var query = _items(congregationId)
            .orderBy('serverTs')
            .limit(pageSize);
        if (cursor != null) {
          query = query.where('serverTs',
              isGreaterThan: decodeServerTs(cursor));
        }
        // Source.server: a doc whose write is still latency-compensated has
        // serverTs == null locally; never let it poison the cursor.
        final snap = await query.get(const GetOptions(source: Source.server));
        return [
          for (final d in snap.docs)
            if (d.data()['serverTs'] != null) _toItemDoc(d),
        ];
      });

  ItemDoc _toItemDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    return ItemDoc(
      entityId: d.id,
      entity: data['entity'] as String,
      programTypeId: data['programTypeId'] as String?,
      hlc: data['hlc'] as String,
      srcDevice: data['srcDevice'] as String,
      keyVersion: data['keyVersion'] as int,
      blob: data['blob'] as String,
      serverTs: encodeServerTs(data['serverTs'] as Timestamp),
    );
  }

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on FirebaseException catch (e) {
      throw SyncTransportException(
        switch (e.code) {
          'permission-denied' => SyncTransportErrorKind.permissionDenied,
          'unavailable' => SyncTransportErrorKind.offline,
          _ => SyncTransportErrorKind.unknown,
        },
        'Firestore ${e.code}: ${e.message}',
        e,
      );
    } on TimeoutException catch (e) {
      throw SyncTransportException(
          SyncTransportErrorKind.offline, 'Firestore write timed out.', e);
    }
  }
}
