import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/proyecto.dart';
import '../../state/dashboard_provider.dart';
import '../responsive.dart';
import '../shell/program_shell.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import 'block_title.dart';
import 'filter_pill.dart';
import 'new_project_card.dart';
import 'project_card.dart';
import 'reminder_card.dart';

/// Vista de Inicio (`HomeView` del mock): saludo, filtros, cuadrícula de
/// proyectos y panel de recordatorios. Los datos son de ejemplo (solo UI).
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = context.screenSize;
    final isMobile = size == ScreenSize.mobile;
    final pad = isMobile ? 16.0 : 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
          child: const _Topbar(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Filtros(),
                const SizedBox(height: 18),
                _HomeGrid(stacked: size != ScreenSize.desktop),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Saludo según la hora del día.
String _saludo() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Buenos días';
  if (h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

class _Topbar extends ConsumerWidget {
  const _Topbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final isMobile = context.isMobile;
    final usuario = ref.watch(usuarioProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_saludo()}, ${usuario.nombre}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 19 : 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.42,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tus proyectos y pendientes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textMute,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppIconButton(
          icon: Icons.notifications_none_rounded,
          bordered: true,
          tooltip: 'Recordatorios',
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        AppButton(
          icon: Icons.add,
          label: isMobile ? null : 'Nuevo proyecto',
          onPressed: () {}, // modal diferido a una fase posterior
        ),
      ],
    );
  }
}

class _Filtros extends ConsumerWidget {
  const _Filtros();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final congs = ref.watch(congregacionesDashProvider);
    final proyectos = ref.watch(proyectosProvider);
    final filtros = ref.watch(dashFiltrosProvider);
    final notifier = ref.read(dashFiltrosProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterPill(
          label: 'Todas',
          count: proyectos.length,
          active: filtros.congId == 'all',
          onTap: () => notifier.setCong('all'),
        ),
        for (final c in congs)
          FilterPill(
            label: c.nombre,
            dotColor: c.color,
            count: proyectos.where((p) => p.congregacionId == c.id).length,
            active: filtros.congId == c.id,
            onTap: () => notifier.setCong(c.id),
          ),
        Container(width: 1, height: 22, color: t.border),
        FilterPill(
          label: 'Todo estado',
          active: filtros.estado == null,
          onTap: () => notifier.setEstado(null),
        ),
        for (final e in EstadoProyecto.values)
          FilterPill(
            label: e.plural,
            active: filtros.estado == e,
            onTap: () => notifier.setEstado(e),
          ),
      ],
    );
  }
}

class _HomeGrid extends ConsumerWidget {
  const _HomeGrid({required this.stacked});

  final bool stacked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const proyectos = _ProyectosSection();
    const recordatorios = _RecordatoriosSection();

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          proyectos,
          SizedBox(height: 24),
          recordatorios,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(child: proyectos),
        SizedBox(width: 22),
        SizedBox(width: 312, child: recordatorios),
      ],
    );
  }
}

class _ProyectosSection extends ConsumerWidget {
  const _ProyectosSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final congs = ref.watch(congregacionesDashProvider);
    final proyectos = ref.watch(proyectosFiltradosProvider);
    final porId = {for (final c in congs) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(title: 'Proyectos', count: proyectos.length),
        LayoutBuilder(
          builder: (context, c) {
            const gap = 14.0;
            final cols = (c.maxWidth / 264).floor().clamp(1, 4);
            final colW = (c.maxWidth - (cols - 1) * gap) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: colW,
                  child: NewProjectCard(onTap: () {}),
                ),
                for (final p in proyectos)
                  SizedBox(
                    width: colW,
                    child: ProjectCard(
                      proyecto: p,
                      congregacion: porId[p.congregacionId],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const ProgramShell()),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RecordatoriosSection extends ConsumerWidget {
  const _RecordatoriosSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordatorios = ref.watch(recordatoriosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(
          title: 'Recordatorios',
          count: recordatorios.length,
          linkLabel: 'Ver todo',
          onLink: () {},
        ),
        for (var i = 0; i < recordatorios.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          ReminderCard(recordatorio: recordatorios[i]),
        ],
      ],
    );
  }
}
