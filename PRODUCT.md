# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

The person who prepares their congregation's midweek meeting program. Today they
spend evenings adjusting tables in a word processor to schedule assignments,
balance participants and print the weekly program.

Confirmed: **multiple people per congregation share the same data.** Congregation
reality is a division of labor — one person handles the midweek meeting, another
the public talks — not a single preparer broadcasting a finished PDF. Members,
invitations, and per-capability access are therefore part of the product, not an
add-on.

## Product Purpose

Plan, assign and print congregation meeting programs in minutes, producing
print-ready PDFs with no manual formatting. Success is the evening that no longer
happens: the program is built, assigned and exported without ever touching a word
processor table.

It starts with the midweek meeting and is growing into a general program
generator for the congregation, on the same foundation (projects, participants,
congregations).

## Positioning

Native PDF generation with a live preview that *is* the printed result — names
re-render into the final document as they are typed, removing the
export-and-check loop. Combined with a local-first store that needs no account
and no server, and adaptive column layout that never overflows regardless of
content volume (auxiliary classroom, circuit overseer week, two weeks per sheet).

A generic scheduling tool cannot truthfully claim the PDF-is-the-preview
equivalence; a document template cannot claim the automatic timing.

## Operating Context

- Meeting workbooks are downloaded and cached automatically, so new weeks become
  available as soon as they are published.
- Work happens across a full month or a single week, grouped into projects that
  move from draft → complete → exported.
- The output is printed and physically distributed; the PDF is the deliverable,
  the app is the means.
- The interface language (Spanish / English) is independent of the meeting
  language.
- Fully functional offline. The only network use in local mode is fetching
  workbooks.

## Capabilities and Constraints

**Platform, precisely.** `adaptive` above is the closest value the schema
offers, and it overstates one thing: Agora does **not** adapt its design language
per OS. It ships Android, iOS, macOS and Windows behind **one custom
Material-derived design language** (`lib/ui/theme/tokens.dart` — an `AppTokens`
ThemeExtension mirroring CSS custom properties, light and dark, with further
palettes planned). There is no Cupertino usage anywhere in `lib/`. The real
adaptation axis is **form factor, not operating system**: compact (phone) and
expanded (desktop/tablet) are both first-class and neither is a degraded version
of the other. Platform conventions still bind where they are about behavior
rather than look — safe areas, touch-target minimums, back navigation, Dynamic
Type / font scaling, reduced motion.

**Confirmed functionality**

- Program builder: select weeks, every part laid out with sections, songs, timing.
- Automatic timing: start time, section durations, student counsel minutes and
  slack computed per row.
- Participants directory with privileges (`Role`: elder, ministerial servant,
  publisher) gating which names are offered for which parts.
- Projects dashboard: `ProjectStatus` draft / complete / exported, plus reminders.
- Auxiliary classroom rendered side by side with adaptive columns.
- Circuit overseer visit: Bible study replaced by the overseer's talk, timing
  recalculated.
- Inline-editable assignment titles, kept in sync between editor and PDF.
- One-tap export/share. Light and dark theme, following system or user choice.

**Technical constraints**

- Flutter + Riverpod; `pdf` + `pdfrx` for generation and preview; Drift over
  encrypted SQLite; slang for type-safe i18n.
- Offline-first: local SQLite is the source of truth. Congregation is the tenant.
- A **local password wraps the database key** and there is deliberately no
  recovery — forgetting it loses that device's data. Portable backups are the
  mitigation, and the product must keep saying so plainly.
- Optional cloud account (Firebase email/password or Google) acts as identity and
  sync gate. It never replaces the local password. No cloud config lives in the
  repository; each developer supplies their own.
- Sync is end-to-end encrypted (HLC / last-writer-wins per entity). The server
  sees metadata only.

**Access model (designed, in progress)**

Roles are **capability sets, not a ladder**: `admin` (members, invites, settings,
delete space), `people` (person directory), `edit:<programTypeId>` (`edit:*` for
all), `view` (implied by the others). The UI enforces capabilities exactly;
Firestore rules enforce them approximately, since blob content is not
server-verifiable under E2E. Documented in `docs/DATA_ARCHITECTURE.md`.

**Open decisions**

- Sharing / invitations UI is not built yet, nor is content-encryption-key
  rotation. Enabling cloud sync is currently a manual per-congregation step
  rather than a unified flow.
- Account deletion and the local→cloud migration flow are unbuilt.
- Roadmap, not commitments: more program types, assignment history and workload
  balancing, Portuguese interface.

## Brand Commitments

- Name: **Agora**. Tagline in use: "Congregation program generator."
- Author: Vicente Nevarez Treviño. Source-available under **PolyForm
  Noncommercial 1.0.0** — noncommercial use free (explicitly including
  congregations, charities, educational institutions); commercial use requires a
  separate license. Any surface describing the license must not flatten this into
  "open source."
- Voice in existing copy is plain, concrete and non-promotional; it names the
  chore it removes rather than claiming transformation.
- Code conventions: comments and identifiers in English; every UI string goes
  through slang i18n (Spanish and English shipped).

## Evidence on Hand

- Working application across four platforms; a mature token system and PDF
  pipeline in `lib/`.
- Architecture documentation: `docs/DATA_ARCHITECTURE.md`, `docs/FIREBASE_SETUP.md`,
  phased implementation docs, `docs/features/`.
- Test suite (`test/`, `integration_test/`) and a Firestore rules test harness.

**Absences future work must not fabricate:** there are no screenshots yet — the
README carries commented-out placeholders for a hero capture and a program-output
capture. There are no users, testimonials, ratings, install counts, case studies
or press. Status is "in active development." Do not invent any of these.

## Product Principles

1. **The PDF is the product; the app is the means.** Anything that widens the gap
   between what is on screen and what comes out of the printer is a defect,
   regardless of how it looks.
2. **Form factor adapts, identity does not.** Phone and desktop are both real
   working scenes and get equal design attention, but they are one product with
   one visual language — not a desktop tool with a phone port.
3. **Local-first is a promise, not a default setting.** The app must be entirely
   usable with no account and no network, and must be honest about the
   irreversibility that buys (no password recovery).
4. **Model the congregation's real division of labor.** Access is a set of
   capabilities, not a rank. Design for "this person handles only the midweek
   meeting," never for a generic owner/editor/viewer ladder.
5. **Legibility outranks density.** When a layout decision trades reading comfort
   for information volume, reading comfort wins.

## Accessibility & Inclusion

Confirmed: a significant share of the people who prepare congregation programs
are **older users**. Legible type sizes, generous touch targets and high contrast
are requirements of the product, not stylistic preferences.

Concretely binding for future work: respect OS font-scaling rather than
hard-coding sizes; keep touch targets at or above platform minimums (44pt iOS /
48dp Android) with real spacing between adjacent targets; hold text contrast at
WCAG AA or better in **both** light and dark themes; never rely on color alone to
carry meaning; honor reduced-motion settings. No formal external standard has
been adopted as a compliance obligation.
