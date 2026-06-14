import 'package:flutter/material.dart';

import '../../models/participant.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import 'priv_badge.dart';

/// Tarjeta de participant (`.person-card`): avatar, nombre con punto de
/// disponibilidad, subtítulo (sexo · congregación) e insignia de privilegio.
/// Al tocarla se abre el modal de edición.
class ParticipantCard extends StatelessWidget {
  const ParticipantCard({super.key, required this.participant, required this.onTap});

  final Participant participant;
  final VoidCallback onTap;

  String get _genderLabel => switch (participant.gender) {
        Gender.male => 'Participant',
        Gender.female => 'Mujer',
        Gender.unspecified => 'Sin definir',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final h = participant;
    final cong = h.congregation.trim();
    final sub = cong.isEmpty ? _genderLabel : '$_genderLabel · $cong';

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
              PersonAvatar(name: h.name, size: 38),
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
                            h.name,
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
                        _DotDisponible(active: h.active),
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
              if (h.isIncomplete)
                const _IncompletoBadge()
              else
                PrivBadge(role: h.role),
            ],
          ),
        );
      },
    );
  }
}

/// Punto de disponibilidad (`.dot-avail`): verde si active, gris si no.
class _DotDisponible extends StatelessWidget {
  const _DotDisponible({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF4FA06A) : t.border,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Insignia ámbar para participants con datos incompletos (sexo sin definir).
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
