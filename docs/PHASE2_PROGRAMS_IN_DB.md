# Phase 2 — Programs in the DB: Implementation Plan

Executes phase 2 of [DATA_ARCHITECTURE.md](./DATA_ARCHITECTURE.md) §8.
Status: **in progress** — 2026-07-15.

## Goal

Assignments survive restarts. Opening a project shows ITS weeks with THEIR
saved assignments; the PDF and progress reflect the DB, not an ephemeral
form. Project cards show real progress.

## Design: derive structure, persist content + assignments

The editor pipeline (verified in code) derives everything from two inputs:

```
Week (parsed MWB parts)  ──buildSchedule──▶  rows with times & slot counts
form maps (rowId → names) ─────────────────▶  assignments, progress, PDF
```

Times shift whenever start time/duration change, and slot ids (`te0`,
`se1`, `chairman`…) are stable functions of the part order. So phase 2
persists the **inputs**, not the derived rows:

- **`programs.contentJson`** — the parsed `Week` snapshotted per program
  (docs/DATA_ARCHITECTURE.md §2 "snapshotted at creation"): the program is
  self-contained, offline-safe and immune to MWB cache changes.
- **`assignments` rows** — one per filled slot position:
  `(programId, slotKey, hall main|aux, position, displayName, personId?)`.
  Fine-grained rows keep future sync conflicts rare (§4 of the
  architecture). The chairman is `slotKey 'chairman'`.
- **`programs.titleOverridesJson`** — per-row title edits (coarse LWW with
  the program row is acceptable for these).
- **`programs.startTime / durationMinutes / auxRoom`** (nullable) — per-
  program overrides; congregation settings provide the defaults.

**Architecture refinement**: the `ProgramSlot` table from
DATA_ARCHITECTURE §2 is realized as `contentJson` + *virtual* slots (the
derived rows) + `assignments.slotKey`. Materialized slot rows would need
constant re-syncing with derived times for zero benefit; the essential
properties (self-contained programs, fine-grained assignments) hold.

## Editor strategy: hydrate + write-through

`formProvider` stays THE editor state (schedule, preview, PDF, progress and
pickers all read it — verified: they never touch storage). Phase 2 makes it
a **write-through cache of the DB**:

1. **Hydrate**: opening a project loads its programs (lazy-snapshotting
   `contentJson` for phase-1 programs that lack it, resolving week label →
   issue through the notebook catalog), assignment rows and flags into the
   form maps; the editor's week tabs become the project's programs.
2. **Write through**: every form mutation also writes the DB —
   `setChairman`/`setMainNames`/`setAuxNames` → assignment rows,
   `setCircuitOverseer` → `programs.weekType`, `setTitleOverride` →
   `titleOverridesJson`, aux room / start time / duration → the program
   columns (applied to all programs of the project, matching the current
   single-toggle UX).

`personId` stays null in phase 2 (the picker still hands over names);
linking picks to Person rows is a small follow-up once the picker returns
ids.

## Schema v3 (migration v2→v3)

- `programs`: add `contentJson TEXT?`, `titleOverridesJson TEXT '{}'`,
  `startTime TEXT?`, `durationMinutes INT?`, `auxRoom BOOL?`.
- New `assignments` table: SyncColumns + `programId` FK, `slotKey`,
  `hall` TEXT enum, `position` INT, `displayName`, `personId` FK nullable.
  No unique constraint (soft deletes + future sync); upserts resolve the
  alive row for `(programId, slotKey, hall, position)`.
- `Week`/`Part` gain `toJson`/`fromJson`.

## Milestones

1. **Schema v3** + migration + tests.
2. **Content snapshot**: `ProgramContentService` fills `contentJson` after
   project create/update and on editor open (covers phase-1 programs).
3. **Editor on DB**: hydration + write-through; week tabs from programs.
4. **Real progress**: dashboard cards count assignment rows against the
   schedule computed from each program's content; `complete` status becomes
   reachable.

## Out of scope (later)

- `personId` linking from the picker; qualifications/absences in the picker
  (needs it).
- Editing the snapshot's parts (add/remove/rename parts beyond title
  overrides).
- Multi-type programs in the editor (only `mwb-s140` renders today).
