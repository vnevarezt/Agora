import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/congregacion.dart';
import '../../models/cuaderno.dart';
import '../../models/proyecto.dart';
import '../../state/dashboard_provider.dart';
import '../responsive.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/danger_button.dart';
import '../widgets/labeled_field.dart';

/// Abre el modal de creación/edición de proyecto. [proyecto] null = alta nueva.
Future<void> mostrarProyectoModal(BuildContext context, {Proyecto? proyecto}) {
  return showAppModal<void>(
    context,
    builder: (ctx, sheet, close) =>
        ProjectModal(original: proyecto, sheet: sheet, onClose: close),
  );
}

/// Contenido del modal de proyecto. Lee/escribe vía Riverpod, como `PersonaForm`.
class ProjectModal extends ConsumerStatefulWidget {
  const ProjectModal({
    super.key,
    this.original,
    required this.onClose,
    this.sheet = false,
  });

  /// null = nuevo proyecto.
  final Proyecto? original;
  final VoidCallback onClose;

  /// true cuando se presenta como bottom sheet (móvil).
  final bool sheet;

  @override
  ConsumerState<ProjectModal> createState() => _ProjectModalState();
}

class _ProjectModalState extends ConsumerState<ProjectModal> {
  late String _nombre = widget.original?.nombre ?? '';
  late String _congId;
  late String _cuadernoId;
  late List<String> _semanas = List.of(widget.original?.semanas ?? const []);

  bool get _esNuevo => widget.original == null;

  @override
  void initState() {
    super.initState();
    final congs = ref.read(congregacionesDashProvider);
    final cuadernos = ref.read(cuadernosProvider);
    _congId = widget.original?.congregacionId ??
        (congs.isNotEmpty ? congs.first.id : '');
    _cuadernoId = cuadernos.isNotEmpty ? cuadernos.first.id : '';
  }

  /// Alterna una semana del cuaderno, manteniendo el orden del cuaderno y las
  /// semanas "extra" (de otros cuadernos) al final. Réplica de `toggleWeek`.
  void _toggle(String w, Cuaderno cuaderno) {
    setState(() {
      if (_semanas.contains(w)) {
        _semanas = _semanas.where((x) => x != w).toList();
      } else {
        final extra =
            _semanas.where((x) => !cuaderno.semanas.contains(x)).toList();
        _semanas = [
          ...cuaderno.semanas.where((x) => _semanas.contains(x) || x == w),
          ...extra,
        ];
      }
    });
  }

  void _quitar(String w) =>
      setState(() => _semanas = _semanas.where((x) => x != w).toList());

  /// Nombre por defecto cuando el campo está vacío.
  String _autoName(Cuaderno cuaderno) {
    if (_nombre.trim().isNotEmpty) return _nombre.trim();
    if (_semanas.isEmpty) return '';
    final base = cuaderno.label.split('–').first.trim();
    final n = _semanas.length;
    return '$base · $n ${n == 1 ? 'semana' : 'semanas'}';
  }

  void _guardar(Cuaderno cuaderno) {
    final nombre = _autoName(cuaderno);
    final notifier = ref.read(proyectosProvider.notifier);
    if (_esNuevo) {
      notifier.crear(
          nombre: nombre, congregacionId: _congId, semanas: _semanas);
    } else {
      notifier.actualizar(widget.original!.id,
          nombre: nombre, congregacionId: _congId, semanas: _semanas);
    }
    widget.onClose();
  }

  Future<void> _eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar proyecto?'),
        content: Text(
          'Se eliminará "${widget.original!.nombre}". '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    ref.read(proyectosProvider.notifier).eliminar(widget.original!.id);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isMobile = context.isMobile;
    final congs = ref.watch(congregacionesDashProvider);
    final cuadernos = ref.watch(cuadernosProvider);
    final cuaderno =
        cuadernos.firstWhere((c) => c.id == _cuadernoId, orElse: () => cuadernos.first);
    final extra =
        _semanas.where((x) => !cuaderno.semanas.contains(x)).toList();
    final autoName = _autoName(cuaderno);

    final card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.sheet) _handle(t),
        _header(t),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: _cuerpo(t, isMobile, congs, cuadernos, cuaderno, extra, autoName),
          ),
        ),
        _footer(t, isMobile, cuaderno),
      ],
    );

    if (widget.sheet) return card;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 12)),
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: card,
    );
  }

  Widget _handle(AppTokens t) => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      );

  Widget _header(AppTokens t) => Padding(
        padding: EdgeInsets.fromLTRB(18, widget.sheet ? 12 : 18, 12, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _esNuevo ? 'Nuevo proyecto' : 'Editar proyecto',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Un proyecto agrupa las semanas que quieras: un mes '
                    'completo o una sola semana.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: t.textMute,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppIconButton(
              icon: Icons.close,
              bordered: true,
              tooltip: 'Cerrar',
              size: 32,
              onPressed: widget.onClose,
            ),
          ],
        ),
      );

  Widget _cuerpo(
    AppTokens t,
    bool isMobile,
    List<Congregacion> congs,
    List<Cuaderno> cuadernos,
    Cuaderno cuaderno,
    List<String> extra,
    String autoName,
  ) {
    final congField = LabeledField(
      label: 'Congregación',
      child: AppDropdown<String>(
        value: _congId,
        items: [for (final c in congs) c.id],
        itemLabel: (id) => congs.firstWhere((c) => c.id == id).nombre,
        onChanged: (v) => setState(() => _congId = v),
      ),
    );
    final cuadernoField = LabeledField(
      label: 'Cuaderno',
      child: AppDropdown<String>(
        value: _cuadernoId,
        items: [for (final c in cuadernos) c.id],
        itemLabel: (id) => cuadernos.firstWhere((c) => c.id == id).label,
        onChanged: (v) => setState(() => _cuadernoId = v),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMobile) ...[
          congField,
          const SizedBox(height: 14),
          cuadernoField,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: congField),
              const SizedBox(width: 16),
              Expanded(child: cuadernoField),
            ],
          ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Semanas a incluir · ${_semanas.length} '
              '${_semanas.length == 1 ? 'seleccionada' : 'seleccionadas'}',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final w in cuaderno.semanas)
                _WeekToggle(
                  label: w,
                  active: _semanas.contains(w),
                  onTap: () => _toggle(w, cuaderno),
                ),
              for (final w in extra)
                _WeekToggle(
                  label: w,
                  active: true,
                  extra: true,
                  onTap: () => _quitar(w),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Nombre del proyecto',
          child: BoundTextField(
            initial: _nombre,
            hint: autoName.isNotEmpty ? autoName : 'Ej. Mayo 2026',
            onChanged: (v) => setState(() => _nombre = v),
          ),
        ),
      ],
    );
  }

  Widget _footer(AppTokens t, bool isMobile, Cuaderno cuaderno) {
    final puedeGuardar = _semanas.isNotEmpty;
    final etiquetaPrimary = _esNuevo ? 'Crear proyecto' : 'Guardar cambios';

    final children = isMobile
        ? [
            AppButton(
              label: etiquetaPrimary,
              expand: true,
              height: Dimens.hExportMobile,
              onPressed: puedeGuardar ? () => _guardar(cuaderno) : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    variant: AppButtonVariant.ghost,
                    label: 'Cancelar',
                    expand: true,
                    onPressed: widget.onClose,
                  ),
                ),
                if (!_esNuevo) ...[
                  const SizedBox(width: 8),
                  DangerButton(onTap: _eliminar),
                ],
              ],
            ),
          ]
        : [
            Row(
              children: [
                if (!_esNuevo) DangerButton(onTap: _eliminar),
                const Spacer(),
                AppButton(
                  variant: AppButtonVariant.ghost,
                  label: 'Cancelar',
                  onPressed: widget.onClose,
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: etiquetaPrimary,
                  onPressed: puedeGuardar ? () => _guardar(cuaderno) : null,
                ),
              ],
            ),
          ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        widget.sheet ? 12 + MediaQuery.paddingOf(context).bottom : 12,
      ),
      decoration: BoxDecoration(
        color: t.surface2,
        border: Border(top: BorderSide(color: t.border2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Toggle de semana (`.week-toggle`): rectangular, borde 1.5, cifras tabulares.
class _WeekToggle extends StatelessWidget {
  const _WeekToggle({
    required this.label,
    required this.active,
    required this.onTap,
    this.extra = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  /// Semana de otro cuaderno: tocar la quita.
  final bool extra;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      tooltip: extra ? 'De otro cuaderno · toca para quitar' : null,
      builder: (context, hovered, _) {
        final fg = active ? t.accentInk : (hovered ? t.text : t.textDim);
        return AnimatedContainer(
          duration: Dimens.dFast,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: active ? t.accent : t.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active ? t.accent : (hovered ? t.accent : t.border),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
    );
  }
}
