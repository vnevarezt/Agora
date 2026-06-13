import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/assignment_ops.dart';
import '../../state/hermanos_provider.dart';
import '../../state/program_form.dart';
import '../../state/ui_state.dart';
import '../responsive.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../picker/person_picker.dart';
import 'assignee_button.dart';
import 'part_presentation.dart';

/// Un hueco de asignación: label uppercase + [AssigneeButton]. Abre el
/// picker y escribe el resultado en el formulario vía [escribirAsignacion].
class SlotField extends ConsumerWidget {
  const SlotField({super.key, required this.spec});

  final SlotSpec spec;

  Future<void> _abrirPicker(
      BuildContext anchorContext, WidgetRef ref, String actual) async {
    ref.read(activeSlotProvider.notifier).set(spec.ref);
    try {
      final resultado = await showPersonPicker(
        anchorContext,
        roleLabel: spec.label,
        actual: actual,
        maxLength: spec.maxLength,
      );
      switch (resultado) {
        case PickNombre(:final nombre):
          escribirAsignacion(ref, spec.ref, nombre);
          // Fire-and-forget: el directorio se actualiza solo (stream).
          unawaited(ref.read(hermanosAccionesProvider).registrarUso(nombre));
        case PickQuitar():
          escribirAsignacion(ref, spec.ref, '');
        case null:
          break;
      }
    } finally {
      ref.read(activeSlotProvider.notifier).set(null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final nombre =
        ref.watch(formProvider.select((f) => nombreDeSlot(f, spec.ref)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            spec.label.toUpperCase(),
            style: AppText.label(
                color: spec.accent ? t.accentStrong : t.textMute),
          ),
        ),
        // Builder: ancla del popover = solo el botón, no el label.
        Builder(
          builder: (anchorContext) => AssigneeButton(
            nombre: nombre.isEmpty ? null : nombre,
            alwaysShowClear: context.isMobile,
            onTap: () => _abrirPicker(anchorContext, ref, nombre),
            onClear: nombre.isEmpty
                ? null
                : () => escribirAsignacion(ref, spec.ref, ''),
          ),
        ),
      ],
    );
  }
}
