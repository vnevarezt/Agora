import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../i18n/strings.g.dart';
import '../../models/congregation.dart';
import '../../models/project.dart';
import '../../models/reminder.dart';
import '../../state/dashboard_provider.dart';
import '../../state/mwb_sync.dart';
import '../../state/sync_controller.dart';
import '../../state/sync_provider.dart';
import '../responsive.dart';
import '../shell/program_shell.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/block_title.dart';
import '../widgets/filter_pill.dart';
import 'continue_card.dart';
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
            child: Consumer(builder: (context, ref, _) {
              if (ref.watch(dashboardLoadingProvider)) {
                return _DashboardSkeleton(
                    stacked: size != ScreenSize.desktop);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroSection(),
                  _HomeGrid(stacked: size != ScreenSize.desktop),
                ],
              );
            }),
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
    final drafts = ref.watch(draftCountProvider);
    final pending = ref.watch(pendingAssignmentsProvider);
    final draftsLabel = drafts == 1
        ? tr.dashboard.draftsOne
        : tr.dashboard.draftsMany(n: drafts);

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
              if (drafts == 0)
                Text(
                  tr.dashboard.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textMute,
                    ),
                    children: [
                      TextSpan(text: '${tr.dashboard.youHave} '),
                      TextSpan(
                        text: draftsLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: t.accentStrong,
                        ),
                      ),
                      TextSpan(
                          text:
                              ' · ${tr.dashboard.pendingItem(n: pending)}'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _SyncIndicator(
          state: _catalogState(ref.watch(mwbSyncProvider)),
          compact: isMobile,
        ),
        const _CloudSyncIndicator(),
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

/// Cloud sync surfaces ONLY when the user must know something: changes are
/// queued but there's no network, or sync hit an error/revocation. Healthy
/// sync is invisible (the whole point of 4b-3) — this renders nothing.
class _CloudSyncIndicator extends ConsumerWidget {
  const _CloudSyncIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final tr = context.t;
    final status = ref.watch(syncControllerProvider);
    const amber = Color(0xFFB9890F);

    final offlinePending =
        status.phase == SyncPhase.offline && status.pendingOutbox > 0;
    final (IconData icon, Color color, String tip)? shown = switch (status) {
      _ when offlinePending => (
          Icons.cloud_off_rounded,
          amber,
          tr.cloudSync.errorOffline,
        ),
      SyncStatus(phase: SyncPhase.error, :final errorKey) => (
          Icons.cloud_off_rounded,
          amber,
          errorKey == 'permissionDenied'
              ? tr.cloudSync.errorPermission
              : tr.cloudSync.errorUnknown,
        ),
      _ => null,
    };
    if (shown == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: shown.$3,
        child: Container(
          height: Dimens.hControl,
          width: Dimens.hControl,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(Dimens.rControl),
            border: Border.all(color: t.border),
          ),
          child: Icon(shown.$1, size: 17, color: shown.$2),
        ),
      ),
    );
  }
}

/// Hero "continue where you left off": the freshest draft, or nothing.
class _HeroSection extends ConsumerWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroProjectProvider);
    if (hero == null) return const SizedBox.shrink();
    final congregations = ref.watch(congregationsProvider);
    Congregation? congregation;
    for (final c in congregations) {
      if (c.id == hero.congregationId) congregation = c;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ContinueCard(
        project: hero,
        congregation: congregation,
        onContinue: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (_) => ProgramShell(project: hero)),
        ),
      ),
    );
  }
}

/// Congregation pills, only worth showing with more than one congregation.
class _CongregationFilter extends ConsumerWidget {
  const _CongregationFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final congregations = ref.watch(congregationsProvider);
    if (congregations.length < 2) return const SizedBox.shrink();
    final projects = ref.watch(projectsProvider);
    final filters = ref.watch(dashboardFiltersProvider);
    final notifier = ref.read(dashboardFiltersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
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
        ],
      ),
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

  /// A `project` item needs `admin` or ANY edit type (mirrors the rules).
  /// Checked against the congregation a new project would land in.
  bool _canCreateProjects(WidgetRef ref, List<Congregation> congregations) {
    final cid = congregations.firstOrNull?.id;
    if (cid == null) return true;
    final rights = ref.watch(rightsProvider(cid));
    return rights.admin || rights.editTypes.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final congregations = ref.watch(congregationsProvider);
    final projects = ref.watch(filteredProjectsProvider);
    final allProjects = ref.watch(projectsProvider);
    final filters = ref.watch(dashboardFiltersProvider);
    final notifier = ref.read(dashboardFiltersProvider.notifier);
    final porId = {for (final c in congregations) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              BlockTitle(
                  title: context.t.dashboard.projects,
                  count: allProjects.length),
              const SizedBox(width: 6),
              FilterPill(
                label: context.t.common.allMasculine,
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
          ),
        ),
        const _CongregationFilter(),
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
                    // A new project lands in the first congregation, the
                    // same one the modal defaults to. Null onTap renders the
                    // card disabled.
                    onTap: _canCreateProjects(ref, congregations)
                        ? () => showProjectModal(context)
                        : null,
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

  void _openProject(BuildContext context, WidgetRef ref, String? projectId) {
    if (projectId == null) return;
    Project? project;
    for (final p in ref.read(projectsProvider)) {
      if (p.id == projectId) project = p;
    }
    if (project == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ProgramShell(project: project)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final reminders = ref.watch(remindersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(
            title: context.t.dashboard.pending, count: reminders.length),
        if (reminders.isEmpty)
          Text(
            context.t.dashboard.allDone,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.textMute,
            ),
          ),
        for (var i = 0; i < reminders.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          ReminderCard(
            recordatorio: reminders[i],
            onCta: () =>
                _openProject(context, ref, reminders[i].projectId),
          ),
        ],
        if (reminders.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              variant: AppButtonVariant.ghost,
              label: context.t.dashboard.resolvePending,
              onPressed: () =>
                  _openProject(context, ref, reminders.first.projectId),
            ),
          ),
        ],
      ],
    );
  }
}

/// Skeleton dashboard while the streams warm up: the REAL cards rendered
/// with mock data inside a [Skeletonizer], so the placeholders can never
/// drift from the actual layout.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.stacked});

  final bool stacked;

  static final _project = Project(
    id: 'skeleton',
    name: 'Programa de ejemplo',
    congregationId: 'skeleton',
    weeks: const ['SEMANA UNO', 'SEMANA DOS', 'SEMANA TRES'],
    done: 12,
    total: 59,
    status: ProjectStatus.draft,
    editedLabel: 'hace 2 h',
    updatedAt: DateTime(2026),
    weekProgress: const [
      (label: 'SEMANA UNO', done: 14, total: 14),
      (label: 'SEMANA DOS', done: 5, total: 15),
      (label: 'SEMANA TRES', done: 0, total: 15),
    ],
  );

  static const _congregation = Congregation(
      id: 'skeleton', name: 'Congregación', number: '', color: 0xFF7A2230);

  static const _reminder = Reminder(
    id: 'skeleton',
    type: ReminderType.task,
    title: 'Asignaciones pendientes',
    meta: 'Semana · Proyecto',
    cta: 'Abrir proyecto',
  );

  @override
  Widget build(BuildContext context) {
    final projects = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(title: context.t.dashboard.projects, count: 0),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          const gap = 14.0;
          final cols = (c.maxWidth / 264).floor().clamp(1, 4);
          final colW = (c.maxWidth - (cols - 1) * gap) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < 4; i++)
                SizedBox(
                  width: colW,
                  child: ProjectCard(
                    project: _project,
                    congregation: _congregation,
                    onTap: () {},
                    onEdit: () {},
                  ),
                ),
            ],
          );
        }),
      ],
    );

    final reminders = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(title: context.t.dashboard.pending, count: 0),
        const ReminderCard(recordatorio: _reminder),
        const SizedBox(height: 9),
        const ReminderCard(recordatorio: _reminder),
      ],
    );

    return Skeletonizer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContinueCard(
            project: _project,
            congregation: _congregation,
            onContinue: () {},
          ),
          const SizedBox(height: 20),
          if (stacked) ...[
            projects,
            const SizedBox(height: 24),
            reminders,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: projects),
                const SizedBox(width: 22),
                SizedBox(width: 312, child: reminders),
              ],
            ),
        ],
      ),
    );
  }
}
