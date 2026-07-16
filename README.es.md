[English](README.md) | Español

<div align="center">

# Agora

**Generador de programas para la congregación**

Planifica, asigna e imprime los programas de las reuniones de la congregación en minutos — PDFs nativos listos para imprimir, sin formateo manual.

<!-- Placeholder de captura principal: reemplazar con una captura real de la app en escritorio y móvil -->
<!-- <img src="docs/assets/hero.png" alt="Agora en escritorio y móvil" width="100%"> -->

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Plataformas](https://img.shields.io/badge/plataformas-Android%20·%20iOS%20·%20macOS%20·%20Windows-4c5b9c)
![Estado](https://img.shields.io/badge/estado-en%20desarrollo%20activo-e0a63b)
![Licencia](https://img.shields.io/badge/licencia-PolyForm%20Noncommercial%201.0.0-8a5cf5)

</div>

---

## Resumen

- **Multiplataforma** — una sola app nativa para Android, iOS, macOS y Windows, construida con Flutter.
- **Local primero** — los datos viven en el dispositivo. Sin cuenta, sin servidor, sin rastreo. Las copias de seguridad son archivos exportables que controla el usuario.
- **PDF nativo** — los programas se generan directamente en PDF listo para imprimir con un diseño de columnas adaptativo; la vista previa coincide exactamente con el resultado impreso.
- **Cuadernos siempre al día** — los cuadernos de la reunión se descargan y almacenan en caché automáticamente, de modo que las semanas nuevas están disponibles en cuanto se publican.
- **Multilingüe** — la interfaz está disponible en español e inglés, independientemente del idioma de la reunión.

## Para quién es Agora

Agora está pensada para quienes preparan el programa de la reunión de entre semana de su congregación y pasan tardes ajustando tablas en un procesador de texto para lograrlo. Si programas asignaciones, repartes participantes e imprimes el programa semanal, Agora es para ti.

Comienza con la reunión de entre semana y está creciendo hacia un generador general de programas para la congregación: hay más tipos de programa planeados sobre la misma base (proyectos, participantes, congregaciones).

## Funciones

- **Constructor de programas** — selecciona las semanas y Agora estructura cada parte de la reunión con secciones, canciones y horarios ya calculados.
- **Horarios automáticos** — la hora de inicio, la duración de las secciones, los minutos de consejo a los estudiantes y el margen se calculan automáticamente; cada fila recibe su hora exacta.
- **Directorio de participantes** — administra los participantes de la congregación con sus privilegios (anciano, siervo ministerial, publicador), para que se ofrezcan los nombres adecuados en las partes adecuadas.
- **Panel de proyectos** — agrupa semanas en proyectos (un mes completo o una sola semana), sigue su estado de borrador a exportado y mantén los recordatorios a la vista.
- **Sala auxiliar** — activa una segunda sala y el programa muestra ambas lado a lado, con columnas adaptativas que nunca se desbordan.
- **Visita del superintendente de circuito** — marca la semana y el programa se adapta automáticamente: el estudio bíblico se reemplaza por el discurso del superintendente y los horarios se recalculan.
- **Títulos editables** — renombra cualquier asignación desde el editor; los títulos personalizados se mantienen sincronizados entre el editor y el PDF impreso.
- **Vista previa en vivo** — el PDF final se vuelve a generar en tiempo real mientras se escribe cada nombre, eliminando el ciclo de exportar y comprobar.
- **Exportación directa** — guarda o comparte el PDF terminado directamente desde la app.
- **Tema claro y oscuro** — ambos modos totalmente soportados, siguiendo el sistema o la preferencia del usuario.

<!-- Placeholder de captura: programa impreso -->
<!-- <img src="docs/assets/program-output.png" alt="Programa impreso generado por Agora" width="100%"> -->

## Plataformas soportadas

Agora es una aplicación nativa de Flutter.

| Plataforma | Estado |
| --- | --- |
| macOS | Objetivo principal de desarrollo |
| Windows | Soportado |
| Android | Soportado |
| iOS | Soportado |

## ¿Agora necesita la nube?

No. Agora funciona en modo local: todo se guarda en el dispositivo y la app es completamente funcional sin conexión. El único uso de red es la descarga de los cuadernos de la reunión cuando se publican nuevos. La copia de seguridad portátil permite proteger los datos y moverlos entre dispositivos.

Una **cuenta local** protege tus datos: la llave de cifrado de la base de datos se envuelve con tu contraseña, así que abrir la app siempre la requiere. No hay recuperación a propósito — **si olvidas la contraseña local, los datos de ese dispositivo se pierden** (mantén copias portátiles). Opcionalmente puedes iniciar sesión con una **cuenta de nube** (Firebase, correo/contraseña o Google) como identidad para la sincronización futura; nunca sustituye a la contraseña local. Cada desarrollador conecta su propio proyecto de Firebase — en este repositorio no vive ninguna configuración de nube. Ver [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

## Tecnologías

- [Flutter](https://flutter.dev) + [Riverpod](https://riverpod.dev) — UI y gestión de estado
- [pdf](https://pub.dev/packages/pdf) + [pdfrx](https://pub.dev/packages/pdfrx) — generación nativa de PDF y vista previa en tiempo real
- [slang](https://pub.dev/packages/slang) — i18n con tipado seguro (español, inglés)
- [Drift](https://drift.simonbinder.eu) + almacenamiento cifrado — base de datos local

## Primeros pasos (desarrollo)

```bash
git clone https://github.com/vnevarezt/Agora.git
cd Agora
sh tool/bootstrap.sh # crea los placeholders de config ignorados por git (funciona 100 % local)
flutter pub get
flutter run          # elige tu dispositivo: macOS, Windows, Android, iOS
```

Para habilitar el inicio de sesión de nube opcional con tu propio proyecto de Firebase, sigue [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

Comandos útiles:

```bash
dart run slang       # regenera las traducciones tras editar lib/i18n/*.i18n.json
flutter test         # ejecuta la suite de tests
flutter analyze      # análisis estático
```

## Cómo contribuir

1. **Dale una estrella al repositorio** — ayuda a que otros encuentren el proyecto.
2. **Reporta errores e ideas** — abre un [issue](https://github.com/vnevarezt/Agora/issues); la retroalimentación de quienes preparan programas reales es especialmente valiosa.
3. **Ayuda a traducir** — la app usa archivos JSON de traducción sencillos; añadir un idioma es una buena primera contribución.
4. **Contribuye código** — los pull requests son bienvenidos. Mantén los textos de la UI en slang i18n y los comentarios en inglés.

## Hoja de ruta

- [ ] Más tipos de programa además de la reunión de entre semana
- [ ] Historial de asignaciones y balance de carga
- [ ] Interfaz en portugués
- [ ] Sincronización en la nube opcional sobre el modo local

## Licencia

Agora es software de código disponible ("source-available"), publicado bajo la [PolyForm Noncommercial License 1.0.0](LICENSE.md).

En resumen:

- **El uso personal y no comercial es libre y gratuito** — úsala, estúdiala, modifícala y compártela para cualquier fin no comercial, incluido el uso por congregaciones, organizaciones benéficas e instituciones educativas.
- **El uso comercial requiere una licencia aparte.** Si quieres usar Agora, o una obra basada en ella, con cualquier fin comercial, contacta primero con el autor: [vicentenevarezt@gmail.com](mailto:vicentenevarezt@gmail.com).

Este resumen es solo informativo; lo que rige es el [texto de la licencia](LICENSE.md) (en inglés).

Required Notice: Copyright (c) 2026 Vicente Nevarez Treviño (https://github.com/vnevarezt)
