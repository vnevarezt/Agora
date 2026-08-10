import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../widgets/pill.dart';

import '../../i18n/strings.g.dart';
import '../../models/person.dart';
import '../theme/tokens.dart';
import '../widgets/avatar.dart';
import '../widgets/ink_surface.dart';
import 'priv_badge.dart';
import '../theme/app_theme.dart';

/// The height every [ParticipantCard] lays out at, for the current text
/// scale. The card is uniform by construction — the avatar is a fixed 38 and
/// all three text runs are `maxLines: 1`, so neither a long name, a visitor's
/// origin congregation nor the incomplete badge changes it. That uniformity
/// is what lets the participants grid virtualise with a fixed tile extent
/// instead of materialising every card.
///
/// Rounds slightly high on purpose: a tile a pixel taller than its card is
/// invisible, a tile a pixel shorter clips it. `participant_card_test` pins
/// this against the real laid-out height, so changing the card's contents
/// fails there rather than silently clipping the whole grid.
double participantCardHeight(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  const avatar = 38.0;
  const verticalPadding = 12.0 * 2;
  const lineHeight = 1.44;
  final textColumn = scaler.scale(AppText.bodyLarge) * lineHeight +
      1 +
      scaler.scale(AppText.caption) * lineHeight;
  return math.max(avatar, textColumn) + verticalPadding;
}

class ParticipantCard extends StatelessWidget {
  const ParticipantCard({super.key, required this.participant, required this.onTap});

  final Person participant;
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
    final congregation = h.originCongregation.trim();
    final g = _genderLabel(context);
    final sub = congregation.isEmpty ? g : '$g · $congregation';

    return InkSurface(
      onTap: onTap,
      borderRadius: 14,
      hoverElevation: 4,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      builder: (context, hovered) {
        return Row(
          children: [
            PersonAvatar(name: h.displayName, size: 38),
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
                          h.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppText.bodyLarge,
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
                      fontSize: AppText.caption,
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
              PrivBadge(role: h.privilege),
          ],
        );
      },
    );
  }
}

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
        color: active ? t.successStrong : t.border,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _IncompleteBadge extends StatelessWidget {
  const _IncompleteBadge();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pill(
      label: context.t.participantCard.incomplete,
      background: t.warningSoft,
      foreground: t.warning,
    );
  }
}
