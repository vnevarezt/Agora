import 'package:flutter/material.dart';
import '../widgets/pill.dart';

import '../../i18n/strings.g.dart';
import '../../models/participant.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/avatar.dart';
import 'priv_badge.dart';

/// Participant card (`.person-card`): avatar, name with an availability
/// dot, subtitle (gender · congregation) and a privilege badge.
/// Tapping it opens the edit modal.
class ParticipantCard extends StatelessWidget {
  const ParticipantCard({super.key, required this.participant, required this.onTap});

  final Participant participant;
  final VoidCallback onTap;

  String _genderLabel(BuildContext context) => switch (participant.gender) {
        Gender.male => context.t.participantModal.male,
        Gender.female => context.t.participantModal.female,
        Gender.unspecified => context.t.participantCard.genderUnspecified,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final h = participant;
    final congregation = h.congregation.trim();
    final g = _genderLabel(context);
    final sub = congregation.isEmpty ? g : '$g · $congregation';

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
                        _AvailabilityDot(active: h.active),
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
                const _IncompleteBadge()
              else
                PrivBadge(role: h.role),
            ],
          ),
        );
      },
    );
  }
}

/// Availability dot (`.dot-avail`): green if active, gray otherwise.
class _AvailabilityDot extends StatelessWidget {
  const _AvailabilityDot({required this.active});

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

/// Amber badge for participants with incomplete data (gender unset).
class _IncompleteBadge extends StatelessWidget {
  const _IncompleteBadge();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Pill(
      label: context.t.participantCard.incomplete,
      background: dark ? const Color(0xFF3A3115) : const Color(0xFFF3ECD2),
      foreground: dark ? const Color(0xFFD9C27A) : const Color(0xFF7A6512),
    );
  }
}
