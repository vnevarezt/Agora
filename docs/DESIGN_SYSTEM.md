# Design System

Reference for Agora's visual and interaction layer. Status: **descriptive, not
aspirational** — everything below is what `lib/ui/` does today, read out of the
code. Where the system has a gap, §13 says so instead of inventing a rule.

**Every value below is checked against the source by
`test/ui/design_doc_test.dart`** — the colours, all three scales, the durations,
the curves and the breakpoints. If this file and `lib/ui/` disagree on a number,
the build says so. The prose is not checked and never will be, so a rationale
here can still go stale where a value cannot; when the two disagree, the code is
right.

The colour, motion, text-scaling and keyboard rules are enforced by tests
(§12), so this document and the code cannot drift apart silently.

Companion documents: `PRODUCT.md` (who this is for and what it must never
claim), `docs/UX_PATTERNS.md` (how the same interface *behaves* — navigation,
states, errors, flows), `docs/ACCESSIBILITY.md` (the standard all three are
held to), `docs/DATA_ARCHITECTURE.md` (the data layer this UI reads).

**Provenance.** The token names, the `Dimens` constants and most component
doc-comments refer to a **CSS/HTML mock** (`.sidebar`, `.portada--a`, `.projbar`,
`.btn--primary`, `--bg`, `--accent`…) that is **not in this repository**. That
mock was the original source of truth; it no longer is. `lib/ui/theme/` is.
When code and mock disagree, code wins — there is nothing to diff against.

---

## 1. Principles

Four rules decide arguments, in this order:

1. **The PDF is the product; the app is the means.** Anything that widens the
   gap between what is on screen and what leaves the printer is a defect,
   however good it looks. This is why §11 exists in a UI document at all.
2. **Form factor adapts, identity does not.** Phone and desktop are both real
   working scenes and get equal attention, but they are one product with one
   visual language — not a desktop tool with a phone port. There is **no
   Cupertino usage anywhere in `lib/`**; the app does not restyle itself per OS.
   Platform conventions bind where they are about *behavior*: safe areas, touch
   targets, back navigation, font scaling, reduced motion.
3. **Legibility outranks density.** When a layout decision trades reading
   comfort for information volume, reading comfort wins. A significant share of
   the people who prepare programs are older users; this is a requirement, not
   a preference.
4. **Depth comes from layering, not from shadows.** Surfaces are flat at rest.
   `bg → surface → surface2` plus a 1px border does the work; the five shadows
   in §6 are the enumerated exceptions.

## 2. The token contract

`AppTokens` (`lib/ui/theme/tokens.dart`) is a Flutter `ThemeExtension` holding
23 colors, mirroring the mock's CSS custom properties. An `AppPalette` bundles a
light and a dark `AppTokens`. Access is always `context.tokens.<role>`.

```dart
final t = context.tokens;
color: t.surface, border: Border.all(color: t.border)
```

**A literal `Color(0x…)` in `lib/ui/` outside `tokens.dart` and `dimens.dart` is
drift.** The exceptions are enumerated:

- the shadow/scrim constants in `Elevation`;
- the S-140 section identity colors in `kSectionColors` (§3.4);
- the brand inks in `widgets/agora_mark.dart` (§3.5) — the mark is one drawing
  on every palette, so it does not take theme tokens;
- the four Google brand colors in `auth/widgets/google_button.dart` — official
  brand assets must not be re-tinted;
- `_paper` in `preview/pdf_preview_view.dart`, the white of the sheet: the
  preview shows paper, and paper does not follow the app theme;
- the PDF palette in `lib/pdf/pdf_theme.dart`, which is print, not screen (§11).

`tokens.dart` is also the source for the marketing site: `tool/gen_css_tokens.py`
generates `site/tokens.css` from it. Edit the palette, re-run the script, and the
landing page follows the product instead of drifting a shade away from it.

Only one palette ships: **`pizarra`**. `AppPalette` exists so more can be added
(the code names Granate, Salvia and Biblioteca as candidates); none are built.

## 3. Color

### 3.1 Structural roles

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F8FAFD` | `#12161B` | app canvas / scaffold |
| `surface` | `#FFFFFF` | `#1A1F26` | cards, bars, modals |
| `surface2` | `#F4F7FB` | `#21272F` | inputs, insets, table headers |
| `border` | `#DEE2E7` | `#2F3742` | decorative hairline: cards, dividers |
| `border2` | `#ECEFF2` | `#272E37` | quieter internal dividers |
| `borderControl` | `#878F9B` | `#6B7686` | outline of an interactive control |
| `text` | `#1F242D` | `#ECEFF2` | primary ink |
| `textDim` | `#5D646F` | `#A6ABB2` | secondary ink, default icon color |
| `textMute` | `#6B7079` | `#979CA4` | hints, placeholders, uppercase labels |

**The dark ground is deliberately not near-black.** It used to be `#0B0F14`,
darker than the `#121212` Material recommends and dark enough that body text
landed at 16.65:1 — far past what accessibility asks for and into the range that
tires the eye at night. It read as the lights being off rather than as a theme
anyone designed. The whole ground scale moved up together, and two ink tokens
had to move with it: `textMute` over `surface2` would have fallen to 4.39, and
`borderControl` to 2.87, under the 3.0 WCAG 1.4.11 asks of a control outline.
The values were solved for rather than eyeballed; the tightest pair in the dark
theme now sits at 5.45 (`textMute` on `surface2`) and text on `bg` at 15.74.

`border` and `borderControl` are split on purpose. WCAG 1.4.11 asks 3:1 of
anything that identifies a control, and a decorative divider carries no such
floor — holding both to 3:1 would turn every hairline into a rule and lose the
flat, layered look §1.4 depends on. Inputs and ghost buttons outline with
`borderControl`; cards and dividers keep the hairline.

### 3.2 Accent

| Token | Light | Dark | Use |
|---|---|---|---|
| `accent` | `#405CB5` | `#7292F1` | primary fill, focus ring, switch on |
| `accentStrong` | `#2F48A7` | `#5E7FE3` | pressed, links, emphasis on tint |
| `accentInk` | `#FAFBFF` | `#080C1A` | ink ON accent |
| `accentSoft` | `#EAF0FF` | `#28324D` | selected/tint background |
| `accentTint` | `#F3F7FF` | `#1D2331` | the faintest wash |
| `accentOnSoft` | `#2F48A7` | `#7C9EFF` | ink ON `accentSoft`/`accentTint` |

**The ramp sits on the mark's hue.** The app was designed before the logo
existed, so the accent was picked on its own — an unsaturated slate blue on
oklch hue 262, against the mark's 268. Six degrees is not a difference anyone
can name, which is exactly the problem: the logo and the button beside it read
as two blues that almost match, and almost is worse than either matching or
contrasting. The accent moved onto the mark. **The code is the current value;
the older, greyer blues are history, not a target to restore.**

Only the hue moved. Lightness is what drives contrast, so holding it is why
`contrast_test` needed no re-tuning. Chroma rose on `accent`, `accentStrong`
and `accentOnSoft` alone — the soft, tint and ink steps are near-white or
near-black, where added chroma clips out of sRGB rather than reading as color.
The mark keeps more chroma than any of these on purpose: matching it would put
every button in competition with the logo. The family is shared, the intensity
is not. The ramp still has to sit next to the S-140 band colors (§3.4) without
competing with them, which is what keeps it off a saturated blue.

`accentOnSoft` exists because the theme is not symmetric. In light mode it is
`accentStrong` (7.06:1 on `accentSoft`); in dark, `accentStrong` on `accentSoft`
lands at 3.40:1, which had put **both** states of the bottom navigation below AA
at once. A separate ink token fixes every tinted surface — nav, privilege badge,
draft badge, add chip — without restyling the tint itself, and reaches 4.95:1 on
`accentSoft` and 6.13:1 on `accentTint`.

### 3.3 Status, and what is *not* status

Three families, each a soft tint used as a background plus the ink that sits on
it. `*Strong` is the solid version for marks that sit directly on `bg`/`surface`
with no tint behind them (dots, standalone icons); it holds the same value in
both themes, because a mark with no tint behind it has the same job either way.

| Token | Light | Dark | Use |
|---|---|---|---|
| `success` | `#2E6A3E` | `#A9D8B8` | ink: complete, up to date |
| `successSoft` | `#DCF0E0` | `#1E3A2A` | the tint that ink sits on |
| `successStrong` | `#4FA06A` | `#4FA06A` | solid mark, no tint behind it |
| `warning` | `#7A6512` | `#D9C27A` | ink: pending, attention |
| `warningSoft` | `#F3ECD2` | `#3A3115` | the tint that ink sits on |
| `warningStrong` | `#B9890F` | `#B9890F` | solid mark, no tint behind it |
| `alert` | `#A94F2B` | `#E8A38C` | ink: overdue, nothing assigned |
| `alertSoft` | `#FBE7DF` | `#40231C` | the tint that ink sits on |

There is no `alertStrong`: nothing in the app marks "overdue" with a bare dot,
and a token with no call site is a claim the system cannot keep.

**`colorScheme.error` is a separate axis** (`#B3261E` light / `#F2B8B5` dark).
Error means validation failure and destructive action; the three families above
mean *content status*. Do not substitute one for the other.

### 3.4 Section identity (S-140 bands)

`kSectionColors` in `lib/ui/theme/dimens.dart` — the only screen colors that
exist outside the palette, because they are quotations of the printed form:

| Section | Screen | PDF (`pdf_theme.dart`) |
|---|---|---|
| Tesoros de la Biblia | `#5C5C5C` | `#575A5D` |
| Seamos mejores maestros | `#B9890F` | `#BE8900` |
| Nuestra vida cristiana | `#8C1B2E` | `#7E0024` |

The screen values are the mock's; the PDF values are taken exactly from the
official format. They are close but **not identical, on purpose** — screen and
paper are different substrates. Opening (`apertura`) has no color.

### 3.5 Brand inks

The mark is one drawing on every palette, so it does not take theme tokens.
`widgets/agora_mark.dart` holds the inks, hand-copied from
`tool/gen_brand_assets.py` — the generator that renders everything under
`assets/brand/` and the source of truth for the geometry.
`test/ui/agora_mark_test.dart` fails if the two disagree.

| Role | On light | On dark |
|---|---|---|
| Back plane | `#14208F` | `#3350E0` |
| Front plane | `#4AA8EE` | `#4AA8EE` |
| Wordmark | `#14208F` | `#ECEFF2` |

Only the back plane changes: `#14208F` drowns below `#1A1F26`. The wordmark on
light is brand navy rather than the `text` token, because matching it is what
makes the in-app lockup and the one in the stores read as the same object.

Two planes cut by one diagonal, separated by air rather than by an outline —
which is why there is no separate outline version. Lockup proportions for a
mark of height H: gap `0.30 H`, font size `0.63 H` in Manrope ExtraBold,
tracking `-0.035em`. Build it live (`AgoraLockup`) rather than shipping the PNG;
the PNGs exist for READMEs, stores and anything outside the app. Full asset
rules, including the app-icon copy steps for all six platforms, are in
`assets/brand/README.md`.

## 4. Typography

Two families, both bundled — no webfont fetch, no silent fallback.

- **Manrope** (400/500/600/700/800) — everything.
- **JetBrains Mono** (500/600) — times, codes, percentages, counts. Always via
  `AppText.mono()`, which sets `FontFeature.tabularFigures()` so digits align.
- **Carlito** (regular/bold/italic/bold-italic) — PDF only, never on screen. It
  is a metric-compatible Calibri clone, which is what makes the generated
  document match the official S-140 (§11).

### 4.1 The scale

Nine steps, in `AppText` (`lib/ui/theme/app_theme.dart`). **A bare font size at
a call site is drift**, and `test/ui/scale_guard_test.dart` now says so.

| Step | pt | Role |
|---|---|---|
| `micro` | 10.5 | uppercase labels and badges — the floor, with one recorded exception (§13) |
| `caption` | 11.5 | secondary and helper text |
| `small` | 12.5 | dense supporting text inside cards and rows |
| `body` | 13.5 | default reading size |
| `bodyLarge` | 15 | emphasised body: names, list item titles |
| `title` | 16.5 | section and modal titles |
| `display` | 19 | screen titles and large counts |
| `displayLarge` | 21 | the same screen title above the mobile breakpoint |
| `brand` | 30 | the product name set as type, on the cover screen only |

Deliberately coarse. It replaced a free-form scale that had grown to **nineteen
distinct values between 9.5 and 19** with no rule for choosing among them, which
is why equivalent elements on different screens did not match.

`displayLarge` and `brand` were added when the guard went in, because both were
already in use and neither had a name: every top-level view was writing
`isMobile ? 19 : 21` by hand and the auth card was writing `20 : 22` — the same
role at almost the same size, which is the exact failure a scale exists to
prevent. `brand` has one call site and must keep it: it belongs to the mark, not
to the interface.

### 4.2 Weight and tracking

The app runs heavy: `w600` is the *default* body weight, not an emphasis.

| Style | Size | Weight | Tracking |
|---|---|---|---|
| `bodyLarge` | 15 | 600 | −0.15 |
| `bodyMedium` | 13.5 | 600 | −0.10 |
| `bodySmall` | 11.5 | 600 | 0 |
| `titleLarge` | 16.5 | 800 | −0.30 |
| `titleMedium` | 15 | 700 | −0.15 |
| `labelLarge` | 13.5 | 700 | 0 |
| `AppText.label()` | 10.5 | 700 | **+0.45**, uppercase |

Negative tracking tightens as size grows; the one positive value is the small
uppercase label, which needs the air. `AppText.label()` expects text **already
uppercased** by the caller — it does not transform.

### 4.3 Icon sizes

`AppIcon`, same file, same rule: **a bare icon size at a call site is drift.**

| Step | px | Role |
|---|---|---|
| `inline` | 13 | inside a chip, badge or pill, set against small text |
| `control` | 17 | the default: buttons, list rows, toolbars |
| `nav` | 24 | a navigation destination, rail and bottom bar alike |
| `feature` | 26 | carries a section or an empty state on its own |
| `hero` | 40 | brand marks, full-screen empty states |

It replaced nine sizes — 12, 13, 15, 16, 17, 18, 19, 26, 40 — five of them
between 15 and 19. The `nav` step is its own tier because the same three
destinations had drifted to 21 on the desktop rail and 24 in the mobile bar;
24 is also Material's own value for a bar destination.

## 5. Radius, size, spacing

`Dimens` (`lib/ui/theme/dimens.dart`) carries sizes only; durations live in
`Motion` (§7).

| Radius | px | Applied to |
|---|---|---|
| `rChip` | 7 | chips, badges, small toggles |
| `rControl` | 10 | buttons, inputs, snackbars |
| `rAssignee` | 11 | assignment button |
| `rCard` | 14 | cards, popovers |
| `rPicker` | 16 | person picker panel |
| `rSheet` | 22 | mobile bottom sheet, top corners only |
| `rPill` | 999 | pills, meters, scrollbar thumb |

| Height | px | Control |
|---|---|---|
| `hControl` | 38 | bar buttons and icon buttons |
| `hField` | 40 | settings inputs |
| `hAssignee` | 44 | assignment button |
| `hPreviewBar` | 46 | preview toolbar |
| `hExportMobile` | 48 | mobile export button |

`hTouchMin` 48 is not a control height but a floor: the tap area a control is
padded out to when its painted size is smaller. `AppButton` expands any square
control below it, and `AppSwitch` keeps a full 48×48 region around a switch
painted smaller than the platform default — a bare `Transform.scale` shrinks the
hit region along with the paint, which is how the toggles fell under the floor.

Two icon-button boxes below `hControl`: `hIconCard` 30 (an overflow button
pinned inside a card) and `hIconModal` 32 (the close button on a modal header).
Both keep the `hTouchMin` tap area. They are 2px apart, which is one step more
than the system should need — §13.

| Family | Steps | Note |
|---|---|---|
| Avatar | `avatar` 30 · `avatarBar` 32 · `avatarRow` 34 · `avatarCard` 38 · `avatarHero` 62 | `avatar` is `PersonAvatar`'s default and what the picker rows are laid out against |
| Brand mark | `markNav` 30 · `markLoader` 44 · `markCover` 52 · `markSplash` 64 | not `AppIcon` steps: the mark carries a surface, it is not a glyph set against text (§3.5) |
| Spinner | `spinnerInButton` 15 · `spinner` 16 · `spinnerLarge` 20 | `spinner` is `AppSpinner`'s default |

Other: `ring` 34 · `pickerW` 340 · `pickerMaxH` 460.

### 5.1 Spacing

`Space`, in the same file. Nine steps, named by magnitude because spacing has no
roles — only distances: **2 · 4 · 6 · 8 · 10 · 12 · 14 · 18 · 24**.

They are the values the UI already leaned on; 6, 8, 10, 12 and 14 alone covered
208 of 434 uses. What they replace is the 28-value spread around them, half of
it odd, where 9, 11 and 13 sat between the real steps for no reason anyone could
name. Ties round up, so 16 joins 18 rather than crowding the dense middle.

**1px is deliberately not a step:** a hairline is a border, not a gap.

Two layout predictors — `participantCardHeight` and `personPickerRowHeight` —
derive their padding from `Space` rather than restating it. They used to hold
their own copy of the number, which is how one of them silently drifted from
the widget it predicts.

## 6. Elevation

Five shadows, ordered by how far the surface sits off the canvas. **A one-off
`BoxShadow` is drift.**

| Name | Shadow | Used by |
|---|---|---|
| `control` | `0 1 2` @ 8% | resting lift under a primary control |
| `raised` | `0 2 8` @ 10% | a control floating over content (preview zoom) |
| `popover` | `0 10 24` @ 15% | menus, dropdowns, pickers anchored to a trigger |
| `modal` | `0 12 40` @ 20% + `0 4 12` @ 10% | dialogs and sheets — ambient pool plus contact shadow, so the surface reads lifted rather than pasted on |
| `page` | `0 8 30` @ 14% + `0 2 8` @ 8% | the PDF page in the preview: physical paper |

Plus one ring, which is not a shadow but belongs to the same vocabulary so it
stops being a one-off at a call site: `Elevation.selectionHalo(accent)` — the
halo around the card the editor is working on. It takes the accent because the
`accentSoft` it was built from sits at 1.5:1 on the dark surface, which made
the active card indistinguishable from the rest in dark mode.

Scrims: `scrim` `#47000000` behind an anchored panel, `scrimStrong` `#52000000`
behind a full modal, which must dim more of the app.

## 7. Motion

One curve, one duration scale (`lib/ui/widgets/motion.dart`).

- **`curve` `Cubic(.2, .8, .3, 1)`** — the default ease-out: the shape a
  critically damped spring draws, leaves fast, settles slowly, never overshoots.
  Overshoot belongs to motion that inherited momentum from a gesture, and
  nothing here is dragged or flicked, so no curve in the app overshoots.
  `Motion.curveOut` is this one mirrored, for the return leg of a reversible
  transition.
- **`arrive` `Cubic(.16, 1, .3, 1)`** — the arrival curve, for content
  travelling a visible distance on its way in. `curve` decelerates gently,
  which is right for a control settling into a new state a few pixels away;
  over 14px or more it reads as drift. `arrive` dumps almost all its speed in
  the first third, so the element looks placed rather than floated into
  position. **The two are not interchangeable**: entrances and content swaps
  take `arrive`, state and press feedback stay on `curve`.
- **`instant` 150 ms** — hover and press feedback. Short enough to read as a
  direct response to the finger rather than an animation.
- **`fast` 180 ms** — a single element changing state or position.
- **`med` 300 ms** — a surface entering or leaving: sheets, page transitions.
- **`stagger(step)` 30 ms × step, capped at 8 steps** — the delay of the
  *step*-th item of an entrance, so the rhythm survives someone inserting a
  row. The stagger should be felt as the screen settling into place, not
  watched item by item; the cap is inside the function, so no caller can turn
  a long list into a queue.

- **`focal` 720 ms** — one authored entrance per surface, long enough to be
  watched rather than merely noticed: the mark's entrance on the boot splash.
  If a second element on the same screen wants this, one of them is not focal.
- **`loop` 1600 ms** — one turn of a looping indeterminate indicator
  (`AgoraLoader`). Unhurried on purpose: a loop the eye can follow reads as the
  app working, one it cannot reads as the app struggling.

- **`message` 4 s, `messageLong` 6 s** — how long a snackbar stays before it
  withdraws itself. `messageLong` is for a failure, which gets read twice: the
  first pass says something went wrong, the second says what.

`instant` · `fast` · `med` are the state scale and it deliberately stops at
`med`. Entrances used to run at 500 ms, which is long enough that the user waits
on them instead of reading them. `focal`, `loop` and the two message steps are not
extensions of that scale — the scale says how long a change takes, `focal` buys
one deliberate performance per surface, `loop` says how often a cycle comes
round, and `message` says how long a sentence waits to be read.
- **`pressScale` .97 / `pressScaleSurface` .99** — how far a control gives
  while held. The scale is a ratio, so a card needs the smaller factor: the
  edge of a 264px card travels ten times further than the edge of a chip at the
  same value. `Pressable` and `InkSurface` apply it, which covers every
  tappable surface in the app; it is also the only press feedback a touch
  device gets, since it has no hover state to fall back on.

**Every duration travels with the curve.** `AnimatedContainer` and every other
implicit animation default to `Curves.linear` — constant speed from a standing
start to a dead stop, the one shape nothing physical moves in. Twenty controls
were animating that way; passing `curve: Motion.curve` next to the duration is
what makes the press and hover states feel soft rather than mechanical.

**Every duration goes through `Motion.of(context, d)`**, which returns
`Duration.zero` when the OS asks for reduced motion. `loop`, `message` and `messageLong` are the
exceptions. An indeterminate indicator is not decorating a change, it *is* the
state, and stopping it says the app has finished when it has not — Material
never routed `CircularProgressIndicator` through the setting either. Zeroing a
message's dwell would take the sentence away before anyone had read it, which
is the same error in a different place. A raw
duration handed to an animated widget ignores the setting — that is a bug, not
a style choice.

The two modal presentations in `showAppModal` are the only places the rule has
to be applied by hand, because each builds its own route: the desktop dialog
takes `transitionDuration`, the mobile sheet takes `sheetAnimationStyle`.
`test/ui/reduce_motion_test.dart` covers both in both states.
`EnterUp` goes further and skips its transform entirely under Reduce Motion:
the entrance is decorative, so the content is simply already there.
The person-picker popover is the third: a `PopupRoute`'s `transitionDuration`
is a getter with no context, so the route reads the setting from the anchor
when it is pushed.

`test/ui/motion_guard_test.dart` enforces all three rules — curve alongside
duration, curves only from `Motion`, timings only from the scale — because
every violation still compiles and still animates, just not like the rest of
the app.

Five shared motion widgets:

| Widget | Motion | Where |
|---|---|---|
| `FadeThroughSwitcher` | MD3 fade-through, transparent fill | top-level section changes |
| `SlideSwitcher` | push/pop, ±0.22 offset + fade | steps inside a flow (auth) |
| `EnterUp` | fade + 14px rise, staggered by `delay` | welcome screen, and the first cards of every list view: dashboard, participants, settings |
| `MotionSize` | `AnimatedSize` that honours Reduce Motion without asserting | anything whose height changes |
| `AnimatedInk` | tweens a color for text and icons alongside their container | controls whose label and background must answer at the same speed |

`MotionSize` exists because `AnimatedSize(duration: Motion.of(context, …))` is
a crash, not a spelling: `RenderAnimatedSize` restarts its controller from
inside `performLayout`, and a zero-length `forward()` notifies synchronously, so
the render object dirties itself mid-layout. `AnimatedInk` tweens the color
alone rather than reaching for `AnimatedDefaultTextStyle`, which *replaces* the
ambient style and silently drops the app's font family.

## 8. Layout and responsiveness

Two independent axes, deliberately separated.

**Window breakpoints** — what the *screen* looks like. Read through
`context.screenSize` / `context.isMobile`, never `MediaQuery` width directly
(that is how a stray `>= 1100` once disagreed with the tablet breakpoint by 20px).

| Size | Width | Shell |
|---|---|---|
| `mobile` | ≤ 720 | bottom navigation, tabbed Assign/Preview, bottom sheets |
| `tablet` | ≤ 1080 | icon-only sidebar (64px) |
| `desktop` | > 1080 | full sidebar (232px), editor and preview side by side, popovers |

**Container queries** — what a *component* can afford in its own box. A card can
be narrow on a wide screen, so these are separate constants (`ContainerWidth`):
settings split into two columns at 760 · settings fields pair at 300 ·
assignment slots fit two per row at 340 · the continue card goes to one line at 560.

Shell anatomy: `Sidebar` / bottom nav (Inicio · Participantes · Configuración,
badge on Inicio) → `ProjectBar` (identity, progress ring, week selector with the
Aux room / Two-per-sheet / Circuit overseer toggles, export) → `WorkspacePanel`
(chairman card, then the four sections) + `PdfPreviewView`.

## 9. Component inventory

`lib/ui/widgets/` is the catalog. Building a one-off where one of these fits is
drift. One line each below; `docs/COMPONENTS.md` carries the per-widget
variants, states and accessibility contract.

| Widget | Mock selector | Role |
|---|---|---|
| `AppButton` | `.btn--primary` / `.btn--ghost` | two variants; square when `label` is null |
| `DangerButton` | — | destructive action in `colorScheme.error`; there is no danger variant on `AppButton` |
| `Pressable` | — | hover/press detection for the catalog (§10) |
| `InkSurface` | — | MD3 interactive card: real ripple, state layers, animated elevation and border |
| `ModalShell` | — | handle, header, scrollable body, button footer; `showAppModal` picks dialog vs bottom sheet |
| `Pill` | — | uppercase badge; base for status, privilege and "Incompleto" |
| `MiniChip` | `.time-badge`, `.dur-chip`, `.aux-flag`… | six presets: time, all-meeting, duration, tag, aux, week |
| `FilterPill` | `.chip` | toggling filter, optional color dot and counter |
| `SegmentedTabs` | `.seg` | Assign/Preview on mobile; static chip when `onChanged` is null |
| `ProgressRing` | `.ring` | accent arc over a `border` base, count in the middle |
| `ProgressMeter` | `.meter` | linear bar, `border2` track, accent fill, fully rounded |
| `SectionHeader` | `.section__head` | color dot, uppercase title, assigned/total |
| `BlockTitle` | `.block-title` | dashboard block title, counter, optional "Ver todo" |
| `LabeledField` | `.field` | small uppercase label above any control |
| `BoundTextField` | — | field seeded once from state; the provider stays the source of truth |
| `Avatar` | — | initials from the display name |
| `DashedBorder` | — | Flutter has none; used by the empty avatar and "Asignar…" |
| `EmptyState` | — | icon, optional title, message, optional action and error |
| `AppSpinner` | — | 16px default, accent; the only indeterminate spinner inside a control |
| `AppSwitch` | — | `Switch` painted below platform size while keeping a 48×48 tap area (§5) |
| `AppSnackBar` | — | `showAppSnack` — the app's only snackbar, success or failure, never neutral |
| `ExportPanel` | — | format selector + Save/Share, shared by desktop menu and mobile sheet |
| `ExportButton` | — | mobile export entry point; opens the sheet, busy state shared across instances |
| `AgoraMark` / `AgoraLockup` | — | the brand mark, and the mark beside the wordmark (§3.5) |
| `AgoraMarkEntrance` | — | the boot splash: a streak of light draws the cut, then each plane grows to meet it (`focal`, §7) |
| `AgoraLoader` | — | the mark turning, for the one wait long enough to deserve a logo: the PDF preview (`loop`, §7) |
| `NotebookDropTarget` | — | drag-and-drop for a workbook file; the web build has a real one, every other platform gets a stub that offers nothing |
| `NotebookImportDialog` | — | fetch the workbook from jw.org, then hand it back — the web fallback for a file the browser cannot read across origins |

`runExport` in `export_actions.dart` is not a widget but belongs to the same
catalog rule: both export surfaces call it, so the build → save/share → snackbar
sequence cannot diverge between desktop and mobile.

## 10. Interaction and state

The Material ripple is **disabled globally** (`NoSplash.splashFactory`,
transparent `highlightColor`). Feedback is explicit, which has one consequence
worth stating loudly:

> `Pressable` reports `hovered = hovered || pressed`. Touch devices have no
> hover, so a control styled only on `hovered` — most ghost buttons, icon
> buttons and nav items — sat in its resting state with no reaction to a finger
> at all, with nothing else covering the gap.

`Pressable` also sets `HitTestBehavior.opaque`: with the default
`deferToChild` only *painted* pixels react, so controls without a background had
dead zones everywhere except the glyphs. And it wraps in `Semantics(button:
true)` with an explicit `semanticLabel` — required in practice for icon-only
controls, which otherwise expose a tap action with no role and no name.
`AppIconButton` forwards `tooltip` into `semanticLabel`, so an icon button with
a tooltip is named for free; one without a tooltip must pass the label itself.

Because the ripple is off, **keyboard access lives entirely in `Pressable`**. It
is built on `FocusableActionDetector`, which carries the hover tracking, takes
focus in the traversal, and binds `ActivateIntent` so Space and Enter fire
`onTap` (flashing the pressed state, or the control would activate invisibly).
The focus ring paints through a *foreground* `DecoratedBox` so it never joins
layout — a focus state that resized the control would shift its neighbours —
and `onShowFocusHighlight` only fires for keyboard focus, so a mouse click
leaves no ring behind. `focusRadius` lets a caller match the ring to its shape.

`InkSurface` is the exception that keeps a real ripple, for cards. The sidebar
`_NavItem` is built on `Material` + `InkWell` and so has always had its own
focus and ink; the bottom bar is Material's `NavigationBar`.

Selection in navigation is carried by **three simultaneous signals**, never
color alone: an animated indicator surface, an outline→filled icon crossfade
with a scale pop, and a weight change.

## 11. The printed artifact

The PDF is not "export styling" — it is the deliverable, so its metrics are part
of the design system. `lib/pdf/pdf_theme.dart`.

Page: US Letter 612×792 pt. Standard margins 0.7in top / 0.5in bottom / 0.8in
sides → content width **496.8 pt**. Columns are taken exactly from the original
LaTeX template: hour 1.3 cm, role 2.6 cm, names 5.0 cm floor, 6 pt gaps,
10 pt row separation.

`S140Metrics` parameterises all of it with two presets:

| | `standard` | `compact` (two per sheet) |
|---|---|---|
| Content width | 496.8 | 554.4 (margins drop to 0.4/0.3 in) |
| Base type | 10 | **10.5** |
| Times | 9 | 10 |
| Role labels | 8 | 8.5 |
| Row separation | 10 | 4.5 |
| Band padding | 3 | 2.5 |

Note the direction: in the two-per-sheet layout the type gets **larger**, not
smaller. The compression comes from row air and page margins, so the content
*reflows* into the space instead of being photo-reduced. A page-level
`FittedBox(scaleDown)` is only a safety net for an unusually heavy week.

Names columns are **measured and adaptive**: the longest name sets the width,
with a 6 pt pad, floored so the title column never drops below 40% of the
content width (34% in Aux Room mode, which needs four columns) and each aux
column keeps at least 60 pt. This is what makes the promise "never overflows
regardless of content volume" true rather than hopeful.

## 12. Accessibility commitments

Binding, from `PRODUCT.md`:

- Respect OS font scaling rather than hard-coding sizes.
- Touch targets at or above platform minimums (44 pt iOS / 48 dp Android) with
  real spacing between adjacent targets.
- Text contrast at WCAG AA or better in **both** themes.
- Never rely on color alone to carry meaning (§10).
- Honor reduced motion (§7).

The standard behind them is **WCAG 2.2 Level AA** — adopted, scoped and walked
criterion by criterion in `docs/ACCESSIBILITY.md`, which also lists the seven
that fail today. Four of the commitments above are enforced by tests rather
than asserted:

| Commitment | Enforced by |
|---|---|
| AA contrast in both themes | `test/ui/contrast_test.dart` — all 21 rendered pairs, per theme |
| Reduced motion | `test/ui/reduce_motion_test.dart` — the catalog surfaces and both modal routes |
| Text scaling without breakage | `test/ui/text_scaling_test.dart` — 2× on a 320px phone |
| Keyboard operability | `test/ui/keyboard_focus_test.dart` — traversal, Space/Enter, ring, no resize |
| Type, icon and shadow scales | `test/ui/scale_guard_test.dart` — no bare size or one-off `BoxShadow` in `lib/ui/` |
| This document's own values | `test/ui/design_doc_test.dart` — every colour, scale step, duration, curve and breakpoint |
| The catalogue's appearance | `test/ui/golden/` — eighteen golden images, both themes |

Touch-target minimums and screen-reader traversal order remain unverified;
traversal order is the largest single unknown in the audit, because four
criteria depend on it and none can be settled by reading code.

## 13. Known gaps

Stated rather than papered over:

1. **The mock is gone.** Dozens of doc-comments cite CSS selectors from a source
   that is not in the repo. New contributors cannot resolve those references.
   Either vendor the mock into `docs/` or strip the citations.
2. **One palette.** `AppPalette` is built for several; `pizarra` is the only one,
   so the abstraction is currently unexercised.
3. **Default theme is `light`, not `system`.** A deliberate-looking choice with
   no recorded rationale; the Settings option offers all three.
4. **The gallery is debug-only, and the screens are not in it.**
   `lib/ui/dev/gallery.dart` composes the catalogue once; `GalleryScreen`
   renders it at `/gallery` behind `kDebugMode`, and `test/ui/golden/` renders
   the same composition into eighteen images. What is still uncovered is
   everything above component level: the dashboard, the participants list, the
   settings tabs and the auth flow have no image and no gallery entry, so a
   layout regression on a *screen* is still caught only by looking.
5. **Touch targets: half closed.** `Dimens.hTouchMin` (48) now exists and
   `AppButton` and `AppSwitch` pad out to it, so a square control or a toggle
   below the floor gets a real hit area without growing visually. What is still
   unverified is coverage: `hControl` is 38, nothing enumerates which controls
   go through the expanding path, and no test asserts a minimum hit rect. The
   remaining question is whether any *non-square* control on a touch screen is
   still short — a visible density decision on mobile, not a mechanical change.
6. **Screen and print section colors differ** (§3.4) with the rationale recorded
   here for the first time. If that was accidental rather than intentional, this
   is the place to fix it.
7. **`Space` is still on the honour system.** `AppText`, `AppIcon` and
   `Elevation` are now defended by `scale_guard_test`, which closed 40 call
   sites that had drifted off them. `Space` is not: padding and gaps are
   written as `EdgeInsets` and `SizedBox` numbers that no single parameter name
   identifies, so the same grep would either miss most of them or drown in
   false positives. It needs a different shape of check — probably an
   `EdgeInsets`/`SizedBox` argument walk — before the ninth scale is as safe as
   the other three.
   Two smaller residues of the same pass: `hIconCard` 30 and `hIconModal` 32
   are 2px apart and one of them is probably redundant, and `spinnerInButton`
   15 sits 1px under `spinner` 16. Collapsing either is a visible decision, so
   both were named at their current values rather than merged.
10. **`Pill` renders below the floor.** Its `fontSize` defaults to 10 and no
   caller overrides it, so every badge in the app is half a point under
   `micro`. Raising it to 10.5 overflows the privilege row on the participant
   card by 5px at 2× text — `participant_card_test` catches it — so the thing
   that has to give is that card's layout, not the token. Until that row wraps
   or sheds a badge, the floor has an exception, `scale_guard_test` carries it
   by name, and this entry is why.
8. **The document's prose is still unchecked.** `design_doc_test` now holds
   every *value* here to the source, which is what went wrong between
   2026-08-16 and 2026-08-29 — the palette moved twice and every accent and
   dark-ground cell was left describing the one from before the app had a
   logo. What it cannot check is everything that is not a number: the §9
   catalogue can fall behind a new widget, §10 can describe an interaction
   that has since changed, and §11's PDF metrics are quoted rather than read.
   Those still rely on somebody looking.
9. **The system is documented; the product is not conformant yet.** The
   behavioural half is now in `docs/UX_PATTERNS.md` and the standard in
   `docs/ACCESSIBILITY.md`. Both carry their own gap lists, and the
   accessibility one has seven live failures — the largest being that no
   status message is announced to a screen reader at all.
