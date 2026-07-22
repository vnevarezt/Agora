# Dos semanas por hoja + exportar PDF/imagen (guardar o compartir)

Estado: **implementado**.

Dos mejoras al flujo de salida del programa VMC:

1. **Dos semanas por hoja** (2-up): opción para imprimir/visualizar dos
   programas en una hoja carta horizontal, en vez de una hoja por semana.
2. **Exportar en PDF o imagen (PNG)**, eligiendo **dónde guardar** o
   **compartir** directo a otra app (WhatsApp, Correo, Drive…) en cualquier
   plataforma.

## Dos semanas por hoja

Carta **vertical** con los dos bloques de semana **apilados** bajo UNA sola
cabecera compartida (congregación + "Programa para la reunión de entre semana"
impresos una vez), imitando el formato del tablón. El contenido **refluye** en
métricas compactas ([S140Metrics.compact](../../lib/pdf/pdf_theme.dart)) en vez
de foto-reducirse: tipografía ~9.5 pt, separación de filas ~3.5 pt, márgenes
más apretados (contenido 547 pt de ancho) — los títulos y nombres aprovechan
todo el ancho real, también en modo Sala Auxiliar (4 columnas). Un
`pw.FittedBox(fit: scaleDown)` actúa solo como red de seguridad: encoge
uniformemente ÚNICAMENTE si una semana inusualmente larga desbordara la hoja.

- Métricas: [S140Metrics](../../lib/pdf/pdf_theme.dart) parametriza fuentes,
  columnas y espaciados con presets `standard` (S-140 oficial, 1 semana/página)
  y `compact` (2 por hoja). `computeColumns` y todos los builders del documento
  reciben las métricas — los anchos adaptativos de nombres funcionan igual en
  ambos modos.
- Generador: [buildProgramSheetPdf](../../lib/pdf/program_document.dart) recibe
  `List<WeekEntry>` (1–2) + `twoPerSheet`. `buildProgramPdf` (una semana) queda
  como wrapper. La cabecera se extrajo a `_headerBlock` (una vez por hoja) y el
  bloque de semana a `_weekBlock`, reusados por ambos modos.
- Emparejado: [sheetWeekIndices](../../lib/state/program_form.dart) alinea a
  pares pares (`[0,1] [2,3] …`) para que imprimir todas las hojas nunca duplique
  una semana; la última semana impar va sola. `sheetEntriesProvider` arma las
  entradas de la hoja activa, cada una con su propio schedule/nombres/presidente.
- Preview: [preview_provider](../../lib/state/preview_provider.dart) escucha
  `sheetEntriesProvider` (cubre semana(s), schedule, nombres, presidente y el
  flag 2-up). El visor no cambió (es agnóstico al tamaño de página).
- Toggle "Dos por hoja" en el popover del selector de semana
  ([project_bar.dart](../../lib/ui/shell/project_bar.dart), junto a Sala
  Auxiliar). Es preferencia **local del dispositivo**
  ([app_settings.dart](../../lib/state/app_settings.dart), `twoPerSheet` en
  SharedPreferences): preferencia de impresión, no dato de congregación → sin
  migración de esquema ni sync.

## Exportar: formato + acción

El menú de exportar (desktop: popover en la barra; móvil: hoja modal) ofrece:

- **Formato**: PDF | Imagen (PNG a 300 dpi, ideal para WhatsApp).
- **Acción**: Guardar (elige ubicación) o Compartir (share sheet).

- Orquestación:
  [previewProvider.export({format, action, shareOrigin})](../../lib/state/preview_provider.dart)
  construye el PDF de la hoja actual (1-up o 2-up), rasteriza a PNG si toca, y
  delega en `FileSaver`. Nombre `programa-<issue>-s3[-s4].<ext>`.
- [FileSaver](../../lib/data/files/file_saver.dart) tiene dos acciones
  explícitas: `saveAs` (diálogo nativo en desktop vía file_selector; document
  picker/SAF en móvil vía **file_picker**) y `share` (share_plus en todas las
  plataformas; `originRect` ancla el popover en iPad/macOS). El backup `.agora`
  ([application_tab.dart](../../lib/ui/config/application_tab.dart)) pasó a
  `saveAs` (antes autodecidía por plataforma).
- PNG: [renderPagePng](../../lib/pdf/pdf_rasterizer.dart) reutiliza `rasterizePage`.
- UI compartida: [ExportPanel](../../lib/ui/widgets/export_panel.dart) (selector
  de formato + botones Guardar/Compartir) y
  [export_actions.dart](../../lib/ui/widgets/export_actions.dart) (`runExport` +
  `originRectOf`), reusados por el menú desktop y la hoja móvil.

## Verificación

- Unit ([pdf_test](../../test/pdf_test.dart),
  [sheet_pairing_test](../../test/state/sheet_pairing_test.dart),
  [file_saver_test](../../test/data/file_saver_test.dart)): PDF válido 1-up y
  2-up (incluida hoja impar con una entrada), emparejado de semanas, y mapeo de
  outcomes de `saveAs`/`share`. Correr con `rtk proxy flutter test` (el wrapper
  rtk trunca fallos).
- Integración ([render_test](../../integration_test/render_test.dart), macOS):
  el 2-up produce UNA página vertical (alto > ancho) y rasteriza a `jw_2up.png`
  y `jw_2up_aux.png` (modo Sala Auxiliar) para inspección visual.

## Fuera de alcance (seguimiento natural)

- "Proyecto completo": todas las semanas en un PDF multipágina (2 por hoja).
  Queda casi gratis sobre `buildProgramSheetPdf` (lista de entradas → páginas en
  bucle). Placeholder deshabilitado en el menú.
- Formato JPG (trivial de añadir). La plantilla LaTeX original no se toca.
