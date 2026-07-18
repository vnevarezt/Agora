/// One synced entity as it travels (docs/PHASE4_CLOUD_SYNC.md): the server
/// stores ONE doc per entity (state-based LWW, no log growth). Everything
/// but the metadata is inside the encrypted [blob].
class ItemDoc {
  const ItemDoc({
    required this.entityId,
    required this.entity,
    required this.hlc,
    required this.srcDevice,
    required this.keyVersion,
    required this.blob,
    this.programTypeId,
    this.serverTs,
  });

  final String entityId;

  /// Entity kind name (SyncEntity.name) — clear metadata so rules can gate
  /// writes per kind (capability roles, DATA_ARCHITECTURE.md §5).
  final String entity;

  /// Program type of program/assignment docs (null for the rest) — clear
  /// metadata, like [entity], so rules can gate `edit:<programTypeId>`
  /// capabilities per write. Deliberately NOT secret: it only says WHICH
  /// meeting a blob belongs to, never its content.
  final String? programTypeId;

  /// Conflict clock of the row state inside [blob].
  final String hlc;

  /// Device that wrote it (pull echo suppression).
  final String srcDevice;

  final int keyVersion;

  /// `base64(nonce|ciphertext|mac)` under the congregation content key.
  final String blob;

  /// Pull cursor field, ASSIGNED BY THE TRANSPORT on upsert (Firestore
  /// server timestamp in 4b; a monotonic counter in the in-memory fake).
  final String? serverTs;

  ItemDoc withServerTs(String ts) => ItemDoc(
        entityId: entityId,
        entity: entity,
        hlc: hlc,
        srcDevice: srcDevice,
        keyVersion: keyVersion,
        blob: blob,
        programTypeId: programTypeId,
        serverTs: ts,
      );
}

/// The cloud seam (docs/PHASE4_CLOUD_SYNC.md): 4a proves the engine against
/// an in-memory implementation; 4b adds the Firestore one. Implementations
/// must assign a monotonically increasing [ItemDoc.serverTs] per
/// congregation on upsert.
abstract interface class SyncTransport {
  Future<void> upsertItem(String congregationId, ItemDoc doc);

  /// Docs with `serverTs > cursor` in ascending serverTs order
  /// (cursor null = everything).
  Future<List<ItemDoc>> pullSince(String congregationId, String? cursor);
}
