#!/usr/bin/env python3
"""Renders site/template.html into build/site/ for every shipped locale.

The copy comes from lib/i18n/*.i18n.json — the same files the Flutter app is
translated from. That is the point: the landing sells the product, and a
marketing page with its own private copy of the wording drifts from the thing
it describes within a release or two.

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

# The site's own chrome: not in the app's i18n because the app has no use for
# it, and adding it there would ship these strings inside main.dart.wasm.
CHROME = {
    "es": {
        "meta.title": "Agora — Programa de la reunión de entresemana",
        "meta.description": (
            "Escribe los nombres y Agora calcula los tiempos y te deja un PDF "
            "listo para imprimir. Sin cuenta y sin instalar nada."
        ),
        "meta.ogLocale": "es_ES",
        "a11y.skipToContent": "Ir al contenido",
        "a11y.sections": "Secciones",
    },
    "en": {
        "meta.title": "Agora — Midweek meeting program",
        "meta.description": (
            "Type the names and Agora works out the timing and leaves you a "
            "print-ready PDF. No account, nothing to install."
        ),
        "meta.ogLocale": "en_US",
        "a11y.skipToContent": "Skip to content",
        "a11y.sections": "Sections",
    },
}

# Default locale is served at /, the rest under /<code>/.
LOCALES = ["es", "en"]
ORIGIN = "https://agora-vnevarezt.web.app"

# The sample program. Hardcoded, and in Spanish in every locale, for the same
# reason a screenshot in a manual is not retranslated: it is a picture of one
# congregation's printout, not interface text.
SHEET = [
    ("row", "18:00", "Canción 42 y oración", "R. Cano"),
    ("row", "18:05", "Palabras de introducción", "M. Salas"),
    ("band treasures", "Tesoros de la Biblia", None, None),
    ("row", "18:09", "Discurso", "M. Salas"),
    ("row", "18:19", "Busquemos perlas escondidas", "A. Beltrán"),
    ("row", "18:29", "Lectura de la Biblia", "J. Ríos"),
    ("band ministry", "Seamos mejores maestros", None, None),
    ("row", "18:34", "Empiece conversaciones", "D. Puga"),
    ("row", "18:39", "Haga revisitas", "R. Ledesma"),
    ("row", "18:44", "Discurso", "C. Vega"),
    ("gap", None, None, None),
    ("row", "18:49", "Canción 108", None),
    ("band life", "Nuestra vida cristiana", None, None),
    ("row", "18:57", "Necesidades de la congregación", "L. Ordaz"),
    ("row", "19:02", "Estudio bíblico de la congregación", "H. Mena"),
    ("gap", None, None, None),
    ("row", "19:32", "Palabras de conclusión", "M. Salas"),
    ("row", "19:35", "Canción 55 y oración", "T. Ibarra"),
]


def esc(value: str) -> str:
    return html.escape(str(value), quote=True)


def render_sheet() -> str:
    parts = [
        '<div class="sheet" role="img" aria-label="Ejemplo de programa impreso">',
        '<div class="sheet-head"><span>Reunión de entresemana</span>'
        "<span>6-12 abr</span></div>",
    ]
    for kind, a, b, c in SHEET:
        if kind == "gap":
            parts.append('<div class="sheet-gap"></div>')
        elif kind.startswith("band"):
            parts.append(f'<div class="sheet-{kind}">{esc(a)}</div>')
        else:
            name = f'<span class="sheet-n">{esc(c)}</span>' if c else ""
            parts.append(
                f'<div class="sheet-row"><span class="sheet-t">{esc(a)}</span>'
                f'<span class="sheet-p">{esc(b)}</span>{name}</div>'
            )
    parts.append("</div>")
    return "\n".join(parts)


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


def build(locale: str, template: str, sheet: str) -> None:
    src = ROOT / f"lib/i18n/{locale}.i18n.json"
    strings = flatten(json.loads(src.read_text()))
    strings = {k: esc(v) for k, v in strings.items()}
    strings.update(CHROME[locale])
    strings["meta.description"] = esc(strings["meta.description"])
    strings["meta.title"] = esc(strings["meta.title"])
    strings["lang"] = locale
    strings["sheet"] = sheet
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

    target = OUT / ("index.html" if locale == LOCALES[0] else f"{locale}/index.html")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(page)
    print(f"  {target.relative_to(ROOT)}  ({len(page) // 1024} KB)")


def main() -> None:
    template = (SITE / "template.html").read_text()
    sheet = render_sheet()
    OUT.mkdir(parents=True, exist_ok=True)

    for name in ("landing.css", "tokens.css", "landing.js"):
        shutil.copy2(SITE / name, OUT / name)
    shutil.copytree(SITE / "fonts", OUT / "fonts", dirs_exist_ok=True)

    # Shared with the app shell so a bookmark of either shows the same icon.
    shutil.copy2(ROOT / "web/favicon.png", OUT / "favicon.png")
    shutil.copytree(ROOT / "web/icons", OUT / "icons", dirs_exist_ok=True)

    for locale in LOCALES:
        build(locale, template, sheet)


if __name__ == "__main__":
    main()
