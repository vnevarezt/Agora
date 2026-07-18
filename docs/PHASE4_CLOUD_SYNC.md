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

## Phase 4b-1 (built): the real cloud

The transport seam and the `keyringFor` seam now have Firestore-backed
implementations. Same-account multi-device sync works end-to-end.

- **Firestore layout** (`firestore.rules` enforces it):
  - `users/{uid}` — `pubKey` (X25519) + `wrappedPrivKey` (the 32-byte seed
    wrapped under the sync passphrase, same Argon2id+AES-GCM envelope as the
    local DEK). Owner-only.
  - `congregations/{cid}` — `createdBy`, `createdAt`, clear `keyVersion`
    (rotation hint). No name/number — those are E2E inside the `congregation`
    item blob.
  - `congregations/{cid}/members/{uid}` — `capabilities` map
    `{admin, people, editTypes:[...]}` (`'*'` = all types), `wrappedCcks`
    (CCK per version, sealed-box to the member's pubkey), `pubKey`,
    `inviteId`, `status`.
  - `congregations/{cid}/invites/{tokenId}` — capabilities + keyring wrapped
    under the invite secret (4b-2 wires the UI; rules already gate it).
  - `congregations/{cid}/items/{entityId}` — the 4a `ItemDoc` plus a CLEAR
    `programTypeId` (rules gate `edit:<type>` with it) and a Firestore
    `serverTimestamp()`.
- **serverTs cursor**: `SyncState.pullCursor` stays a TEXT column;
  `FirestoreTransport` encodes the server `Timestamp` as
  `'{seconds pad 12}.{nanos pad 9}'` (lexicographically sortable AND
  reversible for the `where serverTs >` query). Pulls use `Source.server`
  and skip null-serverTs docs (latency-compensated writes).
- **Keys** (`lib/data/sync/`): `sealed_box.dart` (X25519 → HKDF → AES-GCM),
  `user_key_service.dart` (passphrase create/unlock/change),
  `cck_service.dart` (= the production `keyringFor`: founder bootstrap,
  keychain cache, recovery from the member doc). `passphrase_envelope.dart`
  is the Argon2id+AES-GCM envelope shared with `DbKeyManager`.
- **Wiring** (`lib/state/`): `sync_provider.dart` (Firestore instance,
  transport, key services, `myMembershipsProvider` collection-group stream,
  `myCapabilitiesProvider`, engine), `sync_keys.dart` (passphrase lifecycle,
  Settings → Sync card), `sync_controller.dart` (debounced push on outbox
  watch; pull on start/resume/after-push/every-5-min/manual; status).
- **Enabling**: after cloud sign-in, sync is OFF until the user creates the
  passphrase (Settings → Sync card) and enables cloud on a congregation
  (Congregation tab → "Activar en la nube": mint CCK, create the space,
  `SyncSeeder` enqueues the whole subtree, push).
- **Security rules**: no Cloud Functions (Spark plan). Invite redemption is
  a client batch `[create member, delete invite]` proven single-use with
  `exists()`/`existsAfter()`. Verified by `tool/rules-test/` in the Firestore
  emulator (`firebase emulators:exec --only firestore 'npm --prefix
  tool/rules-test test'`).

## Deferred to 4b-2 / 4b-3

Invite/redeem UI + real members list + capability editor + revocation
rotation (4b-2); realtime pull signal, shell status badge, connectivity
nuances (4b-3). Still deferred past 4b: `personId` linking on assignments,
per-uid DB files (guarded by an account-owner check for now), congregation
cloud delete, tombstone GC.
