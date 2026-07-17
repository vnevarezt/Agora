import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../models/congregation.dart';
import '../../models/project.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import 'status_badge.dart';

/// Hero "continue where you left off" card: progress ring, identity line,
/// one chip per week showing its state, and the big continue CTA.
class ContinueCard extends StatelessWidget {
  const ContinueCard({
    super.key,
    required this.project,
    required this.congregation,
    required this.onContinue,
  });

  final Project project;
  final Congregation? congregation;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tr = context.t;
    final p = project;
    final pct = (p.progress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.dashboard.continueWhere.toUpperCase(),
            style: AppText.label(size: 11, color: t.textMute),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 560;
            final ring = _ProgressRing(value: p.progress, label: '$pct%');
            final body = _body(t, tr, p);
            final cta = AppButton(
              icon: Icons.arrow_forward,
              label: tr.dashboard.continueCta,
              onPressed: onContinue,
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    ring,
                    const SizedBox(width: 16),
                    Expanded(child: body),
                  ]),
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerRight, child: cta),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ring,
                const SizedBox(width: 18),
                Expanded(child: body),
                const SizedBox(width: 18),
                cta,
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _body(AppTokens t, Translations tr, Project p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Flexible(
            child: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: t.text,
              ),
            ),
          ),
          const SizedBox(width: 10),
          StatusBadge(status: p.status),
        ]),
        const SizedBox(height: 5),
        Row(children: [
          if (congregation != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color(congregation!.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                congregation!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.textMute,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              '${tr.dashboard.assignmentsDone(done: p.done, total: p.total)}'
              ' · ${tr.projectCard.edited(label: p.editedLabel)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.textMute,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final w in p.weekProgress) _WeekChip(progress: w),
          ],
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0, 1),
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            backgroundColor: t.border2,
            color: t.accent,
          ),
          Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Week chip tinted by state: complete (check, green), started (half,
/// amber), untouched (plain).
class _WeekChip extends StatelessWidget {
  const _WeekChip({required this.progress});

  final WeekProgress progress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final complete = progress.total > 0 && progress.done >= progress.total;
    final started = !complete && progress.done > 0;

    final (IconData? icon, Color bg, Color fg) = complete
        ? (
            Icons.check_rounded,
            dark ? const Color(0xFF1C3325) : const Color(0xFFE1F2E6),
            dark ? const Color(0xFF7FC796) : const Color(0xFF2E7247),
          )
        : started
            ? (
                Icons.timelapse_rounded,
                dark ? const Color(0xFF3A3115) : const Color(0xFFF7EED4),
                dark ? const Color(0xFFD9C27A) : const Color(0xFF8A6E1B),
              )
            : (null, t.surface2, t.textDim);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: icon == null ? Border.all(color: t.border2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            progress.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
