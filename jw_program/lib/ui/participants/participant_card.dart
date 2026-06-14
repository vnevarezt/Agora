import 'package:flutter/material.dart';
import '../widgets/pill.dart';

import '../../models/participant.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import 'priv_badge.dart';

/// Tarjeta de participant (`.person-card`): avatar, name con punto de
/// disponibilidad, subtítulo (sexo · congregación) e insignia de privilegio.
/// Al tocarla se abre el modal de edición.
class ParticipantCard extends StatelessWidget {
  const ParticipantCard({super.key, required this.participant, required this.onTap});

  final Participant participant;
  final VoidCallback onTap;

  String get _genderLabel => switch (participant.gender) {
        Gender.male => 'Hombre',
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

/// Insignia ámbar para participantes con datos incompletos (sexo sin definir).
class _IncompletoBadge extends StatelessWidget {
  const _IncompletoBadge();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Pill(
      label: 'Incompleto',
      background: dark ? const Color(0xFF3A3115) : const Color(0xFFF3ECD2),
      foreground: dark ? const Color(0xFFD9C27A) : const Color(0xFF7A6512),
    );
  }
}
