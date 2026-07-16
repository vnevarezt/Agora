# Data & Sync Architecture

Design document for Agora's persistence and synchronization layer. Status:
**proposal under discussion** — no code implements this yet.

Goals, in the user's words: offline-first even in cloud mode (data always
lives locally, sync when connectivity returns), multiple congregations,
multiple program types (only VMC/S-140 exists today), programs grouped in
projects, sharing with other users from the first cloud release, and
end-to-end encryption of synced content.

---

## 1. Principles

1. **SQLite is always the source of truth.** In both modes (local account and
   cloud account) the UI reads and writes only the encrypted Drift database.
   The cloud is a replication target, never a data source the UI touches.
   Airplane mode changes nothing.
2. **One code path.** Repositories and providers are identical in both modes.
   Cloud mode only *adds* a background `SyncEngine`; local mode simply never
   starts it. No `if (cloud)` in feature code.
3. **Every synced row carries the same sync metadata** (HLC timestamp,
   tombstone). New entities become syncable by construction, not by retrofit.
4. **The server never sees content.** Synced payloads are AES-256-GCM blobs
   encrypted with a per-congregation key. Firestore stores routing metadata
   only (ids, timestamps, membership).
5. **Program types are pluggable.** The data model knows a `programTypeId`
   string; everything type-specific (template, eligibility rules, PDF layout)
   lives behind a code interface. Adding "public talks" or "attendants" is new
   code + a new id, never a schema migration.

## 2. Domain model

### Hierarchy

```
Congregation  (tenant & sharing unit)
 ├── Person                  directory of brothers/sisters
 ├── Project                 planning container, e.g. "Programas Julio 2026"
 │    └── Program            one emission of one type, e.g. "VMC — week of Jul 21"
 │         └── ProgramSlot   a concrete part: "3. Empiece conversaciones (3 min)"
 │              └── Assignment   who does it (principal / assistant)
 └── Member   (cloud only)   users with access + role + wrapped key
```

- A congregation has N projects; **a project cannot exist without a
  congregation** and belongs to exactly one.
- A project is a *planning container for a period*, typically "the next 4
  weeks". It can mix program types: the same project holds the VMC programs,
  the public-talk programs and the attendants rota for those weeks.
- A **Program** is one emission of one `programTypeId` for one date/week.
  Progress ("12 of 56 parts assigned") is **computed by query**, never stored
  (`Project.done/total/editedLabel` disappear as persisted fields).

### Entities

All synced tables share: `id` (UUID v4, as today), `congregationId`,
`createdAt`, `hlc` (see §4), `deletedAt` (tombstone, null = alive).

| Entity | Own fields | Notes |
|---|---|---|
| `Congregation` | name, number, color, settingsJson | Settings (meeting weekday/time, midweek aux-class count, circuit name, circuit overseer name) feed the program templates. The ACL + encryption boundary. |
| `Person` | firstName, lastName, displayName, gender, privilege (elder/MS/publisher), qualifications, active, notes, lastUsed | Replaces `Participants`; `congregation` free-text becomes the FK. `displayName` is what the PDF prints. `qualifications` = set of slot-kind ids the person can be assigned to (drives the picker), alongside the privilege. |
| `PersonAbsence` | personId, startDate, endDate, comment | "Time away": pickers exclude people absent on the program date. |
| `Project` | name, notes, status is derived | No `programTypeId` — multi-type container. |
| `Program` | projectId, programTypeId, weekType, date (ISO `yyyy-mm-dd` week start), label, sourceRef | `weekType` (normal, CO visit, assembly/convention, memorial, no meeting) alters the generated template — CO-visit weeks drop the CBS, assembly weeks may have no local meeting. `sourceRef` points at the MWB week it was generated from (traceability only). |
| `ProgramSlot` | programId, position, section, title, minutes, rulesJson | **Snapshotted at creation** from the MWB cache + type template, then freely editable. A program is self-contained: it renders offline and survives upstream content changes. |
| `Assignment` | slotId, role (principal/assistant), personId *nullable*, displayName override, status (assigned/confirmed/declined) | `personId` null + displayName covers visiting speakers without polluting the directory. Fine-grained rows keep multi-user conflicts rare (§4). |

**Not synced:**

- **MWB workbook cache** (epubs, parsed weeks): public reference content;
  each device downloads its own copy, as today.
- **Device/user preferences** (locale, window state): local only.
- The current in-memory dashboard state (`dashboard_provider.dart`) is
  replaced by Drift streams over these tables.

### Program types as a code registry

```dart
abstract interface class ProgramTypeDefinition {
  String get id;                       // 'mwb-s140' — stable, stored in DB
  List<SlotTemplate> buildSlots(...);  // from MWB week / static template
  bool canAssign(Person p, SlotRules r);
  ProgramPdf render(Program p, ...);   // reuses today's pdf/ layer
}
```

A `ProgramTypeRegistry` maps ids → definitions. Unknown id (older app version
syncing data from a newer one) renders a read-only placeholder instead of
crashing.

## 3. Application layering

```
Widgets
  └── Riverpod providers (watch Drift streams — UI updates reactively)
        └── Repositories (PeopleRepository, ProjectsRepository, ...)
              └── Drift DAOs  ←──────────────┐  single source of truth
                    └── writes also append   │
                        to Outbox (same TX)  │
                                             │
SyncEngine (cloud mode only, background)  ───┘
  push: Outbox → Firestore (encrypted)
  pull: Firestore → DAOs (LWW apply) → streams refresh the UI for free
```

- Repositories are the only write path; they stamp HLC + enqueue outbox
  entries **in the same transaction** as the row write, so a crash can never
  desync outbox and data.
- The form (`program_form.dart`) stops being the owner of assignment strings:
  it becomes an editor over `Program/ProgramSlot/Assignment` rows, and the
  PDF renders from the DB.

## 4. Sync engine (cloud mode)

### Replication model: state-based LWW, one doc per entity

Firestore holds **one document per entity row** (not an append-only log):

```
congregations/{cid}/items/{entityId}
  {
    entity:  'person' | 'project' | 'program' | 'slot' | 'assignment',
    hlc:     '2026-07-15T18:03:22.114Z-0003-a1b2c3',   // conflict clock
    serverTs: <Firestore serverTimestamp>,             // pull cursor
    srcDevice: 'uuid',                                 // echo suppression
    keyVer:  2,                                        // §5 keyring version
    nonce:   base64,
    blob:    base64   // AES-256-GCM(payload JSON), AAD = cid + entityId
  }
```

- **Push**: batch outbox entries as upserts of these docs.
- **Pull**: per congregation, `where(serverTs > cursor) orderBy(serverTs)`,
  skip own `srcDevice`, decrypt, LWW-apply through the DAOs, advance cursor.
  Cursors live in a local `sync_state` table, per congregation.
- **Conflicts**: compare HLCs (hybrid logical clock — wall clock + counter +
  device id; monotonic even with clock skew). Highest HLC wins the whole row.
  Deletes are tombstones and obey the same rule. Because assignments are one
  row per part, two elders filling different parts of the same program never
  conflict; editing the *same* part concurrently is last-writer-wins, which
  is acceptable for this domain (documented tradeoff).
- **Tombstone GC**: tombstones older than 90 days are purged locally and in
  Firestore (any device offline longer than that must do a fresh full pull —
  detected via a `since` watermark check).

### Triggers

App start → connectivity regained → debounced after local writes (~2 s) →
manual pull-to-refresh. A Firestore snapshot listener on the `items`
collection gives near-realtime updates while online (nice-to-have, phase 4+).
Retries use exponential backoff; sync per congregation is independent, so one
failing space never blocks the others.

## 5. End-to-end encryption

Layered on top of the existing at-rest scheme — **nothing changes** in
`DbKeyManager`: the local DB keeps its per-device DEK (password-wrapped in
local mode, keychain-held in cloud mode).

New material:

| Key | Scope | Where it lives |
|---|---|---|
| **CCK** — Congregation Content Key (AES-256) | encrypts every synced blob of one congregation | never leaves devices in clear; stored in the OS keychain |
| **User keypair** (X25519) | receiving CCKs | pubkey published in `users/{uid}`; privkey wrapped with a **sync passphrase** (Argon2id, same envelope pattern as `DbKeyManager`) and stored in `users/{uid}` so any of the user's devices can fetch + unwrap it |
| **Invite key** (one-time) | carrying a CCK inside an invitation | embedded in the invite code/link, shared out-of-band, never stored server-side in clear |

### Flows

- **Enable cloud / first device**: generate keypair, ask the user to set a
  sync passphrase (shown with the same "no recovery" warning as the local
  password), upload wrapped privkey. Creating a congregation generates its
  CCK and stores it wrapped under the owner's pubkey in
  `congregations/{cid}/members/{uid}`.
- **New device, same user**: Firebase sign-in → download wrapped privkey →
  passphrase unwraps it → unwrap the CCKs from the member docs → full pull.
- **Invite** (sharing v1): inviter creates
  `congregations/{cid}/invites/{id}` = { role, expiry, CCK wrapped under a
  random invite key }; the invite key travels inside the code/link the user
  sends by WhatsApp/in person. Redeeming decrypts the CCK, re-wraps it under
  the invitee's pubkey into their member doc, deletes the invite.
- **Revocation**: delete the member doc **and rotate**: new CCK version added
  to a keyring (`keyVer` in every doc); new writes use the new version; old
  blobs stay readable by remaining members (they hold the whole keyring).
  No mass re-encryption needed. The revoked user keeps whatever was already
  on their device — unavoidable in any E2E design; documented honestly.
- **Lost passphrase**: any still-trusted device can re-wrap keys under a new
  passphrase (it holds them in its keychain). Sole owner + all devices lost +
  passphrase lost = cloud data unrecoverable — consistent with the app's
  existing "losing the password loses the data" stance.

### What the server can see (accepted metadata leak)

Doc counts per congregation, write timestamps, member uids/emails and roles.
Names, notes, assignments, titles: never.

### Security rules sketch

Rules gate paths, not content: `items` read/write requires an active member
doc; `members` and `invites` writable by admins only; `users/{uid}` writable
by its owner.

### Roles: capability-based, not a single ladder

Congregation reality is "brother X only handles the VMC, brother Y only the
public talks" — a flat owner/editor/viewer ladder doesn't express that.
A member's role is a **set of capabilities**:

- `admin` — manage members/invites, congregation settings, delete space.
- `people` — edit the person directory.
- `edit:<programTypeId>` — edit programs of one type (`edit:*` = all).
- `view` — read-only (implied by all of the above).

The UI enforces capabilities exactly. Firestore rules enforce them
approximately: `entity` and (for program docs) `programTypeId` live in clear
metadata, so rules can reject writes to entity kinds / program types the
member lacks — accepting that blob *content* is not server-verifiable under
E2E. Full-fidelity enforcement happens on devices at decrypt/apply time
(malicious writes by a limited member are detectable and rejectable
client-side; the realistic threat model here is misclicks, not attacks).

## 6. Identity & multi-account hygiene

- Cloud mode: the DB file and keychain entries become **per-uid**
  (`agora_{uid}.db`, `db_key.cloud.{uid}`), so switching Firebase accounts on
  one device cannot mix tenants. Local mode keeps the single account.
- **Local → cloud upgrade** (future wizard): UUIDs make it collision-free —
  create congregation spaces in the cloud, push everything as fresh writes.
  Designed for, not built now.
- `.jwpp` export grows into a full versioned backup (all entities), remaining
  the escape hatch for local-mode users.

## 7. Migrations from today's schema

1. Drift `schemaVersion` bump: create `congregations`, `people`, `projects`,
   `programs`, `program_slots`, `assignments`, `outbox`, `sync_state`.
2. Data migration: distinct non-empty `Participants.congregation` strings →
   `Congregation` rows; participants copied into `people` with the FK;
   empty string → a default "Mi congregación" created on first run.
3. The dashboard's in-memory controllers switch to repository-backed
   providers (same provider names, new sources — UI untouched by design).

## 8. Phased plan

| Phase | Deliverable | Sync? |
|---|---|---|
| **1. Local persistence** | Full schema + repositories + participant migration; congregations & projects survive restarts | metadata columns exist, unused |
| **2. Programs in DB** | Program/slots/assignments persisted; form edits rows; PDF renders from DB; progress computed | — |
| **3. Sync scaffolding** | HLC service, outbox written on every mutation, `sync_state`; still 100 % local | write path ready |
| **4. Cloud v1 = multi-device + sharing** | E2E key bootstrap (passphrase), push/pull engine, invites, roles, revocation/rotation | yes — sharing ships in the first cloud release per product decision |

Each phase is releasable on its own; phases 1–3 carry zero cloud risk.

## 9. Decisions taken (challenge here)

- **Congregation = tenant/sharing/encryption unit** (not a global
  "workspace"): inviting an elder to congregation A must not expose
  congregation B. A user's dashboard = union of congregations they belong to.
- **Projects are multi-type containers**; the type lives on `Program`.
- **LWW per row via HLC** — no CRDT/field merging. Fine-grained rows keep
  real conflicts rare; simplicity wins.
- **Slots snapshotted at program creation** — programs are self-contained;
  MWB cache is a generator input, not a live dependency.
- **State-based replication** (doc per entity) over an op-log: no unbounded
  growth, trivial compaction, Firestore-native.
- **Program types in code, referenced by id in data.**
- **UUID v4 kept** (already in use everywhere; no need for v7).
- **Capability-based member roles** (`admin` / `people` / `edit:<type>` /
  `view`) instead of an owner-editor-viewer ladder — see §5 and §11.

## 10. Known limitations & risks

- Concurrent edits to the *same row* silently last-write-win (no merge UI).
- E2E means: no server-side queries/search (all queries are local anyway),
  no web-console debugging of content, and real passphrase UX friction at
  device-link time.
- Firestore costs scale with doc writes; batching + debounce keep this
  negligible at congregation scale.
- Devices offline > tombstone GC window need a full re-pull (handled, but
  worth a test).
- Firebase project (`agora-vnevarezt`) currently sits on a personal account —
  fine for development; revisit before inviting real users.

## 11. Benchmark: sws2apps/organized-app (reviewed 2026-07-15)

[Organized](https://github.com/sws2apps/organized-app) is the most complete
open-source app in this space (full congregation management: schedules,
field-service reports, attendance, S-21). Reviewed its data model
(`src/definition/*`), role system (`useCurrentUser`, `APP_ROLES`) and
encryption map (`TABLE_ENCRYPTION_MAP`). Findings:

**Adopted into this design:**

- **Capability roles.** Their `AppRoleType` splits scheduling power per duty
  (`midweek_schedule`, `weekend_schedule`, `public_talk_schedule`,
  `attendance_tracking`, plus `admin`/`coordinator`/`secretary` as admins).
  Mapped to our generic `edit:<programTypeId>` capabilities (§5) — same idea,
  but it scales automatically with our pluggable program types.
- **Per-person assignment qualifications.** A person carries the list of
  assignment codes they can receive (Bible reading, starting conversations,
  talks, prayers, "assistant only"…), separate from privilege. Adopted as
  `Person.qualifications` (slot-kind ids) — without it an assignment picker
  can only filter by gender/privilege, which is not how real halls work.
- **Time away.** Absence periods per person; schedulers avoid assigning
  absent brothers. Adopted as `PersonAbsence`.
- **Week types.** `NORMAL / CO_VISIT / ASSEMBLY / CONVENTION / MEMORIAL /
  NO_MEETING…` change the meeting structure. Adopted as `Program.weekType`
  consumed by the type templates.
- **Split names + display name.** First/last/display-name instead of one
  string; the display name is what schedules print. Adopted.
- **Congregation meeting settings.** Weekday/time, midweek auxiliary-class
  count (S-140 aux classes = extra student slots), circuit name, CO name.
  Adopted into `Congregation.settingsJson`; templates read it.

**Noted for later (schema tolerates them, not built now):**

- **Two-tier content encryption.** Organized encrypts elder-only fields
  (`birth_date`, `disqualified`, visiting-speaker contacts) under a separate
  *master key* that only appointed roles hold, vs the congregation access
  code for the rest. Our keyring (`keyVer`) can host a second sensitivity
  tier later; v1 keeps one CCK and simply limits membership to the trusted
  editing team.
- **Visiting speakers / sister congregations directory** (their
  `speakers_congregations` + `visiting_speakers` with talk repertoires) —
  becomes relevant with a future `public-talk` program type; until then
  `Assignment.displayName` covers visitors.
- **Read-only "pocket" accounts** for every publisher to view schedules and
  request parts — a distribution feature, not a data-model change (`view`
  capability already models it).
- **Privilege/enrollment histories** (dated elder/MS/pioneer periods) —
  Agora needs only current values; histories are S-21 territory.

**Deliberately out of scope for Agora** (Organized is a secretary suite;
Agora is a program builder): field-service reports and branch submissions,
meeting attendance, Bible-study tracking, family/delegate accounts,
emergency contacts.

**Validation:** their whole model is field-level LWW (`{value, updatedAt}`
on every field) synced through an offline-first IndexedDB — structurally the
same replication strategy as §4, at finer granularity. Reasonable confidence
our row-level LWW + fine-grained rows is sound for this domain.
