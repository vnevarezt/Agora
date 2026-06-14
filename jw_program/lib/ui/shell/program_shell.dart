import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/proyecto.dart';
import '../../state/ui_state.dart';
import '../preview/preview_pane.dart';
import '../responsive.dart';
import '../workspace/workspace_panel.dart';
import 'mobile_bars.dart';
import 'project_bar.dart';

/// Pantalla raíz del editor. Único lugar que decide el layout: escritorio/
/// tablet en dos paneles (46/54) y móvil en una columna con pestañas; ambos
/// arreglos usan los mismos [WorkspacePanel] y [PreviewPane].
class ProgramShell extends StatelessWidget {
  const ProgramShell({super.key, this.proyecto});

  /// Proyecto abierto desde el dashboard (identidad de la barra). Opcional.
  final Proyecto? proyecto;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      body: SafeArea(
        bottom: false, // la bottom bar móvil gestiona su propio inset
        child: Column(
          children: [
            ProjectBar(proyecto: proyecto),
            if (isMobile) const MobileTabs(),
            Expanded(
              child: isMobile
                  ? const _MobileBody()
                  : const Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 46, child: WorkspacePanel()),
                        Expanded(
                          flex: 54,
                          child: PreviewPane(showLeftBorder: true),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuerpo móvil: las pestañas alternan los paneles con [IndexedStack] (el
/// zoom del preview sobrevive al cambio de pestaña) y la bottom bar flota
/// encima con su vidrio esmerilado.
class _MobileBody extends ConsumerWidget {
  const _MobileBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(mobileTabProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: tab.index,
            children: const [WorkspacePanel(), PreviewPane()],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MobileBottomBar(),
        ),
      ],
    );
  }
}
