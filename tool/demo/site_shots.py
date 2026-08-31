#!/usr/bin/env python3
"""Publishes the montages the landing draws in its hero.

frames.sh renders every layout onto one 2880x1800 canvas — megabyte PNGs with
whatever transparent margin the composition happened to leave. The landing
shows exactly one of them at a known width, so what it ships is that one
trimmed to its own art and encoded to WebP: tens of KB, on a page whose whole
point is to be cheap to open.

The output is committed, unlike everything else under build/: rendering the
site must not depend on a capture run that needs a simulator and Chrome.

    tool/demo/site_shots.py        # after shots.sh and frames.sh
"""

import pathlib
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
MOCKUPS = ROOT / "build/demo/mockups"
OUT = ROOT / "site/media"

# What the page draws, and the widest CSS pixel width it draws it at. The key
# is the file name it ships under; the path is the mockup it is cut from, minus
# the `_<locale>_<theme>.png` every one of them ends in.
#
# The three heroes are one montage per device class the reader might be on: the
# column is 6/11 of the measure above 721px, and the whole measure below it.
# The program is a single iPad with the preview panel open, which is the only
# capture that holds the app and its output in one frame.
# The last field is the densities it ships at. The program gets a third
# because it is the one piece anybody tries to *read*: a phone fits a whole
# letter page into its width, so the rows land at about five CSS pixels, and
# five sharp pixels are legible where five soft ones are mush.
SLOTS = {
    "hero-phone": ("montage-transparent/phones-duo", 620, (1, 2)),
    "hero-tablet": ("montage-transparent/turned", 560, (1, 2)),
    "hero-desk": ("montage-transparent/companion", 740, (1, 2)),
    "program": ("transparent/iphone17-pro-max/editorPreview", 400, (1, 2, 3)),
}

LOCALES = ("es", "en")
THEMES = ("light", "dark")

# The frame holds real interface text, some of it a few pixels tall once
# resized, and WebP spends its bits on flat areas first. The 1x file is drawn
# at its own size so it carries the whole burden; the 2x one is downsampled by
# the browser before anyone sees it, which hides a good deal.
QUALITY = {1: 90, 2: 80, 3: 74}

# Alpha above this counts as art. 2 rather than 0 keeps the drop shadow, which
# is what makes the devices look like they are floating rather than pasted, and
# still drops the empty half of a canvas that only holds two phones.
INK = 2

# The trim is measured on a proxy this wide, not on 5 million pixels of PNG in
# a Python loop. A pixel of the proxy is ~6 of the original, so the box is
# grown by one before it is used.
PROXY = 480


def read_rgba(path: pathlib.Path) -> tuple[int, int, bytearray]:
    """The pixels of a plain 8-bit RGBA PNG — which is what sips writes."""
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    pos, idat, meta = 8, bytearray(), None
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        if kind == b"IHDR":
            meta = struct.unpack(">IIBBBBB", data[pos + 8:pos + 8 + length])
        elif kind == b"IDAT":
            idat += data[pos + 8:pos + 8 + length]
        pos += 12 + length

    width, height, depth, colour, _, _, interlace = meta
    if (depth, colour, interlace) != (8, 6, 0):
        sys.exit(f"{path}: not 8-bit RGBA")

    raw = zlib.decompress(bytes(idat))
    stride, bpp = width * 4, 4
    out, prev, i = bytearray(), bytearray(stride), 0
    for _ in range(height):
        kind, i = raw[i], i + 1
        line = bytearray(raw[i:i + stride])
        i += stride
        if kind == 1:
            for x in range(bpp, stride):
                line[x] = (line[x] + line[x - bpp]) & 255
        elif kind == 2:
            for x in range(stride):
                line[x] = (line[x] + prev[x]) & 255
        elif kind == 3:
            for x in range(stride):
                left = line[x - bpp] if x >= bpp else 0
                line[x] = (line[x] + ((left + prev[x]) >> 1)) & 255
        elif kind == 4:
            for x in range(stride):
                a = line[x - bpp] if x >= bpp else 0
                b = prev[x]
                c = prev[x - bpp] if x >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                near = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[x] = (line[x] + near) & 255
        out += line
        prev = line
    return width, height, out


def art_box(src: pathlib.Path, tmp: pathlib.Path) -> tuple[float, float, float, float]:
    """Where the art sits in one montage, as fractions of the canvas."""
    proxy = tmp / f"{src.stem}.png"
    subprocess.run(
        ["sips", "-s", "format", "png", "-Z", str(PROXY), str(src),
         "--out", str(proxy)],
        check=True, capture_output=True,
    )
    w, h, px = read_rgba(proxy)
    left, top, right, bottom = w, h, -1, -1
    for y in range(h):
        row = px[y * w * 4:(y + 1) * w * 4][3::4]
        lit = [x for x, alpha in enumerate(row) if alpha > INK]
        if not lit:
            continue
        left, right = min(left, lit[0]), max(right, lit[-1])
        top = min(top, y)
        bottom = y
    if right < 0:
        sys.exit(f"{src}: no art in it")
    # One proxy pixel of slack on each side, so nothing of the shadow is shaved.
    return ((left - 1) / w, (top - 1) / h, (right + 2) / w, (bottom + 2) / h)


def main() -> None:
    if not shutil.which("cwebp"):
        sys.exit("cwebp is missing — brew install webp")

    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    total = 0.0
    with tempfile.TemporaryDirectory() as td:
        tmp = pathlib.Path(td)
        for slot, (stem, width, densities) in SLOTS.items():
            sources = {
                (locale, theme): MOCKUPS / f"{stem}_{locale}_{theme}.png"
                for locale in LOCALES for theme in THEMES
            }
            for src in sources.values():
                if not src.exists():
                    sys.exit(
                        f"missing {src.relative_to(ROOT)}\n"
                        "run tool/demo/shots.sh and tool/demo/frames.sh first"
                    )

            # One box for the whole slot, the union of its four variants: a
            # dark montage carries a heavier shadow than a light one, and two
            # ratios behind one CSS aspect-ratio would letterbox whichever
            # variant lost.
            boxes = [art_box(src, tmp) for src in sources.values()]
            l = min(b[0] for b in boxes)
            t = min(b[1] for b in boxes)
            r = max(b[2] for b in boxes)
            b_ = max(b[3] for b in boxes)

            for (locale, theme), src in sources.items():
                cw, ch = png_size(src)
                x, y = round(max(l, 0) * cw), round(max(t, 0) * ch)
                w = round(min(r, 1) * cw) - x
                h = round(min(b_, 1) * ch) - y
                for density in densities:
                    out_w = width * density
                    out_h = round(h * out_w / w)
                    suffix = "" if density == 1 else f"@{density}x"
                    dst = OUT / f"{slot}-{locale}-{theme}{suffix}.webp"
                    subprocess.run(
                        ["cwebp", "-quiet", "-q", str(QUALITY[density]),
                         "-m", "6", "-alpha_q", "95", "-sharp_yuv",
                         "-crop", str(x), str(y), str(w), str(h),
                         "-resize", str(out_w), str(out_h),
                         str(src), "-o", str(dst)],
                        check=True,
                    )
                    kb = dst.stat().st_size / 1024
                    total += kb
                    print(f"  {dst.name}  {out_w}x{out_h}  {kb:.0f} KB")
            print(f"  ^ trimmed to {100 * (r - l):.0f}% x {100 * (b_ - t):.0f}% "
                  f"of the canvas — aspect-ratio: {width} / "
                  f"{round(h * width / w)};")

    files = sum(len(d) for _, _, d in SLOTS.values()) * len(LOCALES) * len(THEMES)
    print(f"{files} files, {total:.0f} KB in {OUT.relative_to(ROOT)} "
          "(a reader downloads one)")
    print("the ratios above are the .shot rules in site/landing.css")


def png_size(path: pathlib.Path) -> tuple[int, int]:
    """Width and height straight out of the IHDR chunk."""
    head = path.read_bytes()[:24]
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        sys.exit(f"not a PNG: {path}")
    return struct.unpack(">II", head[16:24])


if __name__ == "__main__":
    main()
