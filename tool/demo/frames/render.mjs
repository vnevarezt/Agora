// Turns the raw captures in build/demo/shots/ into framed mockups, using CSS
// device frames rendered by headless Chrome. No paid service, no per-device
// image assets, no dependencies beyond a Chrome that is already installed.
//
//   node tool/demo/frames/render.mjs            # store frames + heroes
//   node tool/demo/frames/render.mjs hero       # only the hero compositions
//   node tool/demo/frames/render.mjs store es   # only Spanish store frames

import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..', '..', '..');
const shotsDir = join(repo, 'build', 'demo', 'shots');
const outDir = join(repo, 'build', 'demo', 'mockups');
const tmpDir = join(repo, 'build', 'demo', '.frame-tmp');
const css = readFileSync(join(here, 'frame.css'), 'utf8');

const CHROME =
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

// Frame geometry per capture target, in units of the capture's own pixels.
// `bezel` and `radius` are what separate an iPhone from a 10" tablet far more
// than the outline does, so they are the only knobs worth exposing.
// Frame geometry per capture target, in the capture's own pixels. `bezel` is
// the black glass border, `rail` the metal edge outside it, `radius` the
// screen's corner.
//
// One hard rule: `radius` must stay comfortably LARGER than `bezel`. Every
// real device has a screen corner wider than the glass around it, so inverting
// the two produces a thick black band that refuses to follow the content's
// curve — which reads instantly as a broken frame, in light and dark alike.
const DEVICES = {
  'phone': {
    bezel: 13, rail: 8, radius: 104, btnR: 4,
    metal: 'graphite', island: false, buttons: 'android',
  },
  'iphone17-pro-max': {
    // 6.9" (1320x2868, the resolution App Store Connect takes for
    // that class): ~1.15mm bezel, at 3x.
    bezel: 16, rail: 10, radius: 150, btnR: 5,
    metal: 'titanium', island: true, buttons: 'iphone',
  },
  'ipad11-portrait': {
    // iPad Pro 11" (M4): ~5mm bezel, ~22pt screen radius, at 2x.
    bezel: 30, rail: 11, radius: 62, btnR: 4,
    metal: 'aluminium', island: false, buttons: 'none',
  },
  'ipad11-landscape': {
    bezel: 30, rail: 11, radius: 62, btnR: 4,
    metal: 'aluminium', island: false, buttons: 'none',
  },
  'tablet10-portrait': {
    bezel: 26, rail: 10, radius: 52, btnR: 4,
    metal: 'graphite', island: false, buttons: 'none',
  },
  'tablet10-landscape': {
    bezel: 26, rail: 10, radius: 52, btnR: 4,
    metal: 'graphite', island: false, buttons: 'none',
  },
  'web-hero': {
    bezel: 22, rail: 9, radius: 42, btnR: 4,
    metal: 'graphite', island: false, buttons: 'none',
  },
};

// Brushed metal is a gradient with several reversals, not two stops: the eye
// reads the repeated light/dark banding as a curved surface.
const METALS = {
  titanium:
    'linear-gradient(148deg,#e6e1d9 0%,#9d968c 14%,#cfc9bf 30%,#847d73 52%,' +
    '#ded8ce 68%,#8d867c 86%,#d5cfc5 100%)',
  aluminium:
    'linear-gradient(148deg,#dfe2e7 0%,#8f949c 14%,#c6cad1 30%,#767b83 52%,' +
    '#d7dae0 68%,#82878f 86%,#cbcfd6 100%)',
  graphite:
    'linear-gradient(148deg,#5a5f69 0%,#2a2d35 16%,#484d57 34%,#22252c 54%,' +
    '#4e535d 70%,#25282f 88%,#454a54 100%)',
};

/** Side buttons, in fractions of the device's own height. */
const BUTTONS = {
  none: [],
  android: [
    { side: 'right', top: 0.14, len: 0.055 },  // power
    { side: 'right', top: 0.21, len: 0.095 },  // volume rocker
  ],
  iphone: [
    { side: 'left', top: 0.135, len: 0.035 },  // action button
    { side: 'left', top: 0.195, len: 0.075 },  // volume up
    { side: 'left', top: 0.285, len: 0.075 },  // volume down
    { side: 'right', top: 0.225, len: 0.115 }, // power
    { side: 'right', top: 0.375, len: 0.045 }, // camera control
  ],
};

// Background and shadow follow the capture's own theme: a dark screenshot on
// a pale gradient reads as a mistake.
const THEMES = {
  light: {
    bg: 'radial-gradient(120% 100% at 50% 0%, #f4f6fc 0%, #e3e8f6 52%, #cdd5ee 100%)',
    // Low, because the three layers in frame.css each take a share of it and
    // a shadow on a pale ground is read at a glance: past ~0.2 the device
    // stops looking lifted and starts looking smudged.
    shadowA: 0.20,
  },
  dark: {
    bg: 'radial-gradient(120% 100% at 50% 0%, #1b1f2b 0%, #151824 52%, #0d0f18 100%)',
    shadowA: 0.62,
  },
};

/** `tablet10-landscape_editor_es_dark.png` → its parts. */
function parse(file) {
  const m = /^(.+)_(editor|editorPreview|dashboard|participants)_(es|en)_(light|dark)\.png$/
    .exec(file);
  if (!m) return null;
  return { file, target: m[1], screen: m[2], locale: m[3], theme: m[4] };
}

function pngSize(buf) {
  return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
}

function dataUri(path) {
  return `data:image/png;base64,${readFileSync(path).toString('base64')}`;
}

/** One device: rail, glass, screen, and the details that sell the silhouette. */
function device(shot, { screenW }) {
  const d = DEVICES[shot.target];
  const w = screenW;
  const h = w * (shot.size.h / shot.size.w);
  const k = w / shot.size.w; // capture px → laid-out px
  const rail = d.rail * k;
  const bezel = d.bezel * k;
  const outerH = h + 2 * (rail + bezel);

  const buttons = BUTTONS[d.buttons]
    .map((b) => `<div class="btn ${b.side}" style="
        top:${outerH * b.top}px;
        width:${Math.max(2, rail * 0.62)}px;
        height:${outerH * b.len}px"></div>`)
    .join('');

  return `
    <div class="device" style="
      --r-outer:${(d.radius + d.bezel + d.rail) * k}px;
      --rail-w:${rail}px;
      --bezel-w:${bezel}px;
      --screen-w:${w}px;
      --rail:${METALS[d.metal]};
      --btn-r:${d.btnR * k}px;
      --edge-w:${Math.max(1, 1.5 * k)}px;
      --shadow:${Math.round(w * 0.16)}px;
    ">
      ${buttons}
      <div class="glass">
        <div class="screen" style="width:${w}px;height:${h}px">
          <img src="${shot.uri}" alt="">
          ${d.island ? '<div class="island"></div>' : ''}
        </div>
        <div class="glare"></div>
      </div>
    </div>`;
}

function page({ w, h, theme, body, transparent = false }) {
  const t = THEMES[theme];
  return `<!doctype html><meta charset="utf-8"><style>
:root {
  --canvas-w:${w}px; --canvas-h:${h}px;
  --bg:${transparent ? 'transparent' : t.bg}; --shadow-a:${t.shadowA};
}
${css}
</style><body>${body}</body>`;
}

function shoot(html, out, w, h, { transparent = false } = {}) {
  mkdirSync(tmpDir, { recursive: true });
  mkdirSync(dirname(out), { recursive: true });
  const htmlPath = join(tmpDir, 'frame.html');
  writeFileSync(htmlPath, html);
  execFileSync(CHROME, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--force-device-scale-factor=1',
    ...(transparent ? ['--default-background-color=00000000'] : []),
    `--window-size=${w},${h}`,
    `--screenshot=${out}`,
    `file://${htmlPath}`,
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
}

/** Store listing: the device centred on a soft gradient, at the exact pixel
 *  size the store demands — the frame eats into the margin, never the canvas. */
function renderStore(shot) {
  const { w, h } = shot.size;
  const portrait = h >= w;
  // The frame grows outward from the screen, so the scale has to leave room
  // for rail + bezel + shadow inside a canvas the store fixes for us.
  const screenW = Math.round(w * (portrait ? 0.74 : 0.79));
  const body = `<div class="stage">${device(shot, { screenW })}</div>`;
  const out = join(outDir, 'store', shot.target, shot.leaf);
  shoot(page({ w, h, theme: shot.theme, body }), out, w, h);
  return out;
}

/** Frame only, on transparency, at the capture's native resolution — the
 *  asset to drop onto someone else's background (landing, README, slides). */
function renderTransparent(shot) {
  const d = DEVICES[shot.target];
  const screenW = shot.size.w;
  const outerW = screenW + 2 * (d.rail + d.bezel);
  const outerH = shot.size.h + 2 * (d.rail + d.bezel);
  // Just enough for the drop shadow to finish. Wider and the cut-out arrives
  // with a dead band around it that has to be trimmed by hand.
  const margin = Math.round(screenW * 0.16 * 0.45);
  const w = outerW + 2 * margin;
  const h = outerH + 2 * margin;

  const body = `<div class="stage">${device(shot, { screenW })}</div>`;
  const out = join(outDir, 'transparent', shot.target, shot.leaf);
  shoot(page({ w, h, theme: shot.theme, body, transparent: true }), out, w, h,
      { transparent: true });
  return out;
}

/** Stacks several framed devices on one canvas.
 *
 *  Each layer places a device by a fraction of the canvas, so a layout holds
 *  at any output size. Devices are separate elements, so the one in front
 *  drops its shadow over the one behind — which is what sells the depth. */
function renderMontage({ name, layers, w, h, theme, transparent }) {
  const body = `<div class="stage">${layers
    .map((l, i) => `
      <div class="slot" style="
        z-index:${i};
        transform:translate(${l.x * w}px, ${l.y * h}px) ${l.tilt ?? ''}">
        ${device(l.shot, { screenW: w * l.scale })}
      </div>`)
    .join('')}</div>`;

  const dir = transparent ? 'montage-transparent' : 'montage';
  const out = join(outDir, dir, name);
  shoot(page({ w, h, theme, body, transparent }), out, w, h, { transparent });
  return out;
}

// Named arrangements. `x`/`y` are fractions of the canvas from its centre,
// `scale` a fraction of its width. Layers are drawn in order, so the last one
// listed sits on top and drops its shadow over the rest.
const LAYOUTS = {
  // --- iPad pairs -------------------------------------------------------
  // Two slabs offset on the diagonal, straight on. The quiet one: nothing
  // competes with the screens.
  stack: (back, front) => [
    { shot: back, x: -0.105, y: -0.085, scale: 0.60 },
    { shot: front, x: 0.115, y: 0.095, scale: 0.60 },
  ],
  // Same pair, turned away from each other. More product-page, less neutral.
  turned: (back, front) => [
    { shot: back, x: -0.13, y: -0.05, scale: 0.58,
      tilt: 'rotateY(16deg) rotateX(5deg) rotateZ(-2deg)' },
    { shot: front, x: 0.14, y: 0.07, scale: 0.58,
      tilt: 'rotateY(-16deg) rotateX(5deg) rotateZ(2deg)' },
  ],
  // A tablet with a phone leaning in front of it.
  companion: (tablet, phone) => [
    { shot: tablet, x: -0.06, y: 0, scale: 0.62,
      tilt: 'rotateY(14deg) rotateX(5deg) rotateZ(-2deg)' },
    { shot: phone, x: 0.30, y: 0.09, scale: 0.16,
      tilt: 'rotateY(-12deg) rotateX(4deg) rotateZ(3deg)' },
  ],

  // --- iPhone only ------------------------------------------------------
  // Phones are narrow, so they can run bigger and still leave air: these
  // scales put three of them across a canvas two iPads would fill with one.
  duo: (back, front) => [
    { shot: back, x: -0.10, y: -0.035, scale: 0.20,
      tilt: 'rotateY(13deg) rotateX(4deg)' },
    { shot: front, x: 0.10, y: 0.045, scale: 0.20,
      tilt: 'rotateY(-9deg) rotateX(3deg)' },
  ],
  // The app-store standard: a hero upright in front, two turned in behind.
  // Centre goes last so it wins the stacking order.
  trio: (left, right, centre) => [
    { shot: left, x: -0.205, y: 0.035, scale: 0.185,
      tilt: 'rotateY(17deg) rotateX(4deg) rotateZ(-2deg)' },
    { shot: right, x: 0.205, y: 0.035, scale: 0.185,
      tilt: 'rotateY(-17deg) rotateX(4deg) rotateZ(2deg)' },
    { shot: centre, x: 0, y: -0.02, scale: 0.215 },
  ],
  // Three straight phones walking down the diagonal — reads as a sequence,
  // which suits showing one flow across three screens.
  cascade: (a, b, c) => [
    { shot: a, x: -0.225, y: -0.075, scale: 0.19, tilt: 'rotateZ(-4deg)' },
    { shot: b, x: 0, y: 0, scale: 0.19 },
    { shot: c, x: 0.225, y: 0.075, scale: 0.19, tilt: 'rotateZ(4deg)' },
  ],
};

function load(file) {
  const path = join(shotsDir, file);
  const meta = parse(file);
  if (!meta || !DEVICES[meta.target]) return null;
  const leaf = `${meta.screen}_${meta.locale}_${meta.theme}.png`;
  return { ...meta, leaf, size: pngSize(readFileSync(path)), uri: dataUri(path) };
}

function main() {
  const [what = 'all', onlyLocale] = process.argv.slice(2);
  let files;
  try {
    files = readdirSync(shotsDir).filter((f) => f.endsWith('.png'));
  } catch {
    console.error(`No captures in ${shotsDir} — run tool/demo/shots.sh first.`);
    process.exit(1);
  }
  if (files.length === 0) {
    console.error(`No captures in ${shotsDir} — run tool/demo/shots.sh first.`);
    process.exit(1);
  }

  // Only a full, unfiltered run may clear the output: a filtered one exists
  // precisely to refresh part of it, and wiping the rest would throw away
  // work the caller just asked to keep. Everything else overwrites per file.
  if (what === 'all' && !onlyLocale) {
    rmSync(outDir, { recursive: true, force: true });
  }

  const shots = files.map(load).filter(Boolean)
    .filter((s) => !onlyLocale || s.locale === onlyLocale);
  let n = 0;

  if (what === 'all' || what === 'store') {
    for (const shot of shots) {
      if (shot.target === 'web-hero') continue; // not a store size
      console.log(`FRAMED ${renderStore(shot)}`);
      n++;
    }
  }

  if (what === 'all' || what === 'transparent') {
    for (const shot of shots) {
      console.log(`FRAMED ${renderTransparent(shot)}`);
      n++;
    }
  }

  if (what === 'all' || what === 'montage') {
    const pick = (targets, screen, locale, theme) => {
      for (const t of targets) {
        const hit = shots.find((s) => s.target === t && s.screen === screen &&
          s.locale === locale && s.theme === theme);
        if (hit) return hit;
      }
      return null;
    };
    // Apple hardware only, deliberately: a montage mixing an Android slab
    // with an iPad reads as stock art. No fallbacks — if these captures are
    // missing the montage is skipped rather than silently substituted.
    const tablets = ['ipad11-landscape'];
    const phones = ['iphone17-pro-max'];

    for (const locale of ['es', 'en']) {
      if (onlyLocale && locale !== onlyLocale) continue;
      for (const theme of ['light', 'dark']) {
        const ipad = (screen) => pick(tablets, screen, locale, theme);
        const iphone = (screen) => pick(phones, screen, locale, theme);

        const built = [];
        const add = (name, layout, ...shots) => {
          if (shots.every(Boolean)) built.push([name, layout(...shots)]);
        };

        add('stack', LAYOUTS.stack, ipad('dashboard'), ipad('editor'));
        add('turned', LAYOUTS.turned, ipad('dashboard'), ipad('editor'));
        add('companion', LAYOUTS.companion, ipad('editor'),
            iphone('editor'));

        // iPhone-only sets. Different screens per slot on purpose: three
        // copies of one screen shows the device, not the app.
        add('phones-duo', LAYOUTS.duo, iphone('dashboard'), iphone('editor'));
        add('phones-trio', LAYOUTS.trio, iphone('dashboard'),
            iphone('participants'), iphone('editor'));
        add('phones-cascade', LAYOUTS.cascade, iphone('dashboard'),
            iphone('editor'), iphone('editorPreview'));

        for (const [layout, layers] of built) {
          const name = `${layout}_${locale}_${theme}.png`;
          for (const transparent of [false, true]) {
            // 4000 wide, not the 2880 a web hero is captured at: at this
            // size the iPad in `companion` lays its 2420px capture out at
            // ~2480px, so the screenshot inside the frame is drawn about 1:1
            // instead of being resampled down before anything else touches
            // it. Everything here is a fraction of the canvas, so the
            // compositions are unchanged — only the detail is.
            console.log(`FRAMED ${renderMontage({
              name, layers, w: 4000, h: 2500, theme, transparent })}`);
            n++;
          }
        }
      }
    }
  }

  rmSync(tmpDir, { recursive: true, force: true });
  console.log(`\n${n} mockups in ${outDir}`);
}

main();
