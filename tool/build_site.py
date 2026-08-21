#!/usr/bin/env python3
"""Renders site/template.html into build/site/ for every shipped locale.

The copy lives in site/copy/*.json, beside the page it belongs to. It started
out inside the app's own lib/i18n so the two could not drift, which stopped
being true the moment the Flutter landing was deleted: nothing in the app reads
a word of it, and leaving it there shipped 86 strings per locale inside
main.dart.wasm for a page the app does not draw.

Run through tool/build_site.sh, which also builds the app into build/site/app.
"""

import html
import json
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
OUT = ROOT / "build/site"

SLOT = re.compile(r"\{\{([a-zA-Z0-9_.]+)\}\}")

# Default locale is served at /, the rest under /<code>/.
LOCALES = ["es", "en"]

# (template, subdirectory under the locale root). The landing sits at the root;
# the action page is what the reset and verification emails link to, so its path
# is part of the contract with functions/src/index.ts — moving it here without
# moving it there sends every link in the wild to a 404.
PAGES = [
    ("template.html", ""),
    ("action.html", "auth/action"),
]

# Each page ships one stylesheet: the shared base plus its own rules. Two files
# would cost a second blocking request for a page whose whole point is to be
# cheap to open.
SHEETS = {
    "landing.css": ("base.css", "landing.css"),
    "action.css": ("base.css", "action.css"),
}
ORIGIN = "https://agora-vnevarezt.web.app"

# The hero art: one montage per device class, at two densities, rendered into
# site/media/ by tool/demo/site_shots.py. Named here rather than in the
# stylesheet because the shot has interface text in it, so it differs per
# locale, and there is one landing.css for every locale.
#
# The widths are the ones landing.css switches on, and the preload below has to
# repeat them: a preload that disagreed with the stylesheet by one pixel would
# fetch a montage the page then declines to use.
SHOT_SLOTS = {
    "phone": "(max-width: 720px)",
    "tablet": "(min-width: 721px) and (max-width: 1080px)",
    "desk": "(min-width: 1081px)",
}


def esc(value: str) -> str:
    return html.escape(str(value), quote=True)


def mark() -> str:
    """The brand mark, inlined from the files gen_brand_assets.py renders.

    Read at build time rather than copied into the CSS, so the page can never
    hold a stale version of a drawing whose source of truth is a script two
    directories away. Both variants ship because only the back plane changes
    between them, and it has to: the brand navy drowns on a dark ground.

    Inline rather than <img>: it is 200 bytes against a request, on a page
    whose whole point is to be cheap to open.
    """
    out = []
    for theme, name in (("light", "agora-mark.svg"), ("dark", "agora-mark-dark.svg")):
        svg = (ROOT / "assets/brand" / name).read_text().strip()
        # Drop the intrinsic size; the height comes from CSS and the width
        # follows the viewBox, or the mark cannot be reused at two sizes.
        svg = re.sub(r'\s(width|height)="[^"]*"', "", svg, count=2)
        out.append(svg.replace("<svg ", f'<svg class="mark-on-{theme}" ', 1))
    return "".join(out)


def wordmark_ink() -> str:
    """The lockup's word colour, per theme, as custom properties.

    Same source as the mark: gen_brand_assets.py holds it, the app reads its
    own copy (guarded by test/ui/agora_mark_test.dart), and this pulls it out
    of the generator so the page cannot be the one that drifts.
    """
    src = (ROOT / "tool/gen_brand_assets.py").read_text()
    line = re.search(r"^WORDMARK_INK = (.*)$", src, re.M).group(1)
    light, dark = re.findall(r"#[0-9a-f]{6}", line)
    return (
        f":root {{ --brand-word: {light}; }}\n"
        "@media (prefers-color-scheme: dark) {\n"
        f'  :root:not([data-theme="light"]) {{ --brand-word: {dark}; }}\n'
        "}\n"
        f':root[data-theme="dark"] {{ --brand-word: {dark}; }}\n'
    )


def shot_url(slot: str, locale: str, theme: str, density: int) -> str:
    at = "" if density == 1 else f"@{density}x"
    return f"/media/hero-{slot}-{locale}-{theme}{at}.webp"


def render_shot(locale: str, alt: str) -> str:
    """The hero montage, as the candidates landing.css picks one of.

    A background image rather than a <picture>, because the theme here is a
    data-theme attribute as often as it is prefers-color-scheme and a source
    media query cannot see the attribute. Only the rule that wins is ever
    fetched, so the reader pays for one of these, not twelve.
    """
    props = "".join(
        f"--shot-{slot}-{theme}{'' if d == 1 else f'-{d}x'}:"
        f"url({shot_url(slot, locale, theme, d)});"
        for slot in SHOT_SLOTS
        for theme in ("light", "dark")
        for d in (1, 2)
    )
    return f'<div class="shot" role="img" aria-label="{alt}" style="{props}"></div>'


def render_program(locale: str, alt: str) -> str:
    """One iPad with the preview panel open, under the timing section.

    Same mechanism as the hero and for the same reasons — locale in the URL,
    theme in the cascade — but one composition rather than three: the argument
    there is the program, not the hardware, so nothing is gained by handing a
    phone reader a phone.
    """
    props = "".join(
        f"--program-{theme}{'' if d == 1 else f'-{d}x'}:"
        f"url(/media/program-{locale}-{theme}{'' if d == 1 else f'@{d}x'}.webp);"
        for theme in ("light", "dark")
        for d in (1, 2, 3)
    )
    return (f'<div class="program" role="img" aria-label="{alt}" '
            f'style="{props}"></div>')


def shot_preload(locale: str) -> str:
    """Start the hero fetching with the stylesheet, not after it.

    A background image is not visible to the preload scanner: the browser has
    to parse the CSS, build the box and resolve the custom property before it
    learns there is an image at all, which on the largest thing on the page is
    the difference between the hero arriving with the text and arriving after
    it. Each link carries the same width the stylesheet switches on plus the
    theme, so exactly one of the six matches.

    The one it can get wrong is a reader whose stored theme contradicts their
    system: the media query only knows the system, so that reader fetches one
    montage they will not see. One wasted image against a hero that lands late
    for everyone else is the trade.
    """
    links = []
    for slot, width in SHOT_SLOTS.items():
        for theme in ("light", "dark"):
            srcset = ", ".join(
                f"{shot_url(slot, locale, theme, d)} {d}x" for d in (1, 2)
            )
            links.append(
                f'<link rel="preload" as="image" fetchpriority="high" '
                f'imagesrcset="{srcset}" '
                f'media="{width} and (prefers-color-scheme: {theme})">'
            )
    return "\n".join(links)


def flatten(node, prefix="", out=None):
    out = {} if out is None else out
    for key, value in node.items():
        path = f"{prefix}{key}"
        if isinstance(value, dict):
            flatten(value, path + ".", out)
        else:
            out[path] = value
    return out


def alternates(locale: str) -> str:
    links = []
    for other in LOCALES:
        href = ORIGIN + ("/" if other == LOCALES[0] else f"/{other}/")
        links.append(f'<link rel="alternate" hreflang="{other}" href="{href}">')
    links.append(f'<link rel="alternate" hreflang="x-default" href="{ORIGIN}/">')
    return "\n".join(links)


def build(locale: str, subdir: str, template: str) -> None:
    src = SITE / f"copy/{locale}.json"
    strings = {k: esc(v) for k, v in flatten(json.loads(src.read_text())).items()}
    strings["lang"] = locale
    strings["brand.mark"] = mark()
    strings["shot"] = render_shot(locale, strings["landing.hero.shotAlt"])
    strings["shot.preload"] = shot_preload(locale)
    strings["programShot"] = render_program(
        locale, strings["landing.schedules.shotAlt"]
    )
    strings["meta.canonical"] = ORIGIN + (
        "/" if locale == LOCALES[0] else f"/{locale}/"
    )
    strings["meta.alternates"] = alternates(locale)

    missing = []

    def fill(match):
        key = match.group(1)
        if key not in strings:
            missing.append(key)
            return match.group(0)
        return str(strings[key])

    page = SLOT.sub(fill, template)
    if missing:
        sys.exit(f"{locale}: template asks for keys that do not exist: {sorted(set(missing))}")

    parts = [p for p in ("" if locale == LOCALES[0] else locale, subdir) if p]
    target = OUT.joinpath(*parts, "index.html")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(page)
    print(f"  {target.relative_to(ROOT)}  ({len(page) // 1024} KB)")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    for name in ("tokens.css", "landing.js", "action.js"):
        shutil.copy2(SITE / name, OUT / name)
    ink = wordmark_ink()
    for out_name, sources in SHEETS.items():
        (OUT / out_name).write_text(
            ink + "".join((SITE / src).read_text() for src in sources)
        )
    shutil.copytree(SITE / "fonts", OUT / "fonts", dirs_exist_ok=True)
    shutil.copytree(SITE / "media", OUT / "media", dirs_exist_ok=True)

    # Shared with the app shell so a bookmark of either shows the same icon.
    shutil.copy2(ROOT / "web/favicon.png", OUT / "favicon.png")
    shutil.copytree(ROOT / "web/icons", OUT / "icons", dirs_exist_ok=True)

    for name, subdir in PAGES:
        template = (SITE / name).read_text()
        for locale in LOCALES:
            build(locale, subdir, template)


if __name__ == "__main__":
    main()
