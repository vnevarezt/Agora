import 'package:jw_program/data/sync/sync_transport.dart';

/// In-memory [SyncTransport]: one doc per entity per congregation, with a
/// zero-padded monotonic counter as serverTs (sortable like the Firestore
/// timestamp will be). Mirrors the Firestore activity heartbeat in
/// [activity] so tests can assert the scopes a push announced.
class InMemoryTransport implements SyncTransport {
  final Map<String, Map<String, ItemDoc>> docs = {};

  /// cid → merged heartbeat: {'scopes': {scope: serverTs}, 'srcDevice': ...}.
  final Map<String, Map<String, dynamic>> activity = {};

  int _seq = 0;

  @override
  Future<void> upsertItems(
    String congregationId,
    List<ItemDoc> batch,
    Set<String> activityScopes,
  ) async {
    for (final doc in batch) {
      final stamped = doc.withServerTs((++_seq).toString().padLeft(12, '0'));
      (docs[congregationId] ??= {})[doc.entityId] = stamped;
    }
    final heartbeat = activity[congregationId] ??= {'scopes': <String, String>{}};
    final scopes = heartbeat['scopes'] as Map<String, String>;
    final ts = _seq.toString().padLeft(12, '0');
    for (final scope in activityScopes) {
      scopes[scope] = ts;
    }
    if (batch.isNotEmpty) heartbeat['srcDevice'] = batch.first.srcDevice;
  }

  @override
  Future<List<ItemDoc>> pullSince(
      String congregationId, String? cursor) async {
    final all = (docs[congregationId] ?? const {}).values.where((d) =>
        cursor == null || d.serverTs!.compareTo(cursor) > 0);
    return [...all]..sort((a, b) => a.serverTs!.compareTo(b.serverTs!));
  }
}
