import 'package:jw_program/data/sync/sync_transport.dart';

/// In-memory [SyncTransport]: one doc per entity per congregation, with a
/// zero-padded monotonic counter as serverTs (sortable like the Firestore
/// timestamp will be).
class InMemoryTransport implements SyncTransport {
  final Map<String, Map<String, ItemDoc>> docs = {};
  int _seq = 0;

  @override
  Future<void> upsertItem(String congregationId, ItemDoc doc) async {
    final stamped = doc.withServerTs((++_seq).toString().padLeft(12, '0'));
    (docs[congregationId] ??= {})[doc.entityId] = stamped;
  }

  @override
  Future<List<ItemDoc>> pullSince(
      String congregationId, String? cursor) async {
    final all = (docs[congregationId] ?? const {}).values.where((d) =>
        cursor == null || d.serverTs!.compareTo(cursor) > 0);
    return [...all]..sort((a, b) => a.serverTs!.compareTo(b.serverTs!));
  }
}
