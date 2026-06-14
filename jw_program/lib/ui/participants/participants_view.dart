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

/// Vista de Participants (`PeopleView` del mock): topbar, filtros y cuadrícula de
/// tarjetas alimentada por la BD (`participantsProvider`). Vive dentro del
/// shell; al abrirse desde el editor muestra botón de volver.
class ParticipantsView extends ConsumerStatefulWidget {
  const ParticipantsView({super.key});

  @override
  ConsumerState<ParticipantsView> createState() => _ParticipantsViewState();
}

class _ParticipantsViewState extends ConsumerState<ParticipantsView> {
  String _query = '';
  Role? _privilegio;
  String? _congregacion;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final pad = isMobile ? 16.0 : 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
          child: _topbar(context, isMobile),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filtros(context),
                const SizedBox(height: 18),
                _resultado(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topbar(BuildContext context, bool isMobile) {
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
                'Participants',
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

  Widget _filtros(BuildContext context) {
    final t = context.tokens;
    final congregaciones = ref.watch(participantCongregationsProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 280, child: _buscador(t)),
        _separador(t),
        FilterPill(
          label: 'Todas',
          active: _congregacion == null,
          onTap: () => setState(() => _congregacion = null),
        ),
        for (final c in congregaciones)
          FilterPill(
            label: c,
            active: _congregacion == c,
            onTap: () => setState(() => _congregacion = c),
          ),
        _separador(t),
        FilterPill(
          label: 'Todos',
          active: _privilegio == null,
          onTap: () => setState(() => _privilegio = null),
        ),
        for (final p in Role.values)
          FilterPill(
            label: p.plural,
            active: _privilegio == p,
            onTap: () => setState(() => _privilegio = p),
          ),
      ],
    );
  }

  Widget _buscador(AppTokens t) => TextField(
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

  Widget _separador(AppTokens t) =>
      Container(width: 1, height: 22, color: t.border);

  Widget _resultado(BuildContext context) {
    final t = context.tokens;
    final todos = ref.watch(participantsProvider);
    final filtrados = filterParticipants(
      todos,
      query: _query,
      role: _privilegio,
      congregation: _congregacion,
      incluirInactivos: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockTitle(title: 'Participants', count: filtrados.length),
        if (filtrados.isEmpty)
          _vacio(t, todos.isEmpty)
        else
          _grid(filtrados),
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

  Widget _vacio(AppTokens t, bool sinDatos) {
    return EmptyState(
      icon: Icons.people_outline,
      message: sinDatos
          ? 'Aún no hay participantes.\nAñade el primero con "Añadir participante".'
          : 'Sin resultados con esos filtros.',
    );
  }

}
