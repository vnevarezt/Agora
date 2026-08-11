import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../i18n/strings.g.dart';
import '../../models/program_row.dart';
import '../../models/week.dart';
import '../../state/assignment_ops.dart';
import '../../state/program_form.dart';
import '../../state/weeks_provider.dart';
import '../responsive.dart';
import '../theme/dimens.dart';
import '../widgets/app_button.dart';
import '../widgets/section_header.dart';
import 'part_card.dart';
import 'part_presentation.dart';

/// Assignments column: chairman card + the program's four sections. Empty
/// state with a download CTA when there's no notebook.
class WorkspacePanel extends ConsumerWidget {
  const WorkspacePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sched = ref.watch(scheduleProvider);
    if (sched == null) {
      // Weeks still loading (project snapshots / manual download): skeleton
      // part cards instead of flashing the download empty-state.
      if (ref.watch(weeksProvider).isLoading) {
        return const _WorkspaceSkeleton();
      }
      return const _EmptyState();
    }

    final aux = ref.watch(formProvider.select((f) => f.auxRoom));
    final isMobile = context.isMobile;
    final side = isMobile ? 14.0 : 18.0;
    final tr = context.t;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, side, side, 22),
          sliver: SliverToBoxAdapter(child: PartCard(view: chairmanView(tr))),
        ),
        for (final section in [
          (title: tr.workspace.sectionOpening, dot: null, rows: sched.opening),
          (
            title: tr.workspace.sectionTreasures,
            dot: kSectionColors[Section.treasures],
            rows: sched.treasures,
          ),
          (
            title: tr.workspace.sectionMinistry,
            dot: kSectionColors[Section.ministry],
            rows: sched.ministry,
          ),
          (
            title: tr.workspace.sectionChristianLife,
            dot: kSectionColors[Section.christianLife],
            rows: sched.christianLife,
          ),
        ]) ...[
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: side),
            sliver: SliverToBoxAdapter(
              child: _SectionCounter(
                  title: section.title,
                  dotColor: section.dot,
                  rows: section.rows,
                  aux: aux),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(side, 0, side, 22),
            sliver: SliverList.builder(
              itemCount: section.rows.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: PartCard(
                    view: mapRow(section.rows[i], auxActive: aux, tr: tr)),
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: isMobile ? 128 : 98)),
      ],
    );
  }
}

/// The section's assigned/total counter.
///
/// Its own widget with a `select` so a name landing in one section rebuilds
/// that header alone: watching the form from the block rebuilt every card of
/// every section, which also defeated the per-slot `select` in [SlotField].
class _SectionCounter extends ConsumerWidget {
  const _SectionCounter({
    required this.title,
    required this.dotColor,
    required this.rows,
    required this.aux,
  });

  final String title;
  final Color? dotColor;
  final List<ProgramRow> rows;
  final bool aux;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(formProvider.select((f) {
      var total = 0;
      var done = 0;
      for (final row in rows) {
        total += row.slots;
        done += filledNames(f.main[row.id], row.slots);
        if (aux && row.auxSlots > 0) {
          total += row.auxSlots;
          done += filledNames(f.auxiliary[row.id], row.auxSlots);
        }
      }
      return (done: done, total: total);
    }));

    return SectionHeader(
        title: title,
        dotColor: dotColor,
        done: progress.done,
        total: progress.total);
  }
}

/// Real part cards (chairman layout) skeletonized while the week loads.
class _WorkspaceSkeleton extends StatelessWidget {
  const _WorkspaceSkeleton();

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final side = isMobile ? 14.0 : 18.0;
    return Skeletonizer(
      child: ListView(
        padding: EdgeInsets.fromLTRB(side, side, side, 120),
        children: [
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            PartCard(view: chairmanView(context.t)),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeks = ref.watch(weeksProvider);
    final issue = ref.watch(formProvider.select((f) => f.issue));

    return EmptyState(
      icon: Icons.description_outlined,
      title: context.t.workspace.emptyTitle,
      message: context.t.workspace.emptyMessage,
      action: AppButton(
        icon: Icons.file_download_outlined,
        label: context.t.workspace.searchNotebook(issue: issue),
        busy: weeks.isLoading,
        onPressed: weeks.isLoading
            ? null
            : () => ref
                .read(weeksProvider.notifier)
                .load(ref.read(formProvider).issue),
      ),
      error: weeks.hasError ? '${weeks.error}' : null,
    );
  }
}
