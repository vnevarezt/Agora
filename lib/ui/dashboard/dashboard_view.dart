import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../models/project.dart';
import '../../state/dashboard_provider.dart';
import '../../state/mwb_sync.dart';
import '../responsive.dart';
import '../shell/program_shell.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/block_title.dart';
import '../widgets/filter_pill.dart';
import 'new_project_card.dart';
import 'project_card.dart';
import 'project_modal.dart';
import 'reminder_card.dart';

/// Home view (`HomeView`): greeting, filters, a grid of projects and a
/// reminders panel. Data is example-only (UI-only).
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

/// Greeting based on the time of day.
String _greeting(Translations tr) {
  final h = DateTime.now().hour;
  if (h < 12) return tr.dashboard.greetingMorning;
  if (h < 19) return tr.dashboard.greetingAfternoon;
  return tr.dashboard.greetingEvening;
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tr = context.t;
    final isMobile = context.isMobile;
    final user = ref.watch(sessionUserProvider);
    final greeting = user.name.isEmpty
        ? _greeting(tr)
        : tr.dashboard.greetingNamed(greeting: _greeting(tr), name: user.name);

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
                tr.dashboard.subtitle,
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
        _SyncIndicator(
          state: _catalogState(ref.watch(mwbSyncProvider)),
          compact: isMobile,
        ),
        const SizedBox(width: 8),
        AppIconButton(
          icon: Icons.notifications_none_rounded,
          bordered: true,
          tooltip: tr.common.reminders,
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        AppButton(
          icon: Icons.add,
          label: isMobile ? null : tr.dashboard.newProject,
          onPressed: () => showProjectModal(context),
        ),
      ],
    );
  }
}

/// Persistent state of the notebook catalog, shown in the header.
enum _CatalogState { busy, ok, incomplete }

_CatalogState _catalogState(AsyncValue<SyncReport> sync) {
  if (sync.isLoading) return _CatalogState.busy;
  final report = sync.asData?.value;
  if (report == null) return _CatalogState.incomplete; // sync error
  return report.complete ? _CatalogState.ok : _CatalogState.incomplete;
}

/// Persistent card next to the notifications button: spinner while syncing,
/// a check when everything is up to date, a warning when a notebook is missing.
/// On mobile it collapses to an icon-only square to save space.
class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator({required this.state, this.compact = false});

  final _CatalogState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    const amber = Color(0xFFB9890F);

    final (IconData? icon, String label, Color color, String tip) =
        switch (state) {
      _CatalogState.busy => (
          null,
          tr.sync.updating,
          t.accent,
          tr.sync.updatingTip,
        ),
      _CatalogState.ok => (
          Icons.check_circle_rounded,
          tr.sync.upToDate,
          t.accent,
          tr.sync.upToDateTip,
        ),
      _CatalogState.incomplete => (
          Icons.error_outline_rounded,
          tr.sync.missing,
          amber,
          tr.sync.missingTip,
        ),
    };

    final leading = icon == null
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : Icon(icon, size: 17, color: color);

    return Tooltip(
      message: tip,
      child: Container(
        height: Dimens.hControl,
        width: compact ? Dimens.hControl : null,
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(Dimens.rControl),
          border: Border.all(color: t.border),
        ),
        child: compact
            ? Center(child: leading)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textDim,
                    ),
                  ),
                ],
              ),
      ),
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
          label: context.t.common.allFeminine,
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
          label: context.t.dashboard.allStatus,
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
        BlockTitle(title: context.t.dashboard.projects, count: projects.length),
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
                      project: p,
                      congregation: porId[p.congregationId],
                      // The editor session hydrates the form (congregation
                      // name included) from the DB on open.
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => ProgramShell(project: p)),
                      ),
                      onEdit: () => showProjectModal(context, project: p),
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
          title: context.t.dashboard.reminders,
          count: reminders.length,
          linkLabel: context.t.dashboard.seeAll,
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
