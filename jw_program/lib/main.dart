import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'ui/program_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize(); // pdfium para rasterizar el preview en escritorio
  runApp(const JwProgramApp());
}

class JwProgramApp extends StatelessWidget {
  const JwProgramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JW Program',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7E0024)),
        useMaterial3: true,
      ),
      home: const ProgramScreen(),
    );
  }
}
