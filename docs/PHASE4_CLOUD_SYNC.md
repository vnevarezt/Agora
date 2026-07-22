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

## Phase 4b-3 (built): transparent, cheap sync

Replaces polling with a heartbeat so remote changes appear instantly where
they matter, idle costs zero reads, and the user never manages sync.

- **Batched push** (`SyncEngine.pushOnce` + `SyncTransport.upsertItems`): one
  atomic write per congregation instead of per doc, so the rules' member-doc
  `get()` is billed once per push, not once per doc. Each batch also bumps a
  tiny **heartbeat** doc `congregations/{cid}/meta/activity` =
  `{scopes: {scope: serverTs}, srcDevice}` in the SAME batch. A scope is a
  project id (for project/program/assignment, via `EntityCodec.scopeOf`),
  `'people'` or `'congregation'`. Firestore's 500-op batch cap is chunked at
  450.
- **No polling.** `SyncController` opens ONE cheap listener per congregation
  on `meta/activity` (idle = 0 reads; a listener only bills on change).
  `decidePull` (`lib/data/sync/pull_policy.dart`, pure/unit-tested) turns a
  heartbeat into `none` (own device / nothing newer than the cursor),
  `immediate` (the changed scope is the open project, or `'people'` while the
  directory is on screen) or `lazy` (off-screen → a 3-min coalescing window,
  flushed early when the user opens that project/section). The pull itself is
  still the cursor query — the heartbeat is only a signal; the boot reconcile
  and on-view flush cover any missed beat, so correctness never depends on it.
- **Push you can't lose**: debounced on outbox change, retried on reconnect
  (`connectivity_plus`), on resume, and with exponential backoff (30 s → 2 min
  → 8 min). Push and pull have separate mutexes so a pull can't starve a push;
  a failing congregation doesn't block the others.
- **Silent UI**: the "Sincronizar ahora" button and pending count stay tucked
  in Settings; the dashboard shows a cloud indicator ONLY on offline-with-
  pending or error/revocation. Healthy sync is invisible.

## Phase 4c (built): keys you never manage

There is no passphrase and nothing to link. The X25519 identity key is
minted on first sign-in and stored in `users/{uid}` (readable only by that
account per the rules), so signing in on any device restores everything by
itself — the WhatsApp-style restore the product wanted.

- **Custody, stated plainly**: escrowing the private key is what buys
  automatic restore, and it also means whoever controls the Firebase project
  can read congregation content. What still protects it: TLS, Firestore
  at-rest encryption, the per-member/per-capability rules, and the encrypted
  local database. The UI must not claim otherwise.
- **The content crypto stays** (`SealedBox`, `CckService`, per-congregation
  CCKs sealed to each member's pubkey). It is not decoration: it is what
  makes removing a member actually cut their access to future data,
  independently of the rules. It also means switching to a model where only
  the user can decrypt is a small change later — stop escrowing `privKey`,
  hand out a recovery code — with no data migration, since the stored format
  doesn't change.
- **`users/{uid}`** = `{pubKey, privKey, keyUpdatedAt, createdAt}`, owner-only,
  with both key halves frozen after creation (swapping either would orphan
  every CCK sealed to the identity) and the legacy `wrappedPrivKey`
  rejected.
- **Sign-out** still wipes the device's cached copy and the congregation
  keys (`cloudSignOutProvider`); signing back in fetches the key again.

### Why not end-to-end

Restoring with only the account and keeping the operator unable to read are
mutually exclusive: if the account alone unlocks the key, whoever runs the
account system can unlock it too. WhatsApp's default backup makes the same
trade; its opt-in E2E backup instead requires a password or a 64-digit key,
and Signal requires a 64-character recovery key. The product chose automatic
restore, knowingly.

## Deferred to 4b-2

Invite/redeem UI + real members list + capability editor + revocation
rotation. Still deferred past 4b: `personId` linking on assignments, per-uid
DB files (guarded by an account-owner check for now), congregation cloud
delete, tombstone GC.
