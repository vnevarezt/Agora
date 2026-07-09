import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';

enum _ChipKind { time, allMeeting, duration, tag, aux, week }

/// Small chip. A single widget with presets that mirror
/// `.time-badge`, `.time-badge--all`, `.dur-chip`, `.fixed-line__tag` y
/// `.aux-flag` from the mock.
class MiniChip extends StatelessWidget {
  /// Part time (mono, accent-soft background).
  const MiniChip.time(this.texto, {super.key}) : _kind = _ChipKind.time;

  /// Insignia neutra uppercase ("TODA LA REUNIÓN").
  const MiniChip.allMeeting(this.texto, {super.key})
      : _kind = _ChipKind.allMeeting;

  /// Duration ("10 min").
  const MiniChip.duration(this.texto, {super.key})
      : _kind = _ChipKind.duration;

  /// Fixed-line tag ("Cántico", "A cargo del presidente").
  const MiniChip.tag(this.texto, {super.key}) : _kind = _ChipKind.tag;

  /// Auxiliary-room indicator (accent pill with a building icon).
  const MiniChip.aux(this.texto, {super.key}) : _kind = _ChipKind.aux;

  /// Dashboard week pill ("4–10 MAY"): neutral, with tabular figures.
  const MiniChip.week(this.texto, {super.key}) : _kind = _ChipKind.week;

  final String texto;
  final _ChipKind _kind;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final (Color bg, Color? bordeColor, Color fg, double radio) =
        switch (_kind) {
      _ChipKind.time => (t.accentSoft, null, t.accentStrong, Dimens.rChip),
      _ChipKind.allMeeting => (t.surface2, t.border2, t.textDim, Dimens.rChip),
      _ChipKind.duration => (t.surface2, t.border2, t.textMute, 6.0),
      _ChipKind.tag => (t.surface2, t.border2, t.textMute, Dimens.rPill),
      _ChipKind.aux => (t.accentSoft, null, t.accentStrong, Dimens.rPill),
      _ChipKind.week => (t.surface2, t.border2, t.textDim, 6.0),
    };

    final estilo = switch (_kind) {
      _ChipKind.time => AppText.mono(size: 12, weight: FontWeight.w700, color: fg),
      _ChipKind.allMeeting => AppText.label(color: fg),
      _ChipKind.duration =>
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      _ChipKind.tag =>
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      _ChipKind.aux =>
        TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
      _ChipKind.week => TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
    };

    final padding = switch (_kind) {
      _ChipKind.duration => const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      _ChipKind.tag || _ChipKind.aux =>
        const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      _ChipKind.week => const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      _ => const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radio),
        border: bordeColor != null ? Border.all(color: bordeColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_kind == _ChipKind.aux) ...[
            Icon(Icons.apartment_outlined, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            _kind == _ChipKind.allMeeting ? texto.toUpperCase() : texto,
            style: estilo,
          ),
        ],
      ),
    );
  }
}
