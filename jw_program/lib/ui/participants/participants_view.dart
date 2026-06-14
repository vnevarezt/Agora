import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/participant.dart';
import '../../state/participants_provider.dart';
import '../responsive.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/block_title.dart';
import '../widgets/filter_pill.dart';
import 'participant_card.dart';
import 'participant_modal.dart';

/// Vista de Participants (`PeopleView` del mock): topbar, filters y cuadrícula de
/// tarjetas alimentada por la BD (`participantsProvider`). Vive dentro del
/// shell; al abrirse desde el editor muestra botón de volver.
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
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filters(context),
                const SizedBox(height: 18),
                _result(context),
              ],
            ),
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
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participantes',
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
                'Participantes de las asignaciones',
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
          icon: Icons.person_add_alt,
          label: isMobile ? null : 'Añadir participante',
          onPressed: () => showParticipantModal(context),
        ),
      ],
    );
  }

  Widget _filters(BuildContext context) {
    final t = context.tokens;
    final congregaciones = ref.watch(participantCongregationsProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 280, child: _searchBox(t)),
        _separator(t),
        FilterPill(
          label: 'Todas',
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
          label: 'Todos',
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

  Widget _searchBox(AppTokens t) => TextField(
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: t.text),
        decoration: InputDecoration(
          hintText: 'Buscar participante…',
          prefixIcon: Icon(Icons.search, size: 16, color: t.textMute),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 16),
        ),
      );

  Widget _separator(AppTokens t) =>
      Container(width: 1, height: 22, color: t.border);

  Widget _result(BuildContext context) {
    final t = context.tokens;
    final all = ref.watch(participantsProvider);
    final filtered = filterParticipants(
      all,
      query: _query,
      role: _role,
      congregation: _congregation,
      includeInactive: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(title: 'Participantes', count: filtered.length),
        if (filtered.isEmpty)
          _empty(t, all.isEmpty)
        else
          _grid(filtered),
      ],
    );
  }

  Widget _grid(List<Participant> participants) {
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
                child: ParticipantCard(
                  participant: h,
                  onTap: () => showParticipantModal(context, original: h),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _empty(AppTokens t, bool noData) {
    return EmptyState(
      icon: Icons.people_outline,
      message: noData
          ? 'Aún no hay participantes.\nAñade el primero con "Añadir participante".'
          : 'Sin resultados con esos filters.',
    );
  }

}
