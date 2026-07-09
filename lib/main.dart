import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';
import 'i18n/strings.g.dart';
import 'state/locale_boot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize(); // pdfium para rasterizar el preview en escritorio
  await initLocale(); // restaura el idioma guardado o sigue el del dispositivo
  runApp(TranslationProvider(child: const ProviderScope(child: JwProgramApp())));
}
