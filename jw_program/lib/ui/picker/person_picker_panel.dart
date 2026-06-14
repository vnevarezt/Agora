import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/participant.dart';
import '../../state/participants_provider.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import 'person_picker.dart';

/// Contenido del picker de personas, compartido entre el popover de
/// escritorio y el bottom sheet móvil. Devuelve el resultado haciendo pop
/// de su propia ruta con un [PickResult].
class PersonPickerPanel extends ConsumerStatefulWidget {
  const PersonPickerPanel({
    super.key,
    required this.roleLabel,
    required this.actual,
    required this.maxLength,
    this.mobile = false,
  });

  final String roleLabel;

  /// Nombre actualmente asignado ('' si el slot está vacío).
  final String actual;
  final int maxLength;
  final bool mobile;

  @override
  ConsumerState<PersonPickerPanel> createState() => _PersonPickerPanelState();
}

class _PersonPickerPanelState extends ConsumerState<PersonPickerPanel> {
  String _query = '';

  void _devolver(PickResult resultado) =>
      Navigator.of(context).pop(resultado);

  String get _busqueda => _query.trim();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final activos = ref.watch(activeParticipantsProvider);

    final clave = normalizeName(_busqueda);
    final filtrados = activos
        .where((h) => normalizeName(h.name).contains(clave))
        .toList();
    final recientes = _busqueda.isEmpty
        ? ref.watch(recentParticipantsProvider).take(4).toList()
        : const <Participant>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.mobile)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 9, bottom: 2),
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(Dimens.rPill),
              ),
            ),
          ),
        _cabecera(t),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(6),
            children: [
              if (widget.actual.isNotEmpty)
                _PersonRow(
                  name: 'Quitar asignación',
                  avatarVacio: true,
                  muted: true,
                  selected: true,
                  onTap: () => _devolver(const PickQuitar()),
                ),
              if (recientes.isNotEmpty) ...[
                _grupo(t, 'Recientes'),
                for (final h in recientes) _fila(h),
                _grupo(t, 'Todos'),
              ],
              for (final h in filtrados) _fila(h),
              if (filtrados.isEmpty && _busqueda.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 18),
                  child: Text(
                    'Sin resultados para “$_busqueda”.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textMute,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _pie(t),
      ],
    );
  }

  /// Fila de un participant: privilegio como etiqueta (solo anciano/siervo).
  Widget _fila(Participant h) {
    return _PersonRow(
      name: h.name,
      tag: h.role == Role.publisher ? null : h.role.etiqueta,
      selected: h.name == widget.actual,
      onTap: () => _devolver(PickNombre(h.name)),
    );
  }

  Widget _cabecera(AppTokens t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASIGNAR · ${widget.roleLabel.toUpperCase()}',
            style: AppText.label(size: 11, color: t.textMute),
          ),
          const SizedBox(height: 10),
          TextField(
            autofocus: true,
            maxLength: widget.maxLength,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: t.text),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Buscar participante…',
              prefixIcon: Icon(Icons.search, size: 16, color: t.textMute),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 36, minHeight: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grupo(AppTokens t, String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Text(titulo.toUpperCase(),
          style: AppText.label(color: t.textMute)),
    );
  }

  /// Pie "Añadir": asigna el name tecleado y lo suma al directorio en
  /// memoria (la gestión de personas llegará en otra fase).
  Widget _pie(AppTokens t) {
    final habilitado = _busqueda.isNotEmpty;
    final etiqueta =
        habilitado ? 'Añadir “$_busqueda”' : 'Añadir participante';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border2)),
      ),
      child: Pressable(
        onTap: habilitado
            ? () => _devolver(PickNombre(
                _busqueda.length > widget.maxLength
                    ? _busqueda.substring(0, widget.maxLength)
                    : _busqueda))
            : null,
        builder: (context, hovered, _) {
          final color = habilitado ? t.accentStrong : t.textMute;
          return AnimatedContainer(
            duration: Dimens.dFast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: hovered && habilitado
                  ? t.accentSoft
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Dimens.rControl),
            ),
            child: Row(
              children: [
                Icon(Icons.add, size: 17, color: color),
                const SizedBox(width: 9),
                Text(etiqueta,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.onTap,
    this.tag,
    this.selected = false,
    this.avatarVacio = false,
    this.muted = false,
  });

  final String name;
  final VoidCallback onTap;
  final String? tag;
  final bool selected;
  final bool avatarVacio;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? t.accentSoft
                : hovered
                    ? t.surface2
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimens.rControl),
          ),
          child: Row(
            children: [
              PersonAvatar(name: avatarVacio ? null : name),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: muted ? t.textMute : t.text,
                  ),
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 8),
                Text(
                  tag!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
              ],
              if (selected && !avatarVacio) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 18, color: t.accent),
              ],
            ],
          ),
        );
      },
    );
  }
}
