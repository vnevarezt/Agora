# Phase 3 — Sync Scaffolding: Implementation Plan

Executes phase 3 of [DATA_ARCHITECTURE.md](./DATA_ARCHITECTURE.md) §8.
Status: **implemented** — 2026-07-16 (`4a781e2`, schema v4). Still 100 %
local: nothing talks to Firestore until phase 4; the write path is
sync-ready.

## Pieces

- **HLC** (`lib/data/sync/hlc.dart`): hybrid logical clock — wall-clock ms +
  counter + device id, encoded as a fixed-width sortable string
  (`0000001752601402114-0003-a1b2c3d4`). Monotonic even if the wall clock
  jumps backwards; seeded from the newest outbox stamp on first use so
  restarts never regress.
- **Schema v4**: `outbox` (autoincrement id = push order; entity, entityId,
  hlc, queuedAt — a dirty-set, not an op log: push reads the CURRENT row)
  and `sync_state` (per-congregation pull cursor + pushed-through outbox id,
  filled by phase 4).
- **SyncScribe** (`lib/data/sync/sync_scribe.dart`): `nextHlc()` +
  `enqueue(entity, entityId, hlc)`. Every repository mutation stamps the
  row's `hlc` and enqueues the outbox entry **in the same transaction** —
  a crash can never desync data and outbox.

## Instrumented mutations

Congregations create/update; people save/setActive/delete; projects
create/update/delete/markExported (programs cascade included); programs
setContent/setWeekType/setTitleOverrides/setProjectConfig; assignments
saveSlotNames (per touched row). One HLC stamp per operation.

Deliberately NOT instrumented: `PeopleDao.markUsed` (device bookkeeping —
`lastUsed` travels with the next real edit of the row) and the unused
import helpers (`bulkUpsert`/`replaceAll`, revisited when `.jwpp` lands).

## Device id

Random 8-char id persisted in SharedPreferences (`device_id`), created on
first use — identifies this device inside HLC stamps and, later, `srcDevice`
for pull echo-suppression (DATA_ARCHITECTURE.md §4).
