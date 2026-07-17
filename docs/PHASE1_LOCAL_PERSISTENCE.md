# Phase 1 — Local Persistence: Implementation Plan

Executes phase 1 of [DATA_ARCHITECTURE.md](./DATA_ARCHITECTURE.md) §8.
Status: **milestones 1–4 implemented** — 2026-07-15 (schema+migration
`0cb1ee5`, people `d274577`, congregations+projects `aad1b70`, cleanup
`12d41f7`). The `.jwpp` item was dropped from milestone 2 — export/import
turned out not to exist yet, so it belongs to a later phase.

## Phase 1-B (2026-07-15): everything the config UI promises now persists

Follow-up scoped after user testing found config gaps:

- **Congregation settings persist** (`b0b48c9`): `CongregationSettings`
  (typed, tolerant JSON in `settingsJson`) + repository `update()`; the
  congregation tab seeds from the row and autosaves (debounced).
- **App preferences persist** (`2d007a2`): theme, time format, week start,
  PDF name format, notification toggles → SharedPreferences
  (`state/app_settings.dart`, loaded before `runApp`). The dead ".jwbackup"
  Datos card was removed until a real backup exists.
- **Native save mechanism** (`b64f69a`): `data/files/file_saver.dart` is
  THE standardized way to save/export a file on every platform — native
  save dialog on macOS/Windows/Linux (file_selector), native share sheet on
  Android/iOS (share_plus). PDF export now asks where to save. Future
  backups/exports must reuse it.

Still device-local only by design: nothing syncs to Firestore until phase 4
(see DATA_ARCHITECTURE.md §8) — on Android/iOS data goes to the same
encrypted local DB.

## Goal

Everything the user creates survives an app restart, in the encrypted local
DB, in both auth modes. Concretely:

- Congregations, people and projects live in Drift tables (today: in-memory
  only — even participants were disconnected from the dormant DB layer,
  see `participants_provider.dart` header).
- `Participants` (flat, free-text congregation) migrates to the new `people`
  schema without data loss.
- All new tables carry the sync metadata columns (`hlc`, `deleted_at`) so
  phase 3 never needs an ALTER for them.

**Non-goals (phase 2+):** persisting form assignments/slots, the assignment
picker reading qualifications/absences, any UI for qualifications or
absences, outbox/sync, `.jwpp` beyond keeping it working, per-uid DB files.

## Current state (verified 2026-07-15)

- `AppDatabase` schemaVersion **1**, single `Participants` table,
  `onCreate: createAll`, no migration path yet ([app_database.dart](../lib/data/db/app_database.dart)).
- DB file `participants.db`, opened via injected executor; tests use
  `NativeDatabase.memory()` ([connection.dart](../lib/data/db/connection.dart)).
- UI state is in-memory: `participantsProvider` (Notifier),
  `congregationsProvider`, `projectsProvider` ([dashboard_provider.dart](../lib/state/dashboard_provider.dart)).
- `dbProvider` invariant: consumers must live below `AuthGate` (dashboard,
  participants and workspace screens already do).
- Form keeps `congregationId` as a **name string**; new picker entries copy
  that string into `Participant.congregation` (free text).

## Schema v2

One file per table under `lib/data/db/tables/`. Shared column mixin:

```dart
mixin SyncColumns on Table {
  TextColumn get id => text()();                    // uuid v4
  DateTimeColumn get createdAt => dateTime()();     // UTC
  DateTimeColumn get updatedAt => dateTime()();     // UTC, user edits only
  DateTimeColumn get deletedAt => dateTime().nullable()();  // soft delete
  TextColumn get hlc => text().nullable()();        // unused until phase 3
}
```

Every read query filters `deletedAt IS NULL`. Deletes are soft (tombstones)
from day 1 — required by sync later, and by FK integrity when assignments
arrive in phase 2. "Reset all data" keeps doing hard deletes.

| Table | Columns beyond SyncColumns | Notes |
|---|---|---|
| `congregations` | name, number, color (int), settingsJson (TEXT, default `{}`) | settingsJson: meeting weekday/time, aux-class count, circuit, CO name — read by templates in phase 2; the congregation tab can start editing it now. |
| `people` | congregationId FK, firstName (default ''), lastName (default ''), displayName, gender TEXT enum, privilege TEXT enum, qualificationsJson (default `[]`), originCongregation (default ''), active, notes, lastUsed nullable | Replaces `participants`. `displayName` = what the PDF prints (the old `name`). `originCongregation` = free-text home congregation for visitors (see migration). |
| `person_absences` | personId FK, startDate, endDate, comment | Written/read in phase 2 UI; table exists now. |
| `projects` | congregationId FK, name, notes (default ''), exportedAt nullable | Status is **derived**: exported if `exportedAt != null`, else complete if all programs fully assigned (always false in phase 1), else draft. `done/total/editedLabel` are computed, never stored. |
| `programs` | projectId FK, programTypeId (`'mwb-s140'`), weekType (int, default normal), date (ISO week id from the notebook), label (default '') | **Skeleton rows only** in phase 1: created/deleted when the project modal picks weeks. Slots/assignments arrive in phase 2 — this avoids a throwaway `weeksJson` column and its re-migration. |

Not created yet (phase 3): `outbox`, `sync_state`.

## Migration v1 → v2

In `MigrationStrategy.onUpgrade` (from == 1), one transaction:

1. Create all new tables.
2. **Default congregation**: take the most frequent non-empty
   `participants.congregation` value (the user's own hall in practice); if
   none, name it "Mi congregación". Insert as the first `congregations` row
   (first palette color, number '').
3. **People**: copy every participant → `people` with
   `congregationId = default congregation`, `displayName = name`,
   `firstName/lastName = ''`, privilege = old role,
   `originCongregation = old free text` when it differs (case/accents
   normalized) from the default congregation's name, else `''`.
   `createdAt/updatedAt/lastUsed` preserved.
4. Drop `participants`.

Rationale for step 3: the old free-text field mixed two concepts — the
tenant that owns the record vs. where a visitor comes from. The FK models
the first; `originCongregation` preserves the second (feeds the suggestion
list the participant modal shows today). **No congregation rows are created
from stray free-text values** — a Congregation is a tenant/ACL boundary, not
a label.

Also rename the DB file `participants.db` → `agora.db` (move-if-exists
before open, in `databaseFile()`), while the install base is just us.

## Application layer

New `lib/data/repos/` (implementations over DAOs; DAOs stay in `data/db/`):

- `CongregationsRepository` — `watchAll()`, `create(name, number)` (cycles
  the palette color, as the controller does today), `update`, `softDelete`.
- `PeopleRepository` — mirrors today's `ParticipantsDao` semantics:
  `watchAll`, `upsert`, `markUsed` (touches only `lastUsed`), `setActive`,
  `softDelete`, `bulkUpsert`/`replaceAll` (for `.jwpp`), plus
  `watchOriginCongregations()` (distinct suggestion list).
- `ProjectsRepository` — `watchAll()` (with per-project program count via
  join), `create(name, congregationId, weekIds)` (inserts project +
  skeleton `programs` rows), `update(...)` (diffs week set → insert/remove
  programs), `softDelete` (cascades soft-delete to its programs),
  `markExported(id)`.

Provider rewiring (UI keeps watching the same provider names):

- `participantsProvider` → `StreamProvider<List<Person>>` over
  `PeopleRepository.watchAll()`; `ParticipantActions` calls the repo instead
  of the in-memory Notifier (same method surface; `recordUsage` resolves the
  person's congregation to the **project's congregation** where the picker
  was opened, falling back to the default congregation).
- `congregationsProvider`, `projectsProvider` → StreamProviders; the
  controllers' `add/create/update/delete` move to
  `congregationActionsProvider` / `projectActionsProvider` (same pattern as
  `participantActionsProvider`). Touchpoints:
  [new_congregation_modal.dart](../lib/ui/config/new_congregation_modal.dart),
  [project_modal.dart](../lib/ui/dashboard/project_modal.dart),
  [dashboard_view.dart](../lib/ui/dashboard/dashboard_view.dart),
  [participant_modal.dart](../lib/ui/participants/participant_modal.dart).
- `Project` model loses `done/total/status/editedLabel` as stored fields: a
  `ProjectView` (or record) computed in the provider carries
  `programCount`, `status`, and `updatedAt` (UI formats the relative label).
- `Participant` model renamed `Person` (new fields; `isIncomplete` and
  `normalizeName` unchanged). The participant modal gets optional
  first/last name fields; required field is the display name (labels via
  slang, all three locales).

All of this stays below `AuthGate`, so the `dbProvider` invariant holds
unchanged.

`.jwpp` export/import: update the mapping to `people` (format bumps to v2:
adds the new person fields + congregations; import of v1 files maps like the
DB migration does). Full-backup scope stays phase 2+.

## Milestones (each lands green on its own)

1. **Schema + migration.** Tables, `schemaVersion = 2`, migration,
   `agora.db` rename. Drift schema snapshots (`drift_dev schema dump`) +
   step-by-step migration test with a seeded v1 fixture (accented/duplicate
   congregation strings, empty congregation, lastUsed nulls).
2. **People on DB.** Repo + provider/actions rewire + person modal fields +
   `.jwpp` v2. Restores the pre-refactor DB-backed behavior, now on `people`.
3. **Congregations + projects on DB.** Repos, StreamProviders, actions,
   modals, dashboard filters; skeleton `programs` rows; derived
   `ProjectView`. Form's hardcoded congregation default replaced by the
   default congregation row.
4. **Acceptance + cleanup.** Delete dead in-memory controllers, run the full
   suite, manual pass of the acceptance list.

## Test plan

- Unit: migration (fixture DB at v1 → assert people/congregation mapping,
  originCongregation normalization, counts); each repo on
  `NativeDatabase.memory()`; project week-diffing; status derivation.
- Existing suites must stay green (participants filtering, auth, PDF).
- Run with `rtk proxy flutter test` and read the full log (rtk-wrapped
  `flutter test` truncates and can mask failures).
- Manual acceptance, both auth modes:
  1. Create congregation + project + people → quit app → relaunch → unlock →
     everything is there, filters work.
  2. Fresh install (delete DB) → create-account wizard → empty dashboard, no
     migration side effects.
  3. Upgrade path: install with v1 data → relaunch → participants intact,
     default congregation inferred, suggestions list preserved.
  4. Reset-all-data still wipes file + keys.

## Decisions taken here (challenge if wrong)

- **Program skeleton rows in phase 1** instead of a temporary `weeksJson`
  column on projects (no throwaway schema, phase 2 fills them in).
- **One default congregation absorbs all migrated people**; old free text
  survives in `originCongregation`, and no tenants are auto-created from
  stray strings.
- **DB file renamed to `agora.db`** now, while there are no external users.
- **Soft deletes from day 1** on all new tables.
- Qualifications/absences: **schema now, UI in phase 2** (they only pay off
  when the picker reads them).
