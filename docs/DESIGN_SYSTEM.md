# Design System

Reference for Agora's visual and interaction layer. Status: **descriptive, not
aspirational** — everything below is what `lib/ui/` does today, read out of the
code. Where the system has a gap, §13 says so instead of inventing a rule.

The colour, motion, text-scaling and keyboard rules are enforced by tests
(§12), so this document and the code cannot drift apart silently.

Companion documents: `PRODUCT.md` (who this is for and what it must never
claim), `docs/DATA_ARCHITECTURE.md` (the data layer this UI reads).

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
drift.** The exceptions are enumerated: the shadow/scrim constants in
`Elevation`, the S-140 section identity colors in `kSectionColors`, the four
Google brand colors in `auth/widgets/google_button.dart` (official brand assets
must not be re-tinted), and the PDF palette in `lib/pdf/pdf_theme.dart` (which
is print, not screen — §11).

Only one palette ships: **`pizarra`**. `AppPalette` exists so more can be added
(the code names Granate, Salvia and Biblioteca as candidates); none are built.

## 3. Color

### 3.1 Structural roles

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F8FAFD` | `#0B0F14` | app canvas / scaffold |
| `surface` | `#FFFFFF` | `#13181E` | cards, bars, modals |
| `surface2` | `#F4F7FB` | `#191F26` | inputs, insets, table headers |
| `border` | `#DEE2E7` | `#282E36` | decorative hairline: cards, dividers |
| `border2` | `#ECEFF2` | `#21262C` | quieter internal dividers |
| `borderControl` | `#878F9B` | `#626D7D` | outline of an interactive control |
| `text` | `#1F242D` | `#ECEFF2` | primary ink |
| `textDim` | `#5D646F` | `#A6ABB2` | secondary ink, default icon color |
| `textMute` | `#6B7079` | `#868B92` | hints, placeholders, uppercase labels |

`border` and `borderControl` are split on purpose. WCAG 1.4.11 asks 3:1 of
anything that identifies a control, and a decorative divider carries no such
floor — holding both to 3:1 would turn every hairline into a rule and lose the
flat, layered look §1.4 depends on. Inputs and ghost buttons outline with
`borderControl`; cards and dividers keep the hairline.

### 3.2 Accent

| Token | Light | Dark | Use |
|---|---|---|---|
| `accent` | `#41629F` | `#6F97E2` | primary fill, focus ring, switch on |
| `accentStrong` | `#2E5091` | `#5A84D4` | pressed, links, emphasis on tint |
| `accentInk` | `#F8FCFF` | `#060D1A` | ink ON accent |
| `accentSoft` | `#E7F1FF` | `#21344C` | selected/tint background |
| `accentTint` | `#F2F7FF` | `#192431` | the faintest wash |
| `accentOnSoft` | `#2E5091` | `#7FA3E8` | ink ON `accentSoft`/`accentTint` |

A cool slate blue, deliberately unsaturated: it has to sit next to the S-140
band colors (§3.4) without competing with them.

`accentOnSoft` exists because the theme is not symmetric. In light mode it is
`accentStrong`; in dark, `accentStrong` on `accentSoft` lands at 3.42:1, which
had put **both** states of the bottom navigation below AA at once. A separate
ink token fixes every tinted surface — nav, privilege badge, draft badge, add
chip — without restyling the tint itself.

### 3.3 Status, and what is *not* status

Three families, each a soft tint used as a background plus the ink that sits on
it. `*Strong` is the solid version for marks that sit directly on `bg`/`surface`
with no tint behind them (dots, standalone icons).

| Family | Ink (light / dark) | Soft (light / dark) | Strong | Meaning |
|---|---|---|---|---|
| `success` | `#2E6A3E` / `#A9D8B8` | `#DCF0E0` / `#1E3A2A` | `#4FA06A` | complete, up to date |
| `warning` | `#7A6512` / `#D9C27A` | `#F3ECD2` / `#3A3115` | `#B9890F` | pending, attention |
| `alert` | `#A94F2B` / `#E8A38C` | `#FBE7DF` / `#40231C` | — | overdue, nothing assigned |

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

## 4. Typography

Two families, both bundled — no webfont fetch, no silent fallback.

- **Manrope** (400/500/600/700/800) — everything.
- **JetBrains Mono** (500/600) — times, codes, percentages, counts. Always via
  `AppText.mono()`, which sets `FontFeature.tabularFigures()` so digits align.
- **Carlito** (regular/bold/italic/bold-italic) — PDF only, never on screen. It
  is a metric-compatible Calibri clone, which is what makes the generated
  document match the official S-140 (§11).

### 4.1 The scale

Seven steps, in `AppText` (`lib/ui/theme/app_theme.dart`). **A bare font size at
a call site is drift.**

| Step | pt | Role |
|---|---|---|
| `micro` | 10.5 | uppercase labels and badges — the floor, nothing renders smaller |
| `caption` | 11.5 | secondary and helper text |
| `small` | 12.5 | dense supporting text inside cards and rows |
| `body` | 13.5 | default reading size |
| `bodyLarge` | 15 | emphasised body: names, list item titles |
| `title` | 16.5 | section and modal titles |
| `display` | 19 | screen titles and large counts |

Deliberately coarse. It replaced a free-form scale that had grown to **nineteen
distinct values between 9.5 and 19** with no rule for choosing among them, which
is why equivalent elements on different screens did not match.

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

Other: `avatar` 30 · `ring` 34 · `pickerW` 340 · `pickerMaxH` 460.

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

- **Curve:** `Cubic(.2, .8, .3, 1)` — a single ease-out, everywhere.
- **`instant` 150 ms** — hover and press feedback. Short enough to read as a
  direct response to the finger rather than an animation.
- **`fast` 180 ms** — a single element changing state or position.
- **`med` 300 ms** — a surface entering or leaving: sheets, page transitions.
- **`slow` 500 ms** — staggered entrances, where the delay between items carries
  the meaning.

**Every duration goes through `Motion.of(context, d)`**, which returns
`Duration.zero` when the OS asks for reduced motion. A raw duration handed to an
animated widget ignores the setting — that is a bug, not a style choice.

The two modal presentations in `showAppModal` are the only places the rule has
to be applied by hand, because each builds its own route: the desktop dialog
takes `transitionDuration`, the mobile sheet takes `sheetAnimationStyle`.
`test/ui/reduce_motion_test.dart` covers both in both states.
`EnterUp` goes further and skips its transform entirely under Reduce Motion:
the entrance is decorative, so the content is simply already there.

Three shared transitions:

| Widget | Motion | Where |
|---|---|---|
| `FadeThroughSwitcher` | MD3 fade-through, transparent fill | top-level section changes |
| `SlideSwitcher` | push/pop, ±0.22 offset + fade | steps inside a flow (auth) |
| `EnterUp` | fade + 14px rise, staggered by `delay` | first paint of the welcome screen |

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
drift.

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
| `AppSpinner` | — | 16px default, accent |
| `ExportPanel` | — | format selector + Save/Share, shared by desktop menu and mobile sheet |

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

No formal external standard has been adopted as a compliance obligation. Three
of these are now enforced by tests rather than asserted:

| Commitment | Enforced by |
|---|---|
| AA contrast in both themes | `test/ui/contrast_test.dart` — all 21 rendered pairs, per theme |
| Reduced motion | `test/ui/reduce_motion_test.dart` — the catalog surfaces and both modal routes |
| Text scaling without breakage | `test/ui/text_scaling_test.dart` — 2× on a 320px phone |
| Keyboard operability | `test/ui/keyboard_focus_test.dart` — traversal, Space/Enter, ring, no resize |

Touch-target minimums and screen-reader traversal order remain unverified.

## 13. Known gaps

Stated rather than papered over:

1. **The mock is gone.** Dozens of doc-comments cite CSS selectors from a source
   that is not in the repo. New contributors cannot resolve those references.
   Either vendor the mock into `docs/` or strip the citations.
2. **One palette.** `AppPalette` is built for several; `pizarra` is the only one,
   so the abstraction is currently unexercised.
3. **Default theme is `light`, not `system`.** A deliberate-looking choice with
   no recorded rationale; the Settings option offers all three.
4. **No component gallery.** There is no storybook screen and no visual
   regression test, so the catalog's *appearance* is verified only by reading
   it — its behaviour is now covered (§12), its looks are not.
5. **Touch targets are unverified.** `hControl` is 38, below the 44pt/48dp
   platform minimum. On a pointer that is fine and deliberate; on touch it
   needs either a larger control or an expanded hit area, and nothing currently
   distinguishes the two cases. Fixing it is a visible density decision on
   mobile, not a mechanical change.
6. **Screen and print section colors differ** (§3.4) with the rationale recorded
   here for the first time. If that was accidental rather than intentional, this
   is the place to fix it.
7. **Nothing enforces the scales.** `AppText`, `AppIcon` and `Space` are
   conventions a reviewer has to spot. A custom lint, or a test that greps
   `lib/ui` for bare numbers in the constructs each scale owns, would make the
   rule self-defending — the same way `contrast_test` now defends §12.
