# Feature (investigación): edición de nombres en vivo SOBRE la plantilla

> Estado: **investigado, sin implementar**. Documento para retomar después.
> Fecha investigación: 2026-06-06.

## Objetivo
Que los campos de nombre de los participantes se editen **directamente sobre la
plantilla/preview** y se vea en tiempo real cómo queda el PDF, en vez de tener
inputs en un panel lateral separado de la app.

Requisito transversal: soporte **iOS, Android, macOS, Windows** (y deseable web/Linux),
buen rendimiento y, a poder ser, sin dependencias comerciales.

---

## ✅ Plan elegido: Opción C — Overlay de `TextField` sobre el preview

### Idea
Mantener el preview actual (imagen rasterizada de la página con pdfrx/pdfium) y
colocar `TextField` de Flutter **encima, en las coordenadas exactas** de cada hueco
de nombre, dentro de un `Stack`. El usuario escribe "sobre la hoja".

- El texto vive en el **overlay** (estado de Flutter), no dentro de la imagen.
- Teclear es **instantáneo**: NO hay que regenerar/rasterizar el PDF en cada tecla.
- El PDF real se genera **solo al exportar**, con el generador `pdf` actual
  (`buildProgramPdf`) → se conserva la fidelidad pixel-perfect del formato S-140-S.

### Por qué esta opción
- **Flutter puro** → cubre las 4 plataformas sin dependencias comerciales.
- **Rendimiento**: incluso mejor que el esquema actual (no rasteriza al teclear).
- **Conserva el export exacto**: el overlay es solo la forma de editar; el PDF
  final sigue saliendo de nuestro generador ya validado.
- Riesgo bajo comparado con migrar a `flutter_to_pdf` (Opción A) o a Syncfusion (Opción B).

### Cómo encaja con el código actual
- Ya existe la lista de filas con sus huecos: `ProgramRow` (en `lib/schedule/rules.dart`),
  con `slots`, `rol`, `nombres[]`. Hoy esos nombres se editan en el panel
  `_editorNombres()` de `lib/ui/program_screen.dart`.
- El preview ya rasteriza la página con pdfium y la muestra con `RawImage` dentro
  de un `InteractiveViewer` con `TransformationController _tc` (zoom/pan).
- Plan C = mover esos `TextField` desde el panel lateral a posiciones absolutas
  encima de la imagen del preview.

### Trabajo principal (y el reto conocido)
1. **Mapeo de coordenadas**: calcular la posición (x, y, ancho, alto) en **puntos PDF**
   de cada celda de nombre. Lo controlamos nosotros porque generamos el layout en
   `lib/pdf/program_pdf.dart` con constantes en `lib/pdf/style.dart`
   (Carta 612×792, márgenes, `anchoNomPrin`, `anchoRol`, alto de fila, etc.).
   - Sugerencia: que `buildProgramPdf`/el motor de layout devuelva también un
     "mapa de cajas" de cada nombre (rect en puntos) junto al PDF, para no
     recalcular a ojo.
2. **Transformar puntos PDF → píxeles en pantalla**: aplicar la escala de
   rasterizado y, sobre todo, **la misma transformación del `InteractiveViewer`**
   (zoom + pan) a cada `TextField` para que sigan pegados a su hueco al hacer
   zoom/scroll. (Este es el punto delicado citado en los foros: los overlays hay
   que transformarlos en sincronía con la página.)
   - Posible vía: escuchar `_tc` (Matrix4) y posicionar cada input con
     `Positioned`/`Transform` aplicando esa matriz; o meter los inputs DENTRO del
     mismo hijo del `InteractiveViewer` (así heredan zoom/pan automáticamente) y
     posicionarlos con `Positioned` en coordenadas de la hoja (no de pantalla).
     ⭐ Esta segunda (inputs dentro del child transformado) evita re-sincronizar a mano.
3. **Apariencia integrada**: el `TextField` del overlay debe usar **Carlito** y un
   tamaño/escala que combine con el texto rasterizado (mismo tamaño que en el PDF
   multiplicado por la escala de display) para que parezca parte de la hoja.
4. **Export sin cambios**: al exportar, volcar los valores del overlay a
   `ProgramRow.nombres` y llamar a `buildProgramPdf` (igual que hoy).

### Consideraciones / pendientes a decidir
- ¿Mostrar también el nombre rasterizado o dejar el hueco en blanco en la imagen y
  que SOLO el overlay muestre el texto? (Recomendado: la imagen lleva los huecos
  vacíos y el overlay pinta el texto, para que no se duplique/solape.)
- Tamaño de fuente al hacer zoom (si los inputs van dentro del child transformado,
  escalan solos).
- Campos de 2 nombres (Estudiante/Ayudante, Conductor/Lector) → dos inputs en la
  misma fila, separados por " / ".
- Presidente y oraciones también son huecos overlay.

### Rendimiento esperado
- Edición: instantánea (sólo estado Flutter).
- Re-rasterizado de la imagen: solo cuando cambian datos que NO son nombres
  (semana, hora, congregación) o al hacer zoom (para nitidez), como ya ocurre.

---

## Apéndice: alternativas investigadas (descartadas para esta fase)

### Opción A — Plantilla nativa en widgets + `flutter_to_pdf`
La plantilla S-140-S se construye como widgets Flutter con `TextField` inline; se
exporta con `flutter_to_pdf` (puede dejar campos rellenables o aplanarlos).
- **Pro**: editor y documento son lo mismo → tiempo real máximo; todas las plataformas.
- **Contra**: el PDF sale por una ruta distinta a nuestro generador `pdf` → re-validar
  fidelidad; duplicar layout o migrar export. `flutter_to_pdf` v0.4.1 (~10 meses, MIT,
  un publisher) = riesgo de mantenimiento medio.

### Opción B — Campos de formulario reales (AcroForm) en el PDF
Generar el PDF con campos AcroForm y usar un visor que permita rellenarlos.
- **Pro**: editas dentro del PDF real (máxima fidelidad); relleno nativo rápido.
- **Contra**: **pdfrx NO tiene UI de edición de formularios**. Habría que usar
  **Syncfusion SfPdfViewer** (comercial; gratis solo con *Community License*:
  <$1M ingresos, ≤5 devs, ≤10 empleados) o Nutrient/PSPDFKit (de pago). La opción
  libre `pdf_acroform` es poco madura.

---

## Fuentes
- Syncfusion — Form filling in Flutter PDF Viewer: https://help.syncfusion.com/document-processing/pdf/pdf-viewer/flutter/form-filling
- syncfusion_flutter_pdfviewer: https://pub.dev/packages/syncfusion_flutter_pdfviewer
- pdfrx: https://pub.dev/packages/pdfrx
- Nutrient — Flutter PDF forms: https://www.nutrient.io/guides/flutter/forms/
- pdf_acroform: https://pub.dev/packages/pdf_acroform/versions
- flutter_to_pdf: https://pub.dev/packages/flutter_to_pdf
- LogRocket — Implementing overlays in Flutter: https://blog.logrocket.com/complete-guide-implementing-overlays-flutter/
- Syncfusion forum — Screen tap to PDF page coordinates: https://www.syncfusion.com/forums/196022/screen-tap-to-coordinates-with-respect-to-pdf-page
