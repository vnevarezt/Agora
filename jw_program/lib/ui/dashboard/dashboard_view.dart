import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../state/dashboard_provider.dart';
import '../responsive.dart';
import '../shell/program_shell.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/block_title.dart';
import '../widgets/filter_pill.dart';
import 'new_project_card.dart';
import 'project_card.dart';
import 'project_modal.dart';
import 'reminder_card.dart';

/// Vista de Inicio (`HomeView` del mock): greeting, filters, cuadrícula de
/// projects y panel de reminders. Los datos son de ejemplo (solo UI).
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
          child: const _TopBar(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Filters(),
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
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Buenos días';
  if (h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final isMobile = context.isMobile;
    final user = ref.watch(sessionUserProvider);
    final greeting = user.name.isEmpty
        ? _greeting()
        : '${_greeting()}, ${user.name}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
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
          onPressed: () => showProjectModal(context),
        ),
      ],
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final congregations = ref.watch(congregationsProvider);
    final projects = ref.watch(projectsProvider);
    final filters = ref.watch(dashboardFiltersProvider);
    final notifier = ref.read(dashboardFiltersProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterPill(
          label: 'Todas',
          count: projects.length,
          active: filters.congregationId == 'all',
          onTap: () => notifier.setCongregation('all'),
        ),
        for (final c in congregations)
          FilterPill(
            label: c.name,
            dotColor: Color(c.color),
            count: projects.where((p) => p.congregationId == c.id).length,
            active: filters.congregationId == c.id,
            onTap: () => notifier.setCongregation(c.id),
          ),
        Container(width: 1, height: 22, color: t.border),
        FilterPill(
          label: 'Todo estado',
          active: filters.status == null,
          onTap: () => notifier.setStatus(null),
        ),
        for (final e in ProjectStatus.values)
          FilterPill(
            label: e.plural,
            active: filters.status == e,
            onTap: () => notifier.setStatus(e),
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
    const projects = _ProjectsSection();
    const reminders = _RemindersSection();

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          projects,
          SizedBox(height: 24),
          reminders,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(child: projects),
        SizedBox(width: 22),
        SizedBox(width: 312, child: reminders),
      ],
    );
  }
}

class _ProjectsSection extends ConsumerWidget {
  const _ProjectsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final congregations = ref.watch(congregationsProvider);
    final projects = ref.watch(filteredProjectsProvider);
    final porId = {for (final c in congregations) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(title: 'Proyectos', count: projects.length),
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
                  child: NewProjectCard(
                    onTap: () => showProjectModal(context),
                  ),
                ),
                for (final p in projects)
                  SizedBox(
                    width: colW,
                    child: ProjectCard(
                      proyecto: p,
                      congregation: porId[p.congregationId],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => ProgramShell(proyecto: p)),
                      ),
                      onEdit: () => showProjectModal(context, proyecto: p),
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

class _RemindersSection extends ConsumerWidget {
  const _RemindersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(
          title: 'Recordatorios',
          count: reminders.length,
          linkLabel: 'Ver todo',
          onLink: () {},
        ),
        for (var i = 0; i < reminders.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          ReminderCard(recordatorio: reminders[i]),
        ],
      ],
    );
  }
}
