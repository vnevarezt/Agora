import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import '../widgets/dashed_border.dart';

/// Botón de asignación (`.assignee`): vacío muestra borde discontinuo y
/// "Asignar…"; lleno muestra avatar + name + X para limpiar (visible al
/// pasar el cursor, o siempre en táctil con [alwaysShowClear]).
class AssigneeButton extends StatelessWidget {
  const AssigneeButton({
    super.key,
    this.name,
    required this.onTap,
    this.onClear,
    this.alwaysShowClear = false,
  });

  final String? name;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool alwaysShowClear;

  bool get _lleno => name != null && name!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        final contenido = AnimatedContainer(
          duration: Dimens.dFast,
          height: Dimens.hAssignee,
          padding: const EdgeInsets.only(left: 8, right: 10),
          decoration: BoxDecoration(
            color: _lleno ? t.surface : t.surface2,
            borderRadius: BorderRadius.circular(Dimens.rAssignee),
            border: _lleno
                ? Border.all(
                    color: hovered ? t.accent : t.border, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              PersonAvatar(name: _lleno ? name : null),
              const SizedBox(width: 9),
              Expanded(
                child: _lleno
                    ? Text(
                        name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      )
                    : Text(
                        'Asignar…',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: hovered ? t.textDim : t.textMute,
                        ),
                      ),
              ),
              if (_lleno && onClear != null)
                AnimatedOpacity(
                  duration: Dimens.dFast,
                  opacity: hovered || alwaysShowClear ? 1 : 0,
                  child: _BotonLimpiar(onClear: onClear!),
                ),
            ],
          ),
        );

        // El estado vacío lleva borde discontinuo (no soportado por Border).
        if (_lleno) return contenido;
        return DashedBorder(
          color: hovered ? t.accent : t.border,
          radius: Dimens.rAssignee,
          child: contenido,
        );
      },
    );
  }
}

class _BotonLimpiar extends StatelessWidget {
  const _BotonLimpiar({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onClear,
      tooltip: 'Quitar asignación',
      builder: (context, hovered, _) {
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: hovered ? t.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.close,
              size: 14, color: hovered ? t.text : t.textMute),
        );
      },
    );
  }
}
