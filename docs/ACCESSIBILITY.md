# Accessibility

## The standard this project is held to

**Agora targets WCAG 2.2 Level AA.**

Until now `docs/DESIGN_SYSTEM.md` §12 listed five commitments and four tests
that defend them, but named no external standard — so "accessible" had no
definition anybody could be measured against, and no way to tell a gap from an
opinion. This document adopts one and walks all 55 Level A and Level AA success
criteria against the code.

Status: **audited by reading the source on 2026-08-29.** This is a
self-assessment, not a certified conformance claim, and §5 lists the criteria
that fail today. Nothing here may be published as a conformance statement while
those remain open.

### Why WCAG for an app that is mostly not a web page

WCAG is written for web content, and Agora ships to six platforms of which one
is the browser. It is adopted anyway because it is the only standard with
testable criteria that regulators, congregations and app stores all recognise,
and because the [W3C's own guidance on applying WCAG to non-web
software](https://www.w3.org/TR/wcag2ict/) exists for exactly this. Read
"web page" as "screen" and "user agent" as "the platform accessibility API"
throughout. Criteria that only have meaning inside a document-and-URL model are
marked **N/A** below with the reason.

Two platform obligations sit alongside WCAG rather than inside it, and both are
binding:

- **Touch targets at or above the platform minimum** — 44pt iOS, 48dp Android.
  This is stricter than WCAG 2.5.8, which asks 24×24 CSS px.
- **OS text scaling and Reduce Motion are honoured**, not merely tolerated.

### Scope

| In scope | Out of scope |
|---|---|
| Every screen under `lib/ui/` on all six platforms | The generated PDF (see below) |
| The `web/` build's shell (`index.html`) | The marketing site under `site/` — audited separately, not yet done |

**The PDF is deliberately out of scope.** It is a printed artifact whose layout
is fixed by the official S-140 form (`DESIGN_SYSTEM.md` §11); it is not tagged
for accessibility and PDF/UA is not targeted. If that changes, the criteria to
walk are PDF/UA-1, not these.

---

## 1. What is enforced by tests

Four suites fail the build if an existing commitment regresses. They are the
only parts of this document that cannot silently rot.

| Test | Defends |
|---|---|
| `test/ui/semantics_test.dart` | selection state, heading role and the inline error's live region — 4.1.2, 1.3.1 and 4.1.3 |
| `test/ui/contrast_test.dart` | 21 (ink, ground) pairs against 4.5:1 or 3.0:1, in **both** themes — 1.4.3 and 1.4.11 |
| `test/ui/text_scaling_test.dart` | a control grows rather than clipping at 2× text, and does not overflow a 320px phone — 1.4.4 and part of 1.4.10 |
| `test/ui/keyboard_focus_test.dart` | tab traversal reaches a control, Space and Enter activate it, the ring is visible, and focus never resizes the control — 2.1.1 and 2.4.7 |
| `test/ui/reduce_motion_test.dart` | every catalog surface and both modal routes honour Reduce Motion — 2.2.2, and the platform obligation |

`test/ui/scale_guard_test.dart` and `test/ui/motion_guard_test.dart` defend the
design system rather than a criterion, but both feed this: a bare font size is
how a screen stops scaling, and a raw `Duration` is how an animation escapes
Reduce Motion.

## 2. Level A

| SC | Title | Status | Notes |
|---|---|---|---|
| 1.1.1 | Non-text Content | Reviewed | `AgoraMark` announces the product name and `AgoraLoader` announces that it is loading. `AgoraLockup` excludes the mark from semantics on purpose — the wordmark beside it is real text, and labelling both would say the name twice. Icon-only buttons: `Pressable` wraps `Semantics(button: true)` and `AppIconButton` forwards `tooltip` into `semanticLabel`. |
| 1.2.1 | Audio-only and Video-only | N/A | No audio or video anywhere in the product. |
| 1.2.2 | Captions (Prerecorded) | N/A | As above. |
| 1.2.3 | Audio Description or Media Alternative | N/A | As above. |
| 1.3.1 | Info and Relationships | Reviewed | Fields are associated by `InputDecoration(labelText:)`. Headings are exposed with `Semantics(header: true)` — `SectionHeader`, `BlockTitle`, the three screen titles, the auth card title and the modal header. |
| 1.3.2 | Meaningful Sequence | Unverified | Traversal order has never been walked with a screen reader. |
| 1.3.3 | Sensory Characteristics | Unverified | No instruction found that depends on shape or position, but all 365 strings have not been read against this. |
| 1.4.1 | Use of Color | Reviewed | Navigation selection carries three simultaneous signals — indicator surface, outline→filled icon crossfade, weight change. Section identity pairs a colour dot with an uppercase title. Status is a `Pill` with text in it. |
| 1.4.2 | Audio Control | N/A | No audio. |
| 2.1.1 | Keyboard | **Test** (partial) | `Pressable` is built on `FocusableActionDetector`; `keyboard_focus_test` covers the catalog. The person-picker popover and the modal routes are not covered. |
| 2.1.2 | No Keyboard Trap | Unverified | Modals and the bottom sheet have never been checked for a trap. |
| 2.1.4 | Character Key Shortcuts | Reviewed | The app defines no `Shortcuts`, `CallbackShortcuts` or `SingleActivator` at all. |
| 2.2.1 | Timing Adjustable | Reviewed | Nothing expires under the user. The resend cooldown is a rate limit on a button, not a time limit on a task. |
| 2.2.2 | Pause, Stop, Hide | **Test** | Everything animated goes through `Motion.of` and stops under Reduce Motion. `Motion.loop` is the deliberate exception and is a progress indicator, which the criterion exempts. |
| 2.3.1 | Three Flashes | Reviewed | Nothing flashes. The fastest animation is 150 ms and plays once. |
| 2.4.1 | Bypass Blocks | N/A | Single-screen app shell; navigation is a sibling region, not a block repeated ahead of the content on every page. |
| 2.4.2 | Page Titled | **Partial** | `MaterialApp.title` is `Agora` and the web document title is static. No screen sets its own title, so on the web every view is "Agora". |
| 2.4.3 | Focus Order | Unverified | Same gap as 1.3.2. |
| 2.4.4 | Link Purpose (In Context) | Reviewed | Every actionable control carries its own label; there is no bare "here" or "more". |
| 2.5.1 | Pointer Gestures | Reviewed | The only multipoint gesture is pinch-zoom in the PDF preview, and zoom in / zoom out / fit page / fit width all exist as buttons beside it. |
| 2.5.2 | Pointer Cancellation | Reviewed | `Pressable` fires on tap-up, so a press can be aborted by dragging off. |
| 2.5.3 | Label in Name | **Partial** | `AppIconButton` derives `semanticLabel` from `tooltip`, so the two agree by construction. Nothing stops a caller passing an unrelated `semanticLabel` to `AppButton`, which would put the accessible name out of step with the visible one. |
| 2.5.4 | Motion Actuation | N/A | Nothing responds to shaking or tilting. |
| 3.1.1 | Language of Page | Reviewed | `MaterialApp.locale` follows the active translation, `web/index.html` ships the base locale, and `setDocumentLang` rewrites `<html lang>` at boot and on every language change. Non-web platforms get a no-op, having no document to label. |
| 3.2.1 | On Focus | Reviewed | Focus alone changes nothing but the focus ring. |
| 3.2.2 | On Input | Reviewed | No form submits on change. The Settings language dropdown does apply on selection, which is the control's stated purpose. |
| 3.2.6 | Consistent Help | N/A | No help, contact or support mechanism is offered on any screen, so there is nothing to keep consistent. |
| 3.3.1 | Error Identification | Reviewed | Errors are text: `AuthErrorText` under the field, `EmptyState(error:)` for a failed load, panel text for the preview. |
| 3.3.2 | Labels or Instructions | Reviewed | `labelText` on text fields, `LabeledField` on everything else. There are no placeholder-only fields. |
| 3.3.7 | Redundant Entry | Reviewed | No process asks for the same information twice. |
| 4.1.2 | Name, Role, Value | Reviewed | Name and role come from `Pressable`, `AppSwitch` exposes `toggled`, and selection is exposed through `Pressable.selected` (`SegmentedTabs`, `FilterPill`) and a `Semantics` wrapper on the sidebar rail, which is built on `InkWell` rather than `Pressable`. The mobile bar is Material's own `NavigationBar`. |

## 3. Level AA

| SC | Title | Status | Notes |
|---|---|---|---|
| 1.2.4 | Captions (Live) | N/A | No media. |
| 1.2.5 | Audio Description | N/A | No media. |
| 1.3.4 | Orientation | Reviewed | No orientation is locked; iOS `Info.plist` allows portrait and both landscapes, and nothing calls `setPreferredOrientations`. |
| 1.3.5 | Identify Input Purpose | Reviewed | Every auth field declares its purpose through `BoundTextField(autofillHints:)` — name, email, `password` when signing in and `newPassword` when registering. The fields are not wrapped in an `AutofillGroup`, which affects how cleanly a manager *saves* a credential, not whether the purpose is identified. |
| 1.4.3 | Contrast (Minimum) | **Test** | `contrast_test`, 21 pairs per theme. Covers token pairs, not rendered screens: ink on a ground the list does not name is not covered. |
| 1.4.4 | Resize Text | **Test** | `text_scaling_test` at 2×. Sizes come from `AppText`, which scales; `scale_guard_test` keeps it that way. |
| 1.4.5 | Images of Text | Reviewed | The wordmark is a logotype, which the criterion exempts, and `AgoraLockup` builds it live in Manrope rather than shipping a bitmap. Everything else is real text. |
| 1.4.10 | Reflow | **Partial** | Breakpoints and container queries reflow to a phone, and `text_scaling_test` asserts no overflow at 320px × 2×. Reflow at 320 CSS px in the *browser* build is unverified. |
| 1.4.11 | Non-text Contrast | **Test** | `borderControl` is held at 3.0:1 on all three grounds in both themes, as are `successStrong` and `warningStrong`. The focus ring's own contrast is not asserted. |
| 1.4.12 | Text Spacing | N/A (native) / Unverified (web) | A native app has no user stylesheet to apply. The browser build has not been tested with the criterion's spacing overrides. |
| 1.4.13 | Content on Hover or Focus | Unverified | Tooltips are Material's own; whether they are dismissible and hoverable per the criterion has not been checked. |
| 2.4.5 | Multiple Ways | N/A | One application, not a set of pages. |
| 2.4.6 | Headings and Labels | Reviewed | Labels are descriptive and headings are exposed as headings — see 1.3.1. |
| 2.4.7 | Focus Visible | **Test** | `keyboard_focus_test` asserts the ring appears on keyboard focus and never on a mouse click, and that it does not resize the control. |
| 2.4.11 | Focus Not Obscured (Minimum) | Unverified | `ProjectBar` and the mobile bottom bar are fixed. Whether a focused control can end up behind one on a scrolled, text-scaled screen has not been checked. |
| 2.5.7 | Dragging Movements | **Partial** | Zoom has buttons. Panning a zoomed page has no button alternative, and the web workbook drop target has one — the file picker beside it. |
| 2.5.8 | Target Size (Minimum) | **Partial** | `Dimens.hTouchMin` (48) pads out `AppButton`, `AppIconButton` and `AppSwitch`, well past the 24×24 the criterion asks. No test asserts a minimum hit rect, and controls outside those three are unverified. |
| 3.1.2 | Language of Parts | Reviewed | The `MeetingLanguage` widget sets `localeForSubtree` on the text that comes out of the workbook — the week heading in the editor bar and on the dashboard cards, and the numbered part titles. The boundary is drawn in the model rather than guessed at the call site: `PartView.titleFromWorkbook` is true for `RowKind.part` and for a hand-typed override, and false for the songs, the opening and closing words and the circuit overseer's talk, which this app translates itself. |
| 3.2.3 | Consistent Navigation | Reviewed | One shell, one order of destinations, on every screen and both form factors. |
| 3.2.4 | Consistent Identification | Reviewed | The widget catalog is the mechanism: the same function is the same component everywhere, and building a one-off where a catalog widget fits is treated as drift. |
| 3.3.3 | Error Suggestion | **Partial** | `cloudAuthErrorText` names every failure; not all of the strings say what to do about it (`UX_PATTERNS.md` §10.6). |
| 3.3.4 | Error Prevention | Reviewed | Every destructive action is confirmed in a modal, and `DeleteAccountModal` lists what blocks the delete before asking for anything. There is no undo, which the criterion does not require. |
| 3.3.8 | Accessible Authentication | Reviewed | No puzzle, no CAPTCHA, no cognitive function test; password, Google sign-in and device biometrics are all available, and the fields now carry autofill hints (1.3.5). |
| 4.1.3 | Status Messages | **Partial** | Snackbars are covered by the framework: Flutter wraps every one in `Semantics(container: true, liveRegion: true)`. `AuthErrorText` and the sync card's status row are live regions of their own — the sync row as a whole, because "Error" without its reason is not a status message. A button entering its busy state still announces nothing beyond becoming disabled. |

## 4. How to verify

```sh
flutter test test/ui/          # the four suites above, plus the guards
```

Manual passes, none of which have been done end to end:

- **Screen reader**: VoiceOver (iOS/macOS), TalkBack (Android), NVDA (web).
  Walk the first-run flow, the editor and the settings tabs. This is the pass
  that would close 1.3.1, 1.3.2, 2.4.3 and 4.1.2 at once.
- **Keyboard only**: unplug the mouse, complete a week and export it.
- **Text at 200%**, on the smallest supported phone, in both themes.
- **Reduce Motion on**, then the same walk.

## 5. What fails today

Ordered by how much a person is blocked, not by how hard it is to fix.

1. **4.1.3 — a busy button announces only that it is disabled.** `AppButton`
   swaps its label for a spinner while it works, and a screen reader is told
   nothing about why the control stopped responding. It is the last of the
   in-place status cases; the sync row and the inline errors are handled.

That is the whole list. The seven open on 2026-08-29 are closed but one, and
three of them are now defended by `semantics_test` rather than by a reading.

**None of this substitutes for the manual passes in §4.** Every closure above
was verified by reading the code or by a semantics assertion, which proves the
property is set — not that the result is usable. Traversal order, whether the
announcements arrive in a sensible sequence, and whether a person can actually
complete a week with a screen reader are all still unknown.

Two things that are *not* on this list and could look like they should be. A
snackbar carries no icon and no colour, so success and failure look identical —
that is a real defect, but it is a UX one (`UX_PATTERNS.md` §10.1), not a
criterion failure: the text distinguishes them and 1.4.1 asks no more. And
there is no undo anywhere, which 3.3.4 does not require once every destructive
action is confirmed.

## 6. What is unverified

Not failures — nobody has looked. Each needs the corresponding manual pass in
§4 before it can be called anything.

1.3.2 · 1.3.3 · 2.1.2 · 2.4.3 · 2.4.11 · 1.4.12 (web) · 1.4.13 · 1.4.10 (web),
plus the coverage caveats on 2.1.1, 1.4.3 and 2.5.8 above.

**Screen-reader traversal order is the single largest unknown**, because it is
the input to four separate criteria and the only one of the manual passes that
cannot be approximated by reading code.
