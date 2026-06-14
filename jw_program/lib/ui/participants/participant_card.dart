import 'package:flutter/material.dart';

import '../../models/participant.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import 'priv_badge.dart';

/// Tarjeta de hermano (`.person-card`): avatar, nombre con punto de
/// disponibilidad, subtítulo (sexo · congregación) e insignia de privilegio.
/// Al tocarla se abre el modal de edición.
class PersonaCard extends StatelessWidget {
  const PersonaCard({super.key, required this.hermano, required this.onTap});

  final Hermano hermano;
  final VoidCallback onTap;

  String get _sexoLabel => switch (hermano.sexo) {
        Sexo.hombre => 'Hermano',
        Sexo.mujer => 'Hermana',
        Sexo.noEspecificado => 'Sin definir',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final h = hermano;
    final cong = h.congregacion.trim();
    final sub = cong.isEmpty ? _sexoLabel : '$_sexoLabel · $cong';

    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) {
        return AnimatedContainer(
          duration: Dimens.dFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hovered ? t.accent : t.border),
          ),
          child: Row(
            children: [
              PersonAvatar(nombre: h.nombre, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            h.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: t.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _DotDisponible(activo: h.activo),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: t.textMute,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (h.incompleto)
                const _IncompletoBadge()
              else
                PrivBadge(privilegio: h.privilegio),
            ],
          ),
        );
      },
    );
  }
}

/// Punto de disponibilidad (`.dot-avail`): verde si activo, gris si no.
class _DotDisponible extends StatelessWidget {
  const _DotDisponible({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: activo ? const Color(0xFF4FA06A) : t.border,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Insignia ámbar para hermanos con datos incompletos (sexo sin definir).
class _IncompletoBadge extends StatelessWidget {
  const _IncompletoBadge();

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final bg = oscuro ? const Color(0xFF3A3115) : const Color(0xFFF3ECD2);
    final fg = oscuro ? const Color(0xFFD9C27A) : const Color(0xFF7A6512);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dimens.rPill),
      ),
      child: Text(
        'INCOMPLETO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
    );
  }
}
