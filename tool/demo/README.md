# Demo data, captures and mockups

Public material — Play Store, App Store, the landing page, the README — must
never show a real congregation. Everything here builds an invented one and
renders the real app on top of it, so a screenshot is an honest picture of the
product without publishing anybody's name.

The dataset lives in [`demo_dataset.dart`](demo_dataset.dart): one invented
congregation, 19 invented people and five projects covering every state the
dashboard can show, in Spanish and in English. No demo code ships in `lib/`.

## 1. Capture

```bash
tool/demo/shots.sh                 # every size, both languages
tool/demo/shots.sh phone           # one size
tool/demo/shots.sh phone,web-hero es
tool/demo/shots.sh --fetch         # collect what is already rendered
```

The harness boots the real widgets against an in-memory database seeded with
the demo data, so progress rings, timings and the PDF preview are all really
computed — nothing is mocked but the session and the workbook download.

PNGs land in `build/demo/shots/`, named
`<target>_<screen>_<language>_<theme>.png`:

| target | pixels | layout |
| --- | --- | --- |
| `phone` | 1080×2160 | mobile, one column with tabs |
| `iphone17-pro-max` | 1320×2868 | mobile |
| `ipad11-portrait` | 1668×2420 | tablet |
| `ipad11-landscape` | 2420×1668 | desktop, both panels side by side |
| `tablet10-portrait` | 1600×2560 | tablet |
| `tablet10-landscape` | 2560×1600 | desktop, both panels side by side |
| `web-hero` | 2880×1800 | desktop, for the landing |

Screens are `editor`, `editorPreview` (the mobile preview tab), `dashboard`
and `participants`; each is shot light and dark. To add a size or a screen,
edit `_targets` in
[`../../integration_test/screenshots_test.dart`](../../integration_test/screenshots_test.dart).

The app is sandboxed, so it writes into its own container and the script
copies the results out. If that copy fails, grant your terminal Full Disk
Access — the script prints the container path either way.

## 2. Frame

```bash
tool/demo/frames.sh                # store frames + landing heroes
tool/demo/frames.sh hero           # only the heroes
tool/demo/frames.sh store es       # only the Spanish store frames
```

Device frames are drawn in CSS ([`frames/frame.css`](frames/frame.css)) and
composited by headless Chrome, so there are no per-device image assets to
license and no paid mockup service in the loop. Output in
`build/demo/mockups/`, one folder per device:

```
store/<target>/<screen>_<language>_<theme>.png        opaque, exact store size
transparent/<target>/<screen>_<language>_<theme>.png  frame only, alpha background
hero/hero_<language>_<theme>.png                      tablet + phone in perspective
```

* `store/` keeps **exactly** the pixel size the capture had, because App Store
  Connect and Play reject anything else; the frame eats into the margin.
* `transparent/` renders at the capture's native resolution with room for the
  shadow — the asset to drop onto someone else's background.
Montages combine framed devices on one canvas, in `montage/` (on a gradient)
and `montage-transparent/` (alpha). Apple hardware only, and with no
fallbacks: a layout whose captures are missing is skipped rather than quietly
substituted with another device.

| layout | devices | screens |
| --- | --- | --- |
| `stack` | 2 × iPad landscape, straight, diagonal offset | dashboard + editor |
| `turned` | 2 × iPad landscape, in perspective | dashboard + editor |
| `companion` | iPad landscape + iPhone in front | editor + editor |
| `phones-duo` | 2 × iPhone, turned toward each other | dashboard + editor |
| `phones-trio` | 3 × iPhone, hero upright between two turned | dashboard, participants, editor |
| `phones-cascade` | 3 × iPhone, straight, down the diagonal | dashboard, editor, preview |

Each slot takes a different screen on purpose: three copies of one screen
shows off the device, not the app.

Two knobs worth knowing, both in [`frames/render.mjs`](frames/render.mjs):
`DEVICES[target].radius` is the screen's corner, deliberately smaller than the
real hardware because captures have square corners and a true 55pt corner
slices visible UI; and `renderHero`, where the angles are a few CSS
transforms.

## 3. Publish to the landing

```bash
tool/demo/site_shots.py
```

Takes three montages — `phones-duo`, `turned`, `companion` — trims the
transparent margin off each one and writes them to `site/media/` as WebP at the
widths the hero actually draws them: one file per language, theme and density.
The landing picks exactly one by viewport, theme and DPR, so a reader downloads
30-100 KB of it, never the megabyte PNG.

That output is committed, unlike everything else here: rendering the site must
not depend on a capture run that needs a simulator and Chrome.

## 4. Demo backup

For captures that need the app running normally — a video, a walkthrough —
restore the demo congregation into a throwaway profile instead:

```bash
flutter test tool/demo/generate_demo_backup.dart
```

That writes `build/demo/demo-es.agora` and `build/demo/demo-en.agora`
(password `agorademo`) and checks that both restore onto a clean device.
Import from Settings → Data → Import backup, and wipe the profile afterwards.

## Brand entrance

Not a capture — a window to watch the splash mark assemble itself in, since a
strip of stills cannot tell you whether a beat lands or drags:

```bash
flutter run -t tool/demo/mark_preview.dart -d macos
```

Light and dark run side by side on one clock: the entrance at 180px and at
the 64px the splash actually uses, looping with a pause between takes, and
below it `AgoraLoader` at four sizes plus the mono ink on a filled ground.
The loader is never remounted, so the seam between its turns is on show
rather than hidden by a restart. The speed buttons
set `timeDilation`, which stretches the real controller rather than retiming
it, so what you see at 8x is the same curve — a beat that reads wrong there is
wrong at full speed too.

Both animations live in [`agora_mark.dart`](../../lib/ui/widgets/agora_mark.dart)
and share one drawing, whose geometry is checked against `gen_brand_assets.py`
by `test/ui/agora_mark_test.dart`.

## Before uploading

- Keep the `S-140-S 11/23` footer out of frame. Inside the app it is exactly
  what the user needs to print; on a store listing it makes Agora look like an
  official product, which it is not.
- Store policies (Play "Store Listing and Promotion", App Store 2.3.3) require
  screenshots to show the app as it really behaves. Demo *data* is fine; a
  mocked-up UI the binary cannot produce is not.
