import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../i18n/strings.g.dart';
import '../../models/person.dart';
import '../../state/people_provider.dart';
import '../../state/restore_provider.dart';
import '../../state/sync_controller.dart';
import '../responsive.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/block_title.dart';
import '../widgets/filter_pill.dart';
import 'participant_card.dart';
import 'participant_modal.dart';
import '../theme/app_theme.dart';

/// Participants view (`PeopleView`): topbar, filters and a grid of cards
/// fed by `participantsProvider`. Lives inside the shell; shows a back
/// button when opened from the editor.
class ParticipantsView extends ConsumerStatefulWidget {
  const ParticipantsView({super.key});

  @override
  ConsumerState<ParticipantsView> createState() => _ParticipantsViewState();
}

class _ParticipantsViewState extends ConsumerState<ParticipantsView> {
  String _query = '';
  Role? _role;
  String? _congregation;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final pad = isMobile ? 16.0 : 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
          child: _topBar(context, isMobile),
        ),
        Expanded(
          // CustomScrollView rather than SingleChildScrollView: the grid below
          // is a sliver, so only the cards actually on screen are built. With
          // the old Column + Wrap every card in the congregation was
          // materialised, and rebuilt on every keystroke in the filter.
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _filters(context),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              ..._resultSlivers(context, pad),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, bool isMobile) {
    final t = context.tokens;
    return Row(
      children: [
        if (Navigator.of(context).canPop()) ...[
          AppIconButton(
            icon: Icons.arrow_back,
            bordered: true,
            tooltip: context.t.common.back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.participants.title,
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
                context.t.participants.subtitle,
                style: TextStyle(
                  fontSize: AppText.body,
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
          tooltip: context.t.common.reminders,
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        AppButton(
          icon: Icons.person_add_alt,
          label: isMobile ? null : context.t.participants.add,
          onPressed: () => showParticipantModal(context),
        ),
      ],
    );
  }

  Widget _filters(BuildContext context) {
    final t = context.tokens;
    final congregaciones = ref.watch(originCongregationsProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 280, child: _searchBox(context)),
        _separator(t),
        FilterPill(
          label: context.t.common.allFeminine,
          active: _congregation == null,
          onTap: () => setState(() => _congregation = null),
        ),
        for (final c in congregaciones)
          FilterPill(
            label: c,
            active: _congregation == c,
            onTap: () => setState(() => _congregation = c),
          ),
        _separator(t),
        FilterPill(
          label: context.t.common.allMasculine,
          active: _role == null,
          onTap: () => setState(() => _role = null),
        ),
        for (final p in Role.values)
          FilterPill(
            label: p.plural,
            active: _role == p,
            onTap: () => setState(() => _role = p),
          ),
      ],
    );
  }

  Widget _searchBox(BuildContext context) {
    final t = context.tokens;
    return TextField(
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(
            fontSize: AppText.body, fontWeight: FontWeight.w600, color: t.text),
        decoration: InputDecoration(
          hintText: context.t.common.searchParticipant,
          prefixIcon: Icon(Icons.search, size: 16, color: t.textMute),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 16),
        ),
      );
  }

  Widget _separator(AppTokens t) =>
      Container(width: 1, height: 22, color: t.border);

  /// Real cards with mock data inside a [Skeletonizer]: the placeholder
  /// can never drift from the actual card layout.
  Widget _skeleton() {
    final mock = Person(
      id: 'skeleton',
      congregationId: 'skeleton',
      firstName: '',
      lastName: '',
      displayName: 'Nombre de ejemplo',
      gender: Gender.male,
      privilege: Role.publisher,
      qualifications: const [],
      originCongregation: 'Congregación',
      active: true,
      notes: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    return Skeletonizer(
      child: _skeletonGrid([for (var i = 0; i < 6; i++) mock]),
    );
  }

  /// Title + either the empty state or the virtualised grid, as slivers so
  /// the grid can build lazily.
  List<Widget> _resultSlivers(BuildContext context, double pad) {
    final all = ref.watch(peopleProvider);
    final restore = ref.watch(initialRestoreProvider);
    final phase = ref.watch(syncControllerProvider).phase;
    final stalled = phase == SyncPhase.offline || phase == SyncPhase.error;
    // A fresh device restoring its data reads its empty local table as "no
    // people"; keep the skeleton until the pull lands (unless it stalled).
    if (ref.watch(peopleLoadingProvider) ||
        (restore != null && all.isEmpty && !stalled)) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, 120),
          sliver: SliverToBoxAdapter(child: _skeleton()),
        ),
      ];
    }
    final filtered = filterPeople(
      all,
      query: _query,
      privilege: _role,
      originCongregation: _congregation,
      includeInactive: true,
    );

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 0),
        sliver: SliverToBoxAdapter(
          child: BlockTitle(
              title: context.t.participants.title, count: filtered.length),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 120),
        sliver: filtered.isEmpty
            ? SliverToBoxAdapter(child: _empty(context, all.isEmpty))
            : _grid(context, filtered),
      ),
    ];
  }

  /// Virtualised card grid. The columns stay responsive the way the old Wrap
  /// was — one per 330 logical pixels, capped at four — and the tile extent
  /// comes from [participantCardHeight], which is exact because every card
  /// lays out at the same height.
  Widget _grid(BuildContext context, List<Person> participants) {
    const gap = 10.0;
    return SliverLayoutBuilder(
      builder: (context, c) {
        final cols = (c.crossAxisExtent / 330).floor().clamp(1, 4);
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: participantCardHeight(context),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final h = participants[i];
              return ParticipantCard(
                participant: h,
                onTap: () => showParticipantModal(context, original: h),
              );
            },
            childCount: participants.length,
          ),
        );
      },
    );
  }

  /// The skeleton keeps the old Wrap: it is a fixed six placeholders, so
  /// there is nothing to virtualise.
  Widget _skeletonGrid(List<Person> participants) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final cols = (c.maxWidth / 330).floor().clamp(1, 4);
        final colW = (c.maxWidth - (cols - 1) * gap) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final h in participants)
              SizedBox(
                width: colW,
                child: ParticipantCard(participant: h, onTap: () {}),
              ),
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context, bool noData) {
    return EmptyState(
      icon: Icons.people_outline,
      message: noData
          ? context.t.participants.emptyNoData
          : context.t.participants.emptyNoResults,
    );
  }

}
