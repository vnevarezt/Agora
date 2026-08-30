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
| 1.1.1 | Non-text Content | **Not met** | `AgoraMark`, `AgoraLockup` and `AgoraLoader` are `CustomPaint` with no `Semantics` label — the cover screen's brand and the preview's loader announce nothing. Icon-only buttons are covered: `Pressable` wraps `Semantics(button: true)` and `AppIconButton` forwards `tooltip` into `semanticLabel`. |
| 1.2.1 | Audio-only and Video-only | N/A | No audio or video anywhere in the product. |
| 1.2.2 | Captions (Prerecorded) | N/A | As above. |
| 1.2.3 | Audio Description or Media Alternative | N/A | As above. |
| 1.3.1 | Info and Relationships | **Partial** | Form fields are associated: `BoundTextField` uses `InputDecoration(labelText:)`. Headings are not: `SectionHeader` and `BlockTitle` are styled `Text` with no `Semantics(header: true)`, so a screen reader has no structure to navigate by. |
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
| 3.1.1 | Language of Page | **Not met** | `MaterialApp.locale` follows the active translation, but `web/index.html` ships `<html>` with no `lang` attribute, so the web build declares no language at all. One-line fix. |
| 3.2.1 | On Focus | Reviewed | Focus alone changes nothing but the focus ring. |
| 3.2.2 | On Input | Reviewed | No form submits on change. The Settings language dropdown does apply on selection, which is the control's stated purpose. |
| 3.2.6 | Consistent Help | N/A | No help, contact or support mechanism is offered on any screen, so there is nothing to keep consistent. |
| 3.3.1 | Error Identification | Reviewed | Errors are text: `AuthErrorText` under the field, `EmptyState(error:)` for a failed load, panel text for the preview. |
| 3.3.2 | Labels or Instructions | Reviewed | `labelText` on text fields, `LabeledField` on everything else. There are no placeholder-only fields. |
| 3.3.7 | Redundant Entry | Reviewed | No process asks for the same information twice. |
| 4.1.2 | Name, Role, Value | **Partial** | Name and role are handled by `Pressable`; `AppSwitch` exposes `toggled`. **Selected state is not exposed anywhere** — navigation destinations, `SegmentedTabs` and `FilterPill` all communicate selection visually only. |

## 3. Level AA

| SC | Title | Status | Notes |
|---|---|---|---|
| 1.2.4 | Captions (Live) | N/A | No media. |
| 1.2.5 | Audio Description | N/A | No media. |
| 1.3.4 | Orientation | Reviewed | No orientation is locked; iOS `Info.plist` allows portrait and both landscapes, and nothing calls `setPreferredOrientations`. |
| 1.3.5 | Identify Input Purpose | **Not met** | There is not one `autofillHints` in the codebase. Email and password fields therefore offer the platform nothing to fill, which also weakens 3.3.8. |
| 1.4.3 | Contrast (Minimum) | **Test** | `contrast_test`, 21 pairs per theme. Covers token pairs, not rendered screens: ink on a ground the list does not name is not covered. |
| 1.4.4 | Resize Text | **Test** | `text_scaling_test` at 2×. Sizes come from `AppText`, which scales; `scale_guard_test` keeps it that way. |
| 1.4.5 | Images of Text | Reviewed | The wordmark is a logotype, which the criterion exempts, and `AgoraLockup` builds it live in Manrope rather than shipping a bitmap. Everything else is real text. |
| 1.4.10 | Reflow | **Partial** | Breakpoints and container queries reflow to a phone, and `text_scaling_test` asserts no overflow at 320px × 2×. Reflow at 320 CSS px in the *browser* build is unverified. |
| 1.4.11 | Non-text Contrast | **Test** | `borderControl` is held at 3.0:1 on all three grounds in both themes, as are `successStrong` and `warningStrong`. The focus ring's own contrast is not asserted. |
| 1.4.12 | Text Spacing | N/A (native) / Unverified (web) | A native app has no user stylesheet to apply. The browser build has not been tested with the criterion's spacing overrides. |
| 1.4.13 | Content on Hover or Focus | Unverified | Tooltips are Material's own; whether they are dismissible and hoverable per the criterion has not been checked. |
| 2.4.5 | Multiple Ways | N/A | One application, not a set of pages. |
| 2.4.6 | Headings and Labels | **Partial** | Labels are descriptive. Headings are visual only — the same gap as 1.3.1. |
| 2.4.7 | Focus Visible | **Test** | `keyboard_focus_test` asserts the ring appears on keyboard focus and never on a mouse click, and that it does not resize the control. |
| 2.4.11 | Focus Not Obscured (Minimum) | Unverified | `ProjectBar` and the mobile bottom bar are fixed. Whether a focused control can end up behind one on a scrolled, text-scaled screen has not been checked. |
| 2.5.7 | Dragging Movements | **Partial** | Zoom has buttons. Panning a zoomed page has no button alternative, and the web workbook drop target has one — the file picker beside it. |
| 2.5.8 | Target Size (Minimum) | **Partial** | `Dimens.hTouchMin` (48) pads out `AppButton`, `AppIconButton` and `AppSwitch`, well past the 24×24 the criterion asks. No test asserts a minimum hit rect, and controls outside those three are unverified. |
| 3.1.2 | Language of Parts | **Not met** | The meeting's language and the interface's language are deliberately different (`UX_PATTERNS.md` §9), so week labels in one language sit inside a UI in another — with no markup saying so. This is the one criterion the product's own design guarantees it fails until it is handled. |
| 3.2.3 | Consistent Navigation | Reviewed | One shell, one order of destinations, on every screen and both form factors. |
| 3.2.4 | Consistent Identification | Reviewed | The widget catalog is the mechanism: the same function is the same component everywhere, and building a one-off where a catalog widget fits is treated as drift. |
| 3.3.3 | Error Suggestion | **Partial** | `cloudAuthErrorText` names every failure; not all of the strings say what to do about it (`UX_PATTERNS.md` §10.6). |
| 3.3.4 | Error Prevention | Reviewed | Every destructive action is confirmed in a modal, and `DeleteAccountModal` lists what blocks the delete before asking for anything. There is no undo, which the criterion does not require. |
| 3.3.8 | Accessible Authentication | **Partial** | No puzzle, no CAPTCHA, no cognitive function test; password, Google sign-in and device biometrics are all available. The missing `autofillHints` (1.3.5) is what stops password managers filling cleanly. |
| 4.1.3 | Status Messages | **Not met** | Snackbars are raw `SnackBar` with no live region, so an export finishing, a backup restoring and a sync failing are announced to nobody. Sync phase changes are likewise silent. |

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

1. **4.1.3 — nothing is announced.** Every snackbar is silent to a screen
   reader, so the outcome of an action a person just took is invisible unless
   they can see it. One `AppSnackBar` with `Semantics(liveRegion: true)` fixes
   the whole class, and `UX_PATTERNS.md` §10.1 already wants that widget for a
   different reason.
2. **4.1.2 — selection state is not exposed.** A screen reader user cannot tell
   which navigation destination, tab or filter is active. `Semantics(selected:)`
   on three widgets.
3. **1.3.1 / 2.4.6 — no headings.** With no `header: true` there is no
   structure to jump between, so every screen is a flat list of controls.
4. **3.1.2 — the second language is unmarked.** Content in the meeting's
   language is read out in the interface's language. This one is a product
   decision that created a criterion failure, so the fix belongs in the same
   place the decision does.
5. **1.1.1 — the mark announces nothing.** Three brand widgets need a label, or
   an explicit exclusion where they are decorative.
6. **1.3.5 / 3.3.8 — no autofill hints.** Email and password fields should
   carry `autofillHints`; it is a two-line change per field.
7. **3.1.1 — `web/index.html` has no `lang`.** One attribute.

## 6. What is unverified

Not failures — nobody has looked. Each needs the corresponding manual pass in
§4 before it can be called anything.

1.3.2 · 1.3.3 · 2.1.2 · 2.4.3 · 2.4.11 · 1.4.12 (web) · 1.4.13 · 1.4.10 (web),
plus the coverage caveats on 2.1.1, 1.4.3 and 2.5.8 above.

**Screen-reader traversal order is the single largest unknown**, because it is
the input to four separate criteria and the only one of the manual passes that
cannot be approximated by reading code.
