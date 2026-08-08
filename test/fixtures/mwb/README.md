# EPUB parser fixtures

Two week files, one per language, reproducing the **markup** of a real `mwb`
workbook: the heading hierarchy, the `du-color--*` section colors, the
`dc-icon--music` / `du-borderStyle-top--solid` classes on the song and
comments headings, and the `(N min.)` / `(N mins.)` duration forms.

Titles and article references are invented — the point is the structure, which
is what `epub_parser.dart` keys off. Verified against `mwb_S_202607` and
`mwb_E_202607`: both languages emit byte-identical class attributes, and the
only per-language text the parser still needs is the talk marker
(`Discurso.` / `Talk.`), which is why `_talkMarkers` exists.

`es_week.xhtml` covers the common shape. `en_week.xhtml` is the same week in
English AND exercises the case the old title-only matching got wrong: a
ministry part whose talk marker lives in the body, not the title.
