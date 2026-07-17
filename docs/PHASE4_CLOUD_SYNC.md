# Phase 4 — Cloud Sync: Implementation Plan

Executes phase 4 of [DATA_ARCHITECTURE.md](./DATA_ARCHITECTURE.md) §8, split
in two honest halves:

- **4a (this repo state): the engine, cloud-agnostic.** E2E content crypto
  (per-congregation key + keyring), wire codec per entity, push/pull with
  LWW over HLC, cursors, echo suppression — all behind a `SyncTransport`
  interface and proven by two-device tests against an in-memory transport.
  Nothing here needs Firebase.
- **4b (next): the cloud.** `FirestoreTransport` (adds the cloud_firestore
  dependency), user keypair + sync passphrase bootstrap, members/invites,
  security rules, background triggers and the sharing UI. Requires the real
  Firebase project and hands-on testing.

## 4a design

- **ContentCrypto** (`lib/data/sync/content_crypto.dart`): a random 256-bit
  Congregation Content Key encrypts every payload with AES-256-GCM; the
  envelope is `base64(nonce | ciphertext | mac)` with
  AAD = `cid/entityId` (a doc swapped to another path fails to open). A
  `CongregationKeyring` holds `{version → key}`: revocation later adds a
  version instead of re-encrypting history (§5 of the architecture).
- **Entity codec** (`entity_codec.dart`): explicit, versioned wire maps per
  entity — deliberately NOT the drift-generated serialization, so the wire
  format never silently drifts with the schema.
- **SyncTransport** (`sync_transport.dart`): `upsert(cid, ItemDoc)` +
  `pullSince(cid, cursor)`. `ItemDoc` = entityId, entity, hlc, srcDevice,
  keyVer, blob, serverTs (assigned by the transport). One doc per entity =
  state-based LWW, no log growth.
- **SyncEngine** (`sync_engine.dart`):
  - *push*: drain the outbox in id order, coalescing per entity; read the
    CURRENT row, resolve its congregation (joins), encrypt, upsert, delete
    the pushed outbox rows. Crash between upsert and delete → harmless
    re-push (idempotent).
  - *pull*: fetch docs since the congregation's cursor, skip own
    `srcDevice`, decrypt, apply in dependency order (congregation → people →
    absences → projects → programs → assignments) inside one transaction,
    LWW per row on the HLC string (local `null` loses), advance the cursor.
    Applies write tables directly — never through repositories — so pulls
    don't re-enqueue outbox entries.

## Deferred to 4b

Firestore adapter + rules, key bootstrap/passphrase UX, member/invite key
distribution, revocation rotation, connectivity/debounce triggers, sync
status UI, and linking `personId` on assignments.
