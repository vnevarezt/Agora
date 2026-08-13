import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../models/congregation.dart';
import '../../models/project.dart';
import '../../state/app_settings.dart';
import '../../state/dashboard_provider.dart';
import '../../state/preview_provider.dart';
import '../../state/program_form.dart';
import '../../state/progress_provider.dart';
import '../../state/ui_state.dart';
import '../../state/weeks_provider.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_switch.dart';
import '../widgets/export_actions.dart';
import '../widgets/export_panel.dart';
import '../widgets/motion.dart';
import '../widgets/progress_meter.dart';
import '../widgets/progress_ring.dart';

/// Editor bar (`.projbar`): project identity, progress, week selector and
/// export.
class ProjectBar extends ConsumerWidget {
  const ProjectBar({super.key, this.project});

  final Project? project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? Space.s12 : 16, vertical: isMobile ? Space.s8 : Space.s10),
        child: isMobile ? _mobile(context, ref, t) : _desktop(context, ref, t),
      ),
    );
  }

  Widget _desktop(BuildContext context, WidgetRef ref, AppTokens t) {
    final progress = ref.watch(projectProgressProvider);
    return Row(
      children: [
        _back(context),
        const SizedBox(width: 14),
        // Identity: what document this is. No stats here — they live in the
        // work-state cluster on the right, next to the week that owns them.
        Flexible(child: _ProjectId(project: project)),
        const Spacer(),
        // Work state: overall progress, current week, and the action that
        // ships it — grouped because they're all "how's it going".
        ProgressRing(
          done: progress.done,
          total: progress.total,
          showLabel: true,
        ),
        const SizedBox(width: 20),
        const _WeekNav(),
        const SizedBox(width: Space.s12),
        const _ExportMenu(),
      ],
    );
  }

  Widget _mobile(BuildContext context, WidgetRef ref, AppTokens t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _back(context),
            const SizedBox(width: Space.s10),
            Expanded(child: _ProjectId(project: project)),
            const SizedBox(width: Space.s10),
            const _ExportMenu(compact: true),
          ],
        ),
        const SizedBox(height: Space.s8),
        const _WeekNav(expand: true),
      ],
    );
  }

  Widget _back(BuildContext context) => AppIconButton(
        icon: Icons.arrow_back,
        bordered: true,
        tooltip: context.t.common.backToPanel,
        onPressed: () => Navigator.of(context).maybePop(),
      );
}

/// Project identity: name + congregation + week count.
class _ProjectId extends ConsumerWidget {
  const _ProjectId({this.project});

  final Project? project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final congregations = ref.watch(congregationsProvider);

    final Congregation? cong = project == null
        ? null
        : congregations.where((c) => c.id == project!.congregationId).firstOrNull;
    final name = project?.name ?? context.t.app.defaultProjectName;
    final congName =
        cong?.name ?? (project == null ? ref.watch(formProvider).congregationId : '');
    final congColor = cong == null ? t.accent : Color(cong.color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppText.title,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.34,
            color: t.text,
          ),
        ),
        const SizedBox(height: 2),
        // Congregation only — the week count already lives in the "Week
        // X/N" selector; repeating it here was the same fact twice.
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: congColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                congName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppText.small,
                  fontWeight: FontWeight.w600,
                  color: t.textMute,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Week selector (`.week-nav`): arrows + central button with a "Go to
/// week" popover.
class _WeekNav extends ConsumerStatefulWidget {
  const _WeekNav({this.expand = false});

  final bool expand;

  @override
  ConsumerState<_WeekNav> createState() => _WeekNavState();
}

class _WeekNavState extends ConsumerState<_WeekNav> {
  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final weeks = ref.watch(weeksProvider).asData?.value ?? const [];
    final idx = ref.watch(formProvider.select((f) => f.weekIndex));
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(formProvider.notifier);

    final n = weeks.length;
    final active = n == 0 ? 0 : idx.clamp(0, n - 1);
    final date = n == 0 ? '—' : weeks[active].date;
    final done = progress.done == progress.total && progress.total > 0;

    void go(int d) {
      if (n == 0) return;
      notifier.selectWeek((active + d).clamp(0, n - 1));
    }

    final current = MenuAnchor(
      controller: _menu,
      // MenuAnchor's open/close animation is opt-in and defaults to off;
      // MediaQuery's reduce-motion flag isn't wired to it internally, so it
      // needs the same manual gate every other animation in this app goes
      // through.
      animated: !MediaQuery.disableAnimationsOf(context),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      menuChildren: [
        _WeekMenu(
          weeks: weeks,
          active: active,
          onPick: (i) {
            notifier.selectWeek(i);
            _menu.close();
          },
        ),
      ],
      builder: (context, controller, _) {
        return Pressable(
          onTap: n == 0 ? null : () => controller.isOpen
              ? controller.close()
              : controller.open(),
          builder: (context, hovered, _) {
            final open = controller.isOpen;
            return Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: Space.s12),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(Dimens.rControl),
                border: Border.all(
                  color: open ? t.accent : (hovered ? t.textMute : t.border),
                ),
                boxShadow: open
                    ? [
                        BoxShadow(
                            color: t.accentSoft,
                            blurRadius: 0,
                            spreadRadius: 3),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Expanded(
                    flex: widget.expand ? 1 : 0,
                    // Keyed by the active week so stepping through with the
                    // arrows or the dropdown crossfades the date instead of
                    // snapping to it.
                    child: FadeThroughSwitcher(
                      duration: Motion.fast,
                      child: Column(
                        key: ValueKey(active),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: context.t.projectBar
                                  .weekN(n: n == 0 ? '—' : active + 1),
                              style: TextStyle(
                                fontSize: AppText.micro,
                                fontWeight: FontWeight.w700,
                                color: t.textMute,
                              ),
                              children: [
                                TextSpan(
                                  text: ' / $n',
                                  style: TextStyle(
                                      color:
                                          t.textMute.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.mono(
                                size: 14,
                                weight: FontWeight.w800,
                                color: t.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FadeThroughSwitcher(
                    duration: Motion.fast,
                    child: _PctBadge(
                      key: ValueKey(active),
                      done: done,
                      label: '${progress.done}/${progress.total}',
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: Motion.of(context, Motion.instant),
                    child: Icon(Icons.expand_more, size: AppIcon.control, color: t.textMute),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _Arrow(
            icon: Icons.chevron_left,
            label: context.t.projectBar.prevWeek,
            onTap: active == 0 ? null : () => go(-1)),
        const SizedBox(width: Space.s6),
        widget.expand ? Expanded(child: current) : current,
        const SizedBox(width: Space.s6),
        _Arrow(
            icon: Icons.chevron_right,
            label: context.t.projectBar.nextWeek,
            onTap: (n == 0 || active >= n - 1) ? null : () => go(1)),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;

  /// Announced name: the arrow renders a glyph and nothing else.
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      tooltip: label,
      semanticLabel: label,
      builder: (context, hovered, _) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered && enabled ? t.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimens.rControl),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? t.textDim : t.textMute.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _PctBadge extends StatelessWidget {
  const _PctBadge({super.key, required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: done
          ? const EdgeInsets.all(Space.s4)
          : const EdgeInsets.symmetric(horizontal: Space.s8, vertical: Space.s4),
      decoration: BoxDecoration(
        color: done ? t.accent : t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rPill),
        border: done ? null : Border.all(color: t.border2),
      ),
      child: done
          ? Icon(Icons.check, size: AppIcon.inline, color: t.accentInk)
          : Text(
              label,
              style: AppText.mono(
                  size: 11, weight: FontWeight.w700, color: t.textDim),
            ),
    );
  }
}

/// "Go to week" popover content (`.week-menu`) + Auxiliary Room toggle.
class _WeekMenu extends ConsumerWidget {
  const _WeekMenu({
    required this.weeks,
    required this.active,
    required this.onPick,
  });

  final List weeks;
  final int active;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final auxRoom = ref.watch(formProvider.select((f) => f.auxRoom));
    final twoPerSheet = ref.watch(twoPerSheetProvider);
    final coByWeek =
        ref.watch(formProvider.select((f) => f.circuitOverseerByWeek));
    final progressList = ref.watch(progressPerWeekProvider);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: Space.s6),
      padding: const EdgeInsets.all(Space.s6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
        boxShadow: Elevation.popover,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s8, Space.s6, Space.s8, Space.s8),
            child: Text(
              context.t.projectBar.goToWeek.toUpperCase(),
              style: TextStyle(
                fontSize: AppText.micro,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: t.textMute,
              ),
            ),
          ),
          for (var i = 0; i < weeks.length; i++)
            Builder(builder: (context) {
              final pr = i < progressList.length
                  ? progressList[i]
                  : (done: 0, total: 0);
              final completo = pr.total > 0 && pr.done == pr.total;
              return Pressable(
                onTap: () => onPick(i),
                builder: (context, hovered, _) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Space.s10, vertical: Space.s10),
                  decoration: BoxDecoration(
                    color: i == active
                        ? t.accentTint
                        : (hovered ? t.surface2 : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          context.t.projectBar.weekShort(n: i + 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: AppText.micro,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: i == active ? t.accentStrong : t.textMute,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(
                          weeks[i].date as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mono(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: t.text),
                        ),
                      ),
                      const SizedBox(width: Space.s8),
                      Expanded(
                        child: ProgressMeter(
                          value: pr.total == 0 ? 0 : pr.done / pr.total,
                          height: 4,
                        ),
                      ),
                      const SizedBox(width: Space.s8),
                      SizedBox(
                        width: 30,
                        child: completo
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: t.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check,
                                      size: AppIcon.inline, color: t.accentInk),
                                ),
                              )
                            : Text(
                                '${pr.done}/${pr.total}',
                                textAlign: TextAlign.right,
                                style: AppText.mono(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: t.textMute),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s4),
            color: t.border2,
          ),
          _AuxToggle(
            auxRoom: auxRoom,
            onChanged: (v) => ref.read(formProvider.notifier).setAuxRoom(v),
          ),
          _TwoPerSheetToggle(
            twoPerSheet: twoPerSheet,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setTwoPerSheet(v),
          ),
          _CircuitOverseerToggle(
            active: coByWeek[active] ?? false,
            onChanged: (v) =>
                ref.read(formProvider.notifier).setCircuitOverseer(active, v),
          ),
        ],
      ),
    );
  }
}

class _AuxToggle extends StatelessWidget {
  const _AuxToggle({required this.auxRoom, required this.onChanged});

  final bool auxRoom;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: () => onChanged(!auxRoom),
      builder: (context, hovered, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s10, vertical: Space.s10),
        decoration: BoxDecoration(
          color: hovered ? t.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.apartment_outlined,
                size: AppIcon.control, color: auxRoom ? t.accentStrong : t.textMute),
            const SizedBox(width: Space.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t.projectBar.auxRoom,
                      style: TextStyle(
                          fontSize: AppText.body,
                          fontWeight: FontWeight.w700,
                          color: t.text)),
                  Text(context.t.projectBar.auxRoomDesc,
                      style: TextStyle(
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w600,
                          color: t.textMute)),
                ],
              ),
            ),
            AppSwitch(
              value: auxRoom,
              onChanged: onChanged,
              scale: 0.8,
              interactive: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Two programs per sheet" toggle (below [_AuxToggle]). A device print
/// preference: two weeks side by side on one landscape sheet. Mirrors
/// [_AuxToggle].
class _TwoPerSheetToggle extends StatelessWidget {
  const _TwoPerSheetToggle({required this.twoPerSheet, required this.onChanged});

  final bool twoPerSheet;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: () => onChanged(!twoPerSheet),
      builder: (context, hovered, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s10, vertical: Space.s10),
        decoration: BoxDecoration(
          color: hovered ? t.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.splitscreen_outlined,
                size: AppIcon.control, color: twoPerSheet ? t.accentStrong : t.textMute),
            const SizedBox(width: Space.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t.projectBar.twoPerSheet,
                      style: TextStyle(
                          fontSize: AppText.body,
                          fontWeight: FontWeight.w700,
                          color: t.text)),
                  Text(context.t.projectBar.twoPerSheetDesc,
                      style: TextStyle(
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w600,
                          color: t.textMute)),
                ],
              ),
            ),
            AppSwitch(
              value: twoPerSheet,
              onChanged: onChanged,
              scale: 0.8,
              interactive: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Circuit overseer visit" toggle for the active week (footer of the week
/// menu, below [_AuxToggle]). When on, the Congregation Bible Study is replaced
/// by the overseer's talk. Mirrors [_AuxToggle].
class _CircuitOverseerToggle extends StatelessWidget {
  const _CircuitOverseerToggle({required this.active, required this.onChanged});

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: () => onChanged(!active),
      builder: (context, hovered, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s10, vertical: Space.s10),
        decoration: BoxDecoration(
          color: hovered ? t.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.record_voice_over_outlined,
                size: AppIcon.control, color: active ? t.accentStrong : t.textMute),
            const SizedBox(width: Space.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t.projectBar.circuitOverseer,
                      style: TextStyle(
                          fontSize: AppText.body,
                          fontWeight: FontWeight.w700,
                          color: t.text)),
                  Text(context.t.projectBar.circuitOverseerDesc,
                      style: TextStyle(
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w600,
                          color: t.textMute)),
                ],
              ),
            ),
            AppSwitch(
              value: active,
              onChanged: onChanged,
              scale: 0.8,
              interactive: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Export button with a menu (`.menu`): the current sheet (real, PDF or image,
/// save or share) plus project and slips (UI for now).
class _ExportMenu extends ConsumerWidget {
  const _ExportMenu({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(exportBusyProvider);
    final haySemana = ref.watch(scheduleProvider) != null;
    final twoUp = ref.watch(twoPerSheetProvider);
    final menu = MenuController();

    return MenuAnchor(
      controller: menu,
      animated: !MediaQuery.disableAnimationsOf(context),
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      menuChildren: [
        _ExportCard(
          haySemana: haySemana,
          twoPerSheet: twoUp,
          onExport: (format, action, origin) {
            menu.close();
            runExport(context, ref,
                format: format, action: action, shareOrigin: origin);
          },
        ),
      ],
      builder: (context, controller, _) {
        return AppButton(
          icon: Icons.ios_share,
          label: compact ? null : context.t.export.export,
          busy: busy,
          onPressed: busy
              ? null
              : () => controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.haySemana,
    required this.twoPerSheet,
    required this.onExport,
  });

  final bool haySemana;
  final bool twoPerSheet;
  final void Function(ExportFormat, ExportAction, Rect?) onExport;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    return Container(
      width: 300,
      margin: const EdgeInsets.only(top: Space.s6),
      padding: const EdgeInsets.all(Space.s6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
        boxShadow: Elevation.popover,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s12, Space.s8, Space.s12, Space.s8),
            child: Row(
              children: [
                Icon(
                    twoPerSheet
                        ? Icons.splitscreen_outlined
                        : Icons.description_outlined,
                    size: AppIcon.control,
                    color: t.textMute),
                const SizedBox(width: Space.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          twoPerSheet
                              ? tr.export.currentSheet
                              : tr.export.currentWeek,
                          style: TextStyle(
                              fontSize: AppText.body,
                              fontWeight: FontWeight.w700,
                              color: t.text)),
                      Text(
                          twoPerSheet
                              ? tr.export.currentSheetSub
                              : tr.export.currentWeekSub,
                          style: TextStyle(
                              fontSize: AppText.caption,
                              fontWeight: FontWeight.w600,
                              color: t.textMute)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s8, 0, Space.s8, Space.s4),
            child: ExportPanel(enabled: haySemana, onExport: onExport),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s4),
            color: t.border2,
          ),
          _ExportItem(
            icon: Icons.layers_outlined,
            title: tr.export.fullProject,
            sub: tr.export.fullProjectSub,
            onTap: null, // próximamente
          ),
          _ExportItem(
            icon: Icons.list_alt_outlined,
            title: tr.export.sheets,
            sub: tr.export.sheetsSub,
            onTap: null, // próximamente
          ),
        ],
      ),
    );
  }
}

class _ExportItem extends StatelessWidget {
  const _ExportItem({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.s12, vertical: Space.s10),
          decoration: BoxDecoration(
            color: hovered && enabled ? t.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: AppIcon.control, color: t.textMute),
              const SizedBox(width: Space.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: AppText.body,
                            fontWeight: FontWeight.w700,
                            color: t.text)),
                    Text(sub,
                        style: TextStyle(
                            fontSize: AppText.caption,
                            fontWeight: FontWeight.w600,
                            color: t.textMute)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
