import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';
import 'i18n/strings.g.dart';
import 'state/app_settings.dart';
import 'state/locale_boot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Precalentamiento de pdfium para que el primer preview no espere. Sólo en
  // escritorio: en web esto inyecta pdfium_client.js y arranca un worker que
  // baja 5 MB de wasm compitiendo con los primeros frames.
  //
  // No es lo que garantiza la inicialización — de eso se encarga
  // rasterizePage(), que la exige antes de abrir el documento. Aquí sólo se
  // adelanta donde es barato hacerlo.
  if (!kIsWeb) pdfrxFlutterInitialize();
  await initLocale(); // restaura el idioma guardado o sigue el del dispositivo
  await initAppSettings(); // restaura tema y preferencias de la app
  runApp(
    TranslationProvider(child: const ProviderScope(child: AgoraApp())),
  );
}
