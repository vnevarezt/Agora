import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/ui_state.dart';
import '../config/settings_view.dart';
import '../dashboard/dashboard_view.dart';
import '../participants/participants_view.dart';
import '../responsive.dart';
import 'sidebar_nav.dart';

/// Shell raíz de la app: navegación lateral + área de contenido que conmuta
/// entre Inicio (dashboard), Hermanos y Configuración. En móvil la barra
/// lateral se reemplaza por una barra inferior.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = context.screenSize;
    final seccion = ref.watch(appSeccionProvider);

    final body = switch (seccion) {
      AppSeccion.inicio => const DashboardView(),
      AppSeccion.hermanos => const HermanosView(),
      AppSeccion.config => const ConfiguracionView(),
    };

    if (size == ScreenSize.mobile) {
      return Scaffold(
        body: SafeArea(bottom: false, child: body),
        bottomNavigationBar: const BottomNav(),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Sidebar(compact: size == ScreenSize.tablet),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
