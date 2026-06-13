import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/hermano.dart';
import '../../state/hermanos_provider.dart';
import '../../state/program_form.dart';
import '../limites.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/bound_text_field.dart';
import '../widgets/labeled_field.dart';
import '../widgets/mini_chip.dart';

/// Alta/edición de un hermano. Usar con `key: ValueKey(id)` para que el
/// formulario se reinicie al cambiar de selección.
class PersonaForm extends ConsumerStatefulWidget {
  const PersonaForm({super.key, this.original, required this.onClose});

  /// null = alta nueva.
  final Hermano? original;
  final VoidCallback onClose;

  @override
  ConsumerState<PersonaForm> createState() => _PersonaFormState();
}

class _PersonaFormState extends ConsumerState<PersonaForm> {
  late String _nombre = widget.original?.nombre ?? '';
  late Sexo _sexo = widget.original?.sexo ?? Sexo.noEspecificado;
  late Privilegio _privilegio =
      widget.original?.privilegio ?? Privilegio.publicador;
  late String _congregacion =
      widget.original?.congregacion ?? ref.read(formProvider).cong;
  late bool _activo = widget.original?.activo ?? true;
  late String _notas = widget.original?.notas ?? '';
  bool _guardando = false;

  /// Bump para re-sembrar el BoundTextField de congregación al tocar un chip.
  int _congVersion = 0;

  bool get _esAlta => widget.original == null;

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final ahora = DateTime.now().toUtc();
      final h = _esAlta
          ? Hermano(
              id: const Uuid().v4(),
              nombre: _nombre.trim(),
              sexo: _sexo,
              privilegio: _privilegio,
              congregacion: _congregacion.trim(),
              activo: _activo,
              notas: _notas.trim(),
              createdAt: ahora,
              updatedAt: ahora,
            )
          : widget.original!.copyWith(
              nombre: _nombre.trim(),
              sexo: _sexo,
              privilegio: _privilegio,
              congregacion: _congregacion.trim(),
              activo: _activo,
              notas: _notas.trim(),
            );
      await ref.read(hermanosAccionesProvider).guardar(h);
      widget.onClose();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar definitivamente?'),
        content: Text(
          'Se eliminará a ${widget.original!.nombre} del directorio. '
          'Esta acción no se puede deshacer. Las asignaciones ya escritas '
          'en programas no se ven afectadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    await ref.read(hermanosAccionesProvider).eliminar(widget.original!.id);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final todos = ref.watch(hermanosTodosProvider).asData?.value ?? const [];
    final clave = normalizarNombre(_nombre);
    final duplicado = _nombre.trim().isNotEmpty &&
        todos.any((h) =>
            h.id != widget.original?.id && normalizarNombre(h.nombre) == clave);
    final sugerencias = ref
        .watch(congregacionesProvider)
        .where((c) => c != _congregacion.trim())
        .take(3)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _esAlta ? 'Añadir hermano' : 'Editar hermano',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
              ),
              AppIconButton(
                icon: Icons.close,
                tooltip: 'Cerrar',
                size: 30,
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Nombre',
            child: BoundTextField(
              initial: _nombre,
              maxLength: Limites.nombre,
              hint: 'Nombre y apellido',
              onChanged: (v) => setState(() => _nombre = v),
            ),
          ),
          if (duplicado)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                'Ya existe un hermano con este nombre.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Sexo',
            child: AppDropdown<Sexo>(
              value: _sexo,
              items: Sexo.values,
              itemLabel: (s) => s.etiqueta,
              onChanged: (v) => setState(() => _sexo = v),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Privilegio',
            child: AppDropdown<Privilegio>(
              value: _privilegio,
              items: Privilegio.values,
              itemLabel: (p) => p.etiqueta,
              onChanged: (v) => setState(() => _privilegio = v),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Congregación',
            child: BoundTextField(
              key: ValueKey('cong-$_congVersion'),
              initial: _congregacion,
              maxLength: Limites.cong,
              onChanged: (v) => setState(() => _congregacion = v),
            ),
          ),
          if (sugerencias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in sugerencias)
                    GestureDetector(
                      onTap: () => setState(() {
                        _congregacion = c;
                        _congVersion++;
                      }),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: MiniChip.tag(c),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Activo',
            child: SizedBox(
              height: Dimens.hField,
              child: Row(
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _activo,
                      onChanged: (v) => setState(() => _activo = v),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _activo ? 'Visible en el selector' : 'Oculto del selector',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _activo ? t.text : t.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Notas',
            child: BoundTextField(
              initial: _notas,
              maxLength: Limites.notas,
              maxLines: 3,
              hint: 'Opcional',
              onChanged: (v) => setState(() => _notas = v),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Guardar',
                  icon: Icons.check,
                  busy: _guardando,
                  expand: true,
                  onPressed: _nombre.trim().isEmpty || _guardando
                      ? null
                      : _guardar,
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                variant: AppButtonVariant.ghost,
                label: 'Cancelar',
                onPressed: widget.onClose,
              ),
            ],
          ),
          if (!_esAlta) ...[
            const SizedBox(height: 16),
            Center(
              child: Pressable(
                onTap: _eliminar,
                builder: (context, hovered, _) => Text(
                  'Eliminar definitivamente…',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.error.withValues(
                          alpha: hovered ? 1 : 0.85,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
