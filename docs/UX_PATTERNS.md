# UX Patterns

Reference for how Agora *behaves*. `DESIGN_SYSTEM.md` covers what the interface
looks like and how it moves; this covers what it does — where a person can be,
what each surface says while it waits, fails or has nothing to show, and how it
gets them out again.

Status: **descriptive, not aspirational** — read out of `lib/ui/` and
`lib/state/` on 2026-08-29. Where a pattern does not exist, §10 says so instead
of inventing one. Nothing here is enforced by a test yet, which is itself one of
the gaps.

Companion documents: `PRODUCT.md` (who this is for), `docs/DESIGN_SYSTEM.md`
(the visual and motion layer), `docs/ACCESSIBILITY.md` (the standard both are
held to), `docs/DATA_ARCHITECTURE.md` (what the state these screens read is made
of), `lib/i18n/README.md` (the translation pipeline).

---

## 1. What the behaviour is arranged around

`PRODUCT.md` sets the product principles; three of them decide interaction
arguments specifically.

1. **The program is the work; the app is where it gets done.** Every screen is
   in service of a week of assignments reaching a printed sheet. A flow that
   does not move that forward — a tour, an announcement, a survey — has no
   place to appear.
2. **Offline is the normal case, not the degraded one.** No screen may present
   itself as broken because the cloud is unreachable. Sync has its own status
   surface (§4.3) and everything else carries on.
3. **A person preparing a program is often interrupted.** Nothing is lost by
   leaving: the form is the source of truth and writes through, so there is no
   save button to forget and no "unsaved changes" prompt anywhere in the app.

## 2. Information architecture

### 2.1 Three gates, in order

Nothing below a gate builds until the gate passes, which is why nothing can
read the database before it is open.

```
_router (/, /login)  →  AuthGate  →  _SyncBootstrap  →  AppShell
```

`AuthGate` (`ui/auth/auth_gate.dart`) switches on the session and is the only
place a screen is chosen by state rather than by a tap:

| Session state | Surface |
|---|---|
| `SessionLoading` | `_AuthSplash` — the mark's entrance, spinner only after it settles |
| `SessionFreshChoose` | `_AuthFlow` — cover screen, then local or cloud |
| `SessionLocalCreate` | `LocalCreateScreen` (also the migration path) |
| `SessionLocalLocked` | `UnlockScreen` |
| `SessionCloudSignedOut` | `CloudAuthScreen` |
| `SessionCloudLocked` | `CloudLockScreen` |
| `SessionCloudUnverified` | `EmailVerificationScreen` |
| `SessionKeyError` | `KeyErrorScreen` |
| `SessionUnlocked` | the app |

The switch is exhaustive on a sealed type, so a new session state cannot ship
without a screen. Transitions run through `FadeThroughSwitcher` keyed on the
state's runtime type — the app never appears to *navigate* into being locked,
it changes.

### 2.2 Navigation is state, not a route stack

`go_router` is configured with exactly two paths (`/` and `/login`) that build
the same root, and exists because the static landing page links straight at
`/login`. Everything after the gate is Riverpod state in `state/ui_state.dart`:

| Provider | Chooses |
|---|---|
| `appSectionProvider` | Home · Participants · Settings |
| `settingsTabProvider` | the App or Congregation tab inside Settings |
| `mobileTabProvider` | Assign or Preview, on mobile only |
| `activeSlotProvider` | which assignment slot has the picker open |

`settingsTabProvider` is shared rather than owned by the Settings view on
purpose: the dashboard's "no congregation" state sends a new account straight
to the tab holding the button, instead of dropping them in Settings to hunt for
it. **A cross-screen instruction lands on the control, not on the screen.**

The editor is the one thing pushed onto the `Navigator`, from the dashboard
(`Navigator.of(context).push` at three call sites into `ProgramShell`), because
it is the only place with a real back.

### 2.3 Depth

Three levels, and no more:

```
section  →  editor  →  modal
```

Everything that would be a fourth level is a modal instead — `showAppModal`
renders a centred dialog on desktop and a bottom sheet on mobile from one call
site, so a flow does not fork by form factor.

### 2.4 The editor's anatomy

`ProgramShell` is the single place the two-panel decision is made: desktop and
tablet split 46/54 between assignments and preview; mobile stacks one column
and swaps between them with `MobileTabs`. Both arrangements build the *same*
`WorkspacePanel` and `PreviewPane` — the layout differs, the components do not.

## 3. The state matrix

Every surface that loads data has to answer four questions. What follows is
what the app actually does, per register.

### 3.1 Waiting has three registers, and they are not interchangeable

| Register | What it is | Where |
|---|---|---|
| **Skeleton** | the *real* cards rendered with mock data inside a `Skeletonizer` | dashboard, participants, workspace |
| **Control spinner** | `AppButton(busy: true)` — the button holds its size, disables, and swaps its label for `AppSpinner` | every action button |
| **Brand loader** | `AgoraLoader`, the mark turning | the PDF preview, and nowhere else |

The skeletons render the real widget with placeholder content rather than a
hand-drawn grey shape, so a placeholder **cannot drift from the thing it stands
for** — the usual failure of skeleton screens.

`AgoraLoader` is deliberately scarce: it is for the one wait long enough and
large enough to deserve a logo. Everywhere else a spinner is a detail inside a
control, where a mark would be noise.

The boot splash is a fourth case and a rule of its own: the mark plays its
entrance first and the spinner fades in **only if the boot outlasts it**. Most
boots resolve inside the animation, and a spinner that flashes for a fifth of a
second reads as a stutter rather than as progress. The spinner's space is
reserved from the first frame so arriving does not shunt the mark upwards.

**A skeleton must be able to end.** The workspace checks
`weeksProvider.isLoading` before falling through to its empty state, precisely
so a slow load does not flash the download prompt at somebody whose data is on
the way.

### 3.2 Empty always carries its own exit

`EmptyState` (icon · optional title · message · optional action · optional
error) is the only empty-state widget, and every call site fills the action
slot. The pattern is: **name what is missing, then hand over the control that
creates it.**

| Surface | Empty means | The way out |
|---|---|---|
| Dashboard | no congregation exists | a button that lands on the Congregation tab |
| Workspace | no workbook for this issue | download it, or (on web) import it by hand |
| Participants | nobody added yet | add a participant |
| Congregation tab | not a member of one | create or join |

The dashboard case is worth naming because it was a defect first: everything is
filed under a congregation, and with none the app drew a skeleton that never
resolved. A skeleton says *wait*; there was nothing to wait for. **An empty
state is not a slow loading state, and a loading state that cannot finish is a
lie.**

### 3.3 Error has four registers, chosen by what the person can do next

| Register | Widget | Use |
|---|---|---|
| **Inline, under the field** | `AuthErrorText` | the input is wrong and can be corrected in place |
| **In the empty state's error slot** | `EmptyState(error:)` | the thing that would have filled this screen failed to load |
| **Panel text** | plain `Text` in `colorScheme.error` | a pane failed on its own (the PDF preview) |
| **Full screen** | `KeyErrorScreen` | nothing can proceed — the encrypted database will not open |
| **Snackbar** | raw `SnackBar` | an action the person already committed to has finished, well or badly |

`AuthErrorText` accepts null so the call site keeps it mounted, and animates its
own height through `MotionSize`: **an error appearing must not shove the form**,
because the button someone is reaching for would move out from under them.

## 4. Error taxonomy

### 4.1 Codes are mapped once, at the edge

`cloudAuthErrorText` (`ui/auth/auth_error_mapping.dart`) is the single
translation from `CloudAuthErrorCode` to a sentence. Nine codes collapse to
eight strings; `canceled`, `requiresRecentLogin` and `unknown` share one.

### 4.2 Validation happens on submit, not on keystroke

There is exactly one client-side rule — `isValidEmail`, one regular expression
in `ui/auth/auth_validation.dart`. Everything else is decided by the server or
the database and surfaced when it answers. Nothing validates while typing, so
nobody is told they are wrong halfway through being right.

### 4.3 Sync states its own condition and never blocks

`SyncPhase` is `disabled · idle · syncing · offline · error`, rendered as a
title and subtitle in the Settings sync card, with `errorKey` narrowing the
error case to `permissionDenied`, `offline` or unknown. It is a **status
surface, not an interrupt**: nothing about sync ever takes the screen, and the
one button on it (`syncNow`) exists solely because sync is otherwise driven by
heartbeats with no way to ask again.

## 5. Forms

- `LabeledField` — a small uppercase label above any control. The label is
  always present; there are no placeholder-only fields, which vanish the moment
  someone starts typing.
- `BoundTextField` — seeded once from state, after which **the provider is the
  source of truth**. The field does not own the value it shows.
- Submission is `AppButton(busy:)`. The button disables and keeps its size, so
  a double tap is impossible and the layout does not jump.
- There is no save button in the editor. The form writes through, which is what
  makes leaving mid-week safe (§1.3).

## 6. Destructive actions

`DangerButton` in `colorScheme.error` is the only affordance for a destructive
action, and there is deliberately no danger *variant* of `AppButton` — the
destructive control is a different object, not a colour swap on the ordinary
one.

Confirmation is a modal with the danger button in `ModalShell`'s footer.

`DeleteAccountModal` is the pattern to copy for anything with preconditions: it
lists the congregations that block the delete **before** asking for anything,
so nobody is made to re-authenticate for an operation that was always going to
be refused. **Check what would fail first, and say so before collecting.**

## 7. First run

```
Portada  ──create account──→  cloud sign-up  ──→  verify email  ──→  app
   ├──────sign in──────────→  cloud sign-in   ──→  app
   └──────use locally──────→  local profile   ──→  app
```

`_AuthFlow` drives these with `SlideSwitcher`, and reverses the transition when
the step is `choose` so back retraces the path it arrived on rather than pushing
forward again.

There is no tour, no coach marks and no progressive disclosure. The first thing
a new account meets in the app itself is the dashboard's no-congregation empty
state (§3.2), which is therefore the real onboarding step and should be read as
one.

## 8. Content and voice

- The interface addresses one person doing a job, in the second person, and
  never refers to itself. Spanish (`es`) is the base locale and the register
  is the neutral one used across congregations, not a regional one.
- The dashboard greets by time of day (`_greeting`), which is the only
  personality anywhere in the product surface.
- Errors say what happened, not what the code did. `cloudAuthErrorText` is the
  boundary that enforces this: a Firebase code never reaches a person.
- Empty states name the missing thing and offer the control that creates it
  (§3.2). They do not apologise.

## 9. Localization as an interaction concern

Two locales ship (`shippedLocales` = `es`, `en`); `pt` is a 13-key template that
is deliberately not offered — `lib/i18n/README.md` has the full pipeline. Two
consequences belong here rather than there:

- **A missing key renders in Spanish, not as a crash or an empty box**
  (`fallback_strategy: base_locale`). A partially translated locale therefore
  degrades into mixed language, which is why `pt` is withheld rather than
  shipped incomplete.
- **The meeting's language is not the interface's language.** A congregation
  works from a workbook in its own language while a person may run the app in
  another; the week labels follow the workbook, the interface follows the
  person. This is the one place in the app where two languages are on screen at
  once, and it is intentional.

## 10. Known gaps

Stated rather than papered over.

1. **No shared snackbar.** Around fifteen call sites build a raw
   `SnackBar(content: Text(…))` by hand. A backup restored and a backup that
   failed to decrypt therefore look identical — same colour, no icon, no use of
   `colorScheme.error`. This is the largest single inconsistency in the app's
   feedback layer, and it is one widget's worth of work: an `AppSnackBar` with
   success/failure variants routed through one helper, the way `runExport`
   already forces both export surfaces down one path.
2. **A cancelled sign-in reports an error.** `CloudAuthErrorCode.canceled` maps
   to the "something went wrong" string. Dismissing the Google sheet is not a
   failure and should say nothing at all.
3. **Nothing is undoable.** Every destructive action is confirm-then-gone.
   Assignments, participants and projects are all local rows with a sync log
   behind them, so an undo window is affordable; none exists.
4. **No offline indicator outside Settings.** `SyncPhase.offline` is legible
   only to somebody already looking at the sync card. Nothing on the dashboard
   or in the editor says the cloud is unreachable — which is defensible under
   §1.2 and is also why nobody can tell a stale congregation from a current one.
5. **The state matrix is undocumented per screen and unverified anywhere.**
   §3 describes the registers; no screen has a written inventory of which ones
   it implements, and no test asserts that a surface with a loading state also
   has an empty one. `workspace_panel` gets the skeleton-before-empty ordering
   right; nothing would catch the next screen getting it wrong.
6. **No error copy review.** The strings exist and are translated, but nobody
   has read them as a set against a rule — some name the fix, some only name
   the failure.
7. **First-run has no measured path.** There is no instrumentation, so "time to
   first printed sheet" — the only activation metric that matters for this
   product — is unknown.
8. **The flows are where accessibility fails first.** `docs/ACCESSIBILITY.md`
   adopts WCAG 2.2 AA and walks all 55 criteria; four of its seven live
   failures are behavioural rather than visual — no status message is
   announced, no selection state is exposed, no heading structure exists, and
   the meeting's language is unmarked inside an interface in another. Every
   one of them lives in a pattern described above.
