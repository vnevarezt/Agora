# Components

Per-widget reference for `lib/ui/widgets/`, the app's shared catalogue.
Building a one-off where one of these fits is drift.

What each entry carries is what the code does *not* say in one place: the
variants that exist, the states actually implemented, the accessibility
contract, and what the component is deliberately not for. The API itself lives
in the dartdoc above each class, and the rationale for a value lives in
`docs/DESIGN_SYSTEM.md` — neither is repeated here.

Status: **descriptive**, read out of the source on 2026-08-30. Appearance is
defended by `test/ui/golden/`, which renders the same composition
`GalleryScreen` shows at `/gallery` in a debug build.

Companion documents: `docs/DESIGN_SYSTEM.md` (tokens, scales, motion),
`docs/UX_PATTERNS.md` (when a state applies), `docs/ACCESSIBILITY.md` (the
standard the a11y lines are held to).

**States vocabulary**, used the same way throughout: *default · hover · pressed
· focused · disabled · busy · selected · error*. A component lists only the ones
it implements. "hover" is `hovered || pressed` everywhere, because `Pressable`
reports it that way — a touch device has no hover, so a control styled on hover
alone would sit inert under a finger.

---

## 1. Interaction primitives

Everything tappable in the app is built on one of these two. Nothing calls
`GestureDetector` directly.

### `Pressable`
The catalogue's foundation: hover and press detection, keyboard operability and
semantics for anything that is not a Material surface.
- **States** default · hover · pressed · focused · disabled
- **A11y** `Semantics(button: true)` with `enabled`, an optional `semanticLabel`
  — required in practice for icon-only controls — and `selected` for a control
  that is one of a set. Built on `FocusableActionDetector`, so Space and Enter
  fire `onTap` and the focus ring paints as a *foreground* decoration that never
  joins layout. `HitTestBehavior.opaque`, so a control with no background is
  still tappable between its glyphs.
- **Not for** cards. `InkSurface` keeps a real ripple for those.

### `InkSurface`
MD3 interactive card: real ripple, state layers, animated elevation and border.
- **States** default · hover · pressed · focused (Material's own)
- **A11y** inherits Material's `InkWell` semantics.
- **Not for** small controls — the ripple reads as noise below card size.

## 2. Buttons

### `AppButton`
- **Variants** `primary` · `ghost`; square when `label` is null
- **States** default · hover · pressed · focused · disabled (`onPressed: null`)
  · busy (`busy: true` puts `AppSpinner` where the icon goes and disables the
  button; the label stays)
- **A11y** grows with OS text scale rather than clipping
  (`text_scaling_test`); square instances pad their tap area out to
  `Dimens.hTouchMin`. Busy adds a hint saying why the control stopped
  responding, as a live region — otherwise a screen reader gets "dimmed" and no
  reason.
- **Not for** destructive actions. There is no danger variant on purpose.
- **Golden** `controls_*`

### `AppIconButton`
Icon-only button in a `size` box, below `hControl`.
- **Variants** plain · `bordered` · `elevated`
- **States** as `AppButton`
- **A11y** forwards `tooltip` into `semanticLabel`, so a tooltipped button is
  named for free; **one without a tooltip must pass the label itself**. Pads to
  `hTouchMin`; a caller positioning it precisely compensates by
  `(hTouchMin - size) / 2`.
- **Golden** `controls_*`

### `DangerButton`
The only affordance for a destructive action, in `colorScheme.error`.
- **States** default · hover · pressed · focused
- **Not for** anything reversible. It is a different object from `AppButton`,
  not a colour swap on it.
- **Golden** `controls_*`

### `ExportButton` · `runExport` · `ExportPanel`
The mobile export entry point, the shared execution path, and the
format/action selector both surfaces present.
- **Variants** `bar` (desktop project bar, icon + text) · `compact` (mobile
  project bar, icon only) · `full` (mobile bottom bar, full width)
- **States** busy, shared through `exportBusyProvider` so every export control
  in the app disables together
- **Not for** anything but export: `runExport` owns build → save/share →
  snackbar, and exists so the desktop menu and the mobile sheet cannot diverge.
- **Golden** `feedback_*` covers `ExportPanel` in both enabled states.

## 3. Selection and status marks

### `Pill`
Uppercase badge; the base under `StatusBadge`, `PrivBadge` and "Incompleto".
- **Variants** by caller-supplied `background` / `foreground` / `border`
- **States** none — it is a mark, not a control
- **Rule** one line, always. Given a width it cannot fit, it ellipsizes rather
  than wrapping: the participant grid lays out on a single tile extent, and a
  badge that grows a line taller clips the card it sits in.
- **Golden** `markers_*`

### `MiniChip`
Six named presets rather than a styling API: `.time` `.allMeeting` `.duration`
`.tag` `.aux` `.week`.
- **States** none
- **Golden** `markers_*`

### `FilterPill`
A toggling filter, with an optional colour dot and counter.
- **States** default · hover · pressed · focused · **selected**
- **A11y** `selected` reaches the screen reader through `Pressable`; the dot is
  never the only signal — the label carries the meaning.
- **Golden** `markers_*`

### `SegmentedTabs`
Assign/Preview on mobile; a static chip when `onChanged` is null.
- **Variants** content-sized · `expand` (equal widths)
- **States** default · hover · pressed · focused · selected
- **A11y** each segment is a `Pressable` reporting `selected`; the indicator
  slides rather than each segment fading its own background, so selection is
  carried by position as well as colour.
- **Golden** `controls_*`

### `AppSwitch`
A `Switch` painted below platform size while keeping a real 48×48 tap area.
- **States** on · off · non-`interactive` (for a row that owns the tap itself —
  two overlapping regions on the same callback double-fire)
- **A11y** `Semantics(toggled:)`
- **Golden** `controls_*`

## 4. Progress and waiting

### `ProgressRing`
Accent arc over a `border` base, count in the middle.
- **Variants** `showLabel` on/off, `size`
- **Golden** `markers_*`

### `ProgressMeter`
Linear bar: `border2` track, accent fill, fully rounded.
- **Golden** `markers_*`

### `AppSpinner`
The only indeterminate spinner inside a control. `Dimens.spinner` by default.
- **Not for** a whole panel — that wait belongs to `AgoraLoader`, and only one
  surface in the app has one.
- **Golden** `markers_*`

### `AgoraLoader`
The mark turning, for the one wait long enough to deserve a logo: the PDF
preview.
- **Motion** `Motion.loop`, deliberately **not** zeroed by Reduce Motion — an
  indeterminate indicator is the state, not decoration on it.
- **A11y** labelled and a live region.
- **Golden** none — it animates on a loop; the still frame would be arbitrary.

## 5. Structure

### `SectionHeader`
Colour dot, uppercase title, assigned/total.
- **A11y** `Semantics(header: true)` on the title, so there is structure to
  navigate by; the dot never carries meaning alone.
- **Golden** `structure_*`

### `BlockTitle`
Dashboard block title, counter, optional "Ver todo" link.
- **A11y** `header: true` on the title.
- **Golden** `structure_*`

### `ModalShell` · `showAppModal`
Handle (on a sheet), header, scrollable body, button footer. `showAppModal`
picks dialog on desktop and bottom sheet on mobile from one call site.
- **Variants** with/without `desc`; optional `dangerLabel` in the footer
- **States** `primaryBusy`
- **A11y** `header: true` on the modal title. Both presentations honour Reduce
  Motion by hand, because each builds its own route
  (`reduce_motion_test` covers both).
- **Not for** a flow that would otherwise be a fourth level of navigation — see
  `UX_PATTERNS.md` §2.3. That *is* what it is for.
- **Golden** `modal_*`, both presentations, one of them with a destructive
  action in the footer.

### `EmptyState`
Icon, optional title, message, optional action, optional error.
- **States** plain · with action · with error
- **Rule** every call site fills the action slot: an empty state names what is
  missing and hands over the control that creates it (`UX_PATTERNS.md` §3.2).
- **Golden** `structure_*`

### `AppSnackBar` (`showAppSnack`)
The app's only snackbar.
- **Variants** `AppSnackKind.success` · `failure`. There is no neutral kind: a
  snackbar only appears after something the person committed to has finished.
- **A11y** Flutter wraps every snackbar in a live region, so the message is
  announced; the icon distinguishes the two kinds by shape as well as colour.
- **Motion** `Motion.message` / `messageLong`, neither zeroed by Reduce Motion.
- **Golden** `snackbar_success_*` and `snackbar_failure_*`, driven through the
  messenger — one bar per mount, because showing the second dismisses the first
  and the handover is a race an image would sometimes lose.

## 6. Input

### `LabeledField`
Small uppercase label above any control.
- **Rule** the label is always present. There are no placeholder-only fields in
  the app; a placeholder vanishes the moment somebody starts typing.

### `BoundTextField`
Field seeded once from state, after which the provider is the source of truth.
- **Variants** `dense` · `obscureText` · `maxLines` · `enabled: false`
  (read-only, how a capability gate shows a member they may look but not edit)
- **A11y** `InputDecoration(labelText:)` associates the label, and
  `autofillHints` declares the field's purpose to the platform.

### `AppDropdown<T>` · `ReadonlyField`
A dropdown and a read-only computed value, both styled as a field so a settings
column reads as one column.

### `NotebookDropTarget`
Drag-and-drop for a workbook file. The browser build has a real one; every
other platform gets a stub whose `notebookDropSupported` is false — **nothing
that cannot take a file should offer to.**

## 7. Brand

### `AgoraMark` · `AgoraLockup` · `AgoraMarkEntrance`
The mark, the mark beside the wordmark, and the mark playing its entrance once
on mount.
- **Sizes** from `Dimens.mark*`, not `AppIcon` — the mark carries a surface, it
  is not a glyph set against text.
- **A11y** `AgoraMark` announces the product name; `AgoraLockup` excludes it,
  because the wordmark beside it is real text and labelling both would say the
  name twice.
- **Golden** `structure_*`

## 8. Utility

### `MeetingLanguage`
Marks a subtree as content in the congregation's meeting language rather than
the interface's.
- **Rule** wrap only text that came out of the workbook. Everything the app
  translates itself is in the interface's language, and marking it would be the
  same error inverted.

### `DashedBorder`
Flutter has none. Used by the empty avatar and the "Asignar…" button.

### `PersonAvatar`
Initials from the display name; a dashed empty state with a person icon when
there is no name.
- **Sizes** from `Dimens.avatar*`
- **Golden** `markers_*`

### `MotionSize` · `FadeThroughSwitcher` · `SlideSwitcher` · `AnimatedInk` · `EnterUp`
The shared motion widgets. Documented with their rationale in
`DESIGN_SYSTEM.md` §7; each fixes `Motion.curve` internally so a call site
cannot animate linearly by forgetting.

---

## What is not covered

- **Every component here is under an image.** Eighteen of them, in both
  themes, composed from `lib/ui/dev/gallery.dart` — the same file
  `GalleryScreen` renders at `/gallery` in a debug build, so what a developer
  looks at and what the images defend cannot drift apart.
- **No golden covers a screen.** The dashboard, the participants list, the
  settings tabs and the auth flow are compositions of the above and none of
  them is in an image; a regression in how a screen arranges its components is
  still caught only by looking at it.
- **No spec covers** the screen-level compositions in `lib/ui/dashboard/`,
  `participants/`, `workspace/`, `config/` and `auth/`. They are compositions of
  the above, and they are where the state matrix in `UX_PATTERNS.md` §3 lives.
