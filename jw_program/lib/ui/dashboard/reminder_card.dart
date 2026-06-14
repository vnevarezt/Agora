import 'package:flutter/material.dart';

import '../../models/reminder.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';

/// Reminder card (`.reminder`): icon colored by type, title, meta and
/// CTA. No logic at this phase (the CTA does nothing).
class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.recordatorio});

  final Reminder recordatorio;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = recordatorio;

    final (IconData icono, Color iconBg, Color iconFg, Color? iconBorde) =
        switch (r.type) {
      ReminderType.alert => dark
          ? (
              Icons.warning_amber_rounded,
              const Color(0xFF40231C),
              const Color(0xFFE8A38C),
              null
            )
          : (
              Icons.warning_amber_rounded,
              const Color(0xFFFBE7DF),
              const Color(0xFFB5562F),
              null
            ),
      ReminderType.task =>
        (Icons.schedule, t.accentSoft, t.accentStrong, null),
      ReminderType.info =>
        (Icons.auto_awesome_outlined, t.surface2, t.textDim, t.border2),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: iconBorde != null ? Border.all(color: iconBorde) : null,
            ),
            child: Icon(icono, size: 16, color: iconFg),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.meta,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.textMute,
                  ),
                ),
                const SizedBox(height: 7),
                Pressable(
                  onTap: () {}, // sin acción en esta fase
                  builder: (context, hovered, _) => Text(
                    '${r.cta} →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: t.accentStrong,
                      decoration:
                          hovered ? TextDecoration.underline : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
