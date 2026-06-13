import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/hermano.dart';
import '../../state/hermanos_provider.dart';
import '../responsive.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/block_title.dart';
import '../widgets/filter_pill.dart';
import 'persona_card.dart';
import 'persona_modal.dart';

/// Vista de Hermanos (`PeopleView` del mock): topbar, filtros y cuadrícula de
/// tarjetas alimentada por la BD (`hermanosTodosProvider`). Vive dentro del
/// shell; al abrirse desde el editor muestra botón de volver.
class HermanosView extends ConsumerStatefulWidget {
  const HermanosView({super.key});

  @override
  ConsumerState<HermanosView> createState() => _HermanosViewState();
}

class _HermanosViewState extends ConsumerState<HermanosView> {
  String _query = '';
  Privilegio? _privilegio;
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
                'Hermanos',
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
          label: isMobile ? null : 'Añadir hermano',
          onPressed: () => mostrarPersonaModal(context),
        ),
      ],
    );
  }

  Widget _filtros(BuildContext context) {
    final t = context.tokens;
    final congregaciones = ref.watch(congregacionesProvider);

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
        for (final p in Privilegio.values)
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
          hintText: 'Buscar hermano…',
          prefixIcon: Icon(Icons.search, size: 16, color: t.textMute),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 16),
        ),
      );

  Widget _separador(AppTokens t) =>
      Container(width: 1, height: 22, color: t.border);

  Widget _resultado(BuildContext context) {
    final t = context.tokens;
    final asyncTodos = ref.watch(hermanosTodosProvider);

    return asyncTodos.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _error(t, e),
      data: (todos) {
        final filtrados = filtrarHermanos(
          todos,
          query: _query,
          privilegio: _privilegio,
          congregacion: _congregacion,
          incluirInactivos: true,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlockTitle(title: 'Hermanos', count: filtrados.length),
            if (filtrados.isEmpty)
              _vacio(t, todos.isEmpty)
            else
              _grid(filtrados),
          ],
        );
      },
    );
  }

  Widget _grid(List<Hermano> hermanos) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final cols = (c.maxWidth / 330).floor().clamp(1, 4);
        final colW = (c.maxWidth - (cols - 1) * gap) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final h in hermanos)
              SizedBox(
                width: colW,
                child: PersonaCard(
                  hermano: h,
                  onTap: () => mostrarPersonaModal(context, original: h),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _vacio(AppTokens t, bool sinDatos) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 40, color: t.textMute),
            const SizedBox(height: 12),
            Text(
              sinDatos
                  ? 'Aún no hay hermanos.\nAñade el primero con "Añadir hermano".'
                  : 'Sin resultados con esos filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: t.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(AppTokens t, Object e) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          'No se pudo abrir la base de datos local.\n$e',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}
