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
  // pdfium para rasterizar el preview en escritorio. En web NO: inyecta
  // pdfium_client.js y arranca un worker que baja 5 MB de wasm compitiendo con
  // los primeros frames, y pdfrx ya se inicializa solo (pdf_document_ref hace
  // `await pdfrxFlutterInitialize()` antes de abrir cualquier documento), así
  // que adelantarlo aquí solo mueve el coste al arranque.
  if (!kIsWeb) pdfrxFlutterInitialize();
  await initLocale(); // restaura el idioma guardado o sigue el del dispositivo
  await initAppSettings(); // restaura tema y preferencias de la app
  runApp(
    TranslationProvider(child: const ProviderScope(child: AgoraApp())),
  );
}
