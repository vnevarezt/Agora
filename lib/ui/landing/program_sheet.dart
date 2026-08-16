import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/motion.dart';

abstract final class _Paper {
  static const Color sheet = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1F242D);
  static const Color inkDim = Color(0xFF5D646F);
  static const Color rule = Color(0xFFE4E8EC);
  static const Color treasures = Color(0xFF5C5C5C);
  static const Color ministry = Color(0xFFB9890F);
  static const Color christianLife = Color(0xFF8C1B2E);
}

typedef _Entry = (String time, String title, String? name);

sealed class _Block {
  const _Block();

  /// How many lines of the assembly this block occupies. A band counts as a
  /// line of its own: on paper it is printed, not implied.
  int get lines;
}

final class _Plain extends _Block {
  const _Plain(this.entries);

  final List<_Entry> entries;

  @override
  int get lines => entries.length;
}

final class _Banded extends _Block {
  const _Banded({
    required this.color,
    required this.label,
    required this.entries,
  });

  final Color color;
  final String label;
  final List<_Entry> entries;

  @override
  int get lines => entries.length + 1;
}

/// Deliberately not translated: this is a picture of a Spanish-language
/// program, the way a product shot shows one specific document rather than a
/// localised template.
const List<_Block> _program = [
  _Plain([
    ('18:00', 'Canción 42 y oración', 'R. Cano'),
    ('18:05', 'Palabras de introducción', 'M. Salas'),
  ]),
  _Banded(
    color: _Paper.treasures,
    label: 'TESOROS DE LA BIBLIA',
    entries: [
      ('18:09', 'Discurso', 'M. Salas'),
      ('18:19', 'Busquemos perlas escondidas', 'A. Beltrán'),
      ('18:29', 'Lectura de la Biblia', 'J. Ríos'),
    ],
  ),
  _Banded(
    color: _Paper.ministry,
    label: 'SEAMOS MEJORES MAESTROS',
    entries: [
      ('18:34', 'Empiece conversaciones', 'D. Puga'),
      ('18:39', 'Haga revisitas', 'R. Ledesma'),
      ('18:44', 'Discurso', 'C. Vega'),
    ],
  ),
  _Plain([('18:49', 'Canción 108', null)]),
  _Banded(
    color: _Paper.christianLife,
    label: 'NUESTRA VIDA CRISTIANA',
    entries: [
      ('18:57', 'Necesidades de la congregación', 'L. Ordaz'),
      ('19:02', 'Estudio bíblico de la congregación', 'H. Mena'),
    ],
  ),
  _Plain([
    ('19:32', 'Palabras de conclusión', 'M. Salas'),
    ('19:35', 'Canción 55 y oración', 'T. Ibarra'),
  ]),
];

/// Masthead plus every printed line.
final int _lineCount = _program.fold(1, (n, block) => n + block.lines);

/// The slice of the assembly timeline a single line gets. Wide enough that
/// consecutive lines overlap heavily — the sheet should read as filling in,
/// not as seventeen separate animations queued up.
const double _lineSpan = 0.34;

/// How far behind its line a name lands. The blank rule is printed with the
/// form; the name arrives after it, which is the whole product in one gesture.
const double _nameLag = 0.08;

double _lineStart(int line) =>
    (1 - _lineSpan) * line / (_lineCount - 1);

Animation<double>? _lineAnim(Animation<double>? assemble, int line) {
  if (assemble == null) return null;
  final start = _lineStart(line);
  return CurvedAnimation(
    parent: assemble,
    curve: Interval(start, start + _lineSpan, curve: Motion.arrive),
  );
}

Animation<double>? _nameAnim(Animation<double>? assemble, int line) {
  if (assemble == null) return null;
  // The last line has no room left to lag into, so it simply lands with its
  // own row rather than overrunning the end of the timeline.
  final start = math.min(_lineStart(line) + _nameLag, 1 - _lineSpan);
  return CurvedAnimation(
    parent: assemble,
    curve: Interval(start, start + _lineSpan, curve: Motion.arrive),
  );
}

/// The printed program, drawn to scale rather than at a fixed size.
///
/// Every number below is in the coordinate space of a sheet [_refWidth] wide
/// and multiplied by [scale] on the way out, so the mock behaves like paper:
/// narrowing the column shrinks the whole page instead of reflowing 7pt type
/// inside an unchanged margin.
class ProgramSheet extends StatelessWidget {
  const ProgramSheet({super.key, this.assemble});

  /// Drives the sheet filling in, line by line. Null renders it complete —
  /// which is what reduced motion and every non-hero use get.
  final Animation<double>? assemble;

  /// The width this drawing is dimensioned for: the hero column on a desktop
  /// window, where the sheet is seen at its largest.
  static const double _refWidth = 440;

  /// US Letter, the paper the exported program is laid out for.
  static const double aspect = 612 / 792;

  /// The paper's own corner. Barely rounded — it is a sheet, not a card — and
  /// shared with the shadow behind it, which has to clip to the same shape.
  static const double radius = 4;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / _refWidth).clamp(0.72, 1.25);
          var line = 1;
          final blocks = <Widget>[];
          for (final block in _program) {
            blocks.add(
              _BlockView(
                block: block,
                scale: scale,
                firstLine: line,
                assemble: assemble,
              ),
            );
            line += block.lines;
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ColoredBox(
              color: _Paper.sheet,
              child: Padding(
                padding: EdgeInsets.all(18 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Masthead(scale: scale, assemble: assemble),
                    SizedBox(height: 9 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: blocks,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Fade + rise for one printed line. Null [anim] means the line is simply
/// already on the page.
class _Ink extends StatelessWidget {
  const _Ink({required this.anim, required this.scale, required this.child});

  final Animation<double>? anim;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anim = this.anim;
    if (anim == null) return child;
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 5 * scale * (1 - anim.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({
    required this.block,
    required this.scale,
    required this.firstLine,
    required this.assemble,
  });

  final _Block block;
  final double scale;
  final int firstLine;
  final Animation<double>? assemble;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      _Plain(:final entries) => _Rows(
        entries: entries,
        scale: scale,
        firstLine: firstLine,
        assemble: assemble,
      ),
      _Banded(:final color, :final label, :final entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Ink(
            anim: _lineAnim(assemble, firstLine),
            scale: scale,
            child: _Band(color: color, label: label, scale: scale),
          ),
          _Rows(
            entries: entries,
            scale: scale,
            firstLine: firstLine + 1,
            assemble: assemble,
          ),
        ],
      ),
    };
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.scale, required this.assemble});

  final double scale;
  final Animation<double>? assemble;

  @override
  Widget build(BuildContext context) {
    return _Ink(
      anim: _lineAnim(assemble, 0),
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'REUNIÓN DE ENTRESEMANA',
                style: TextStyle(
                  fontSize: 7.5 * scale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5 * scale,
                  color: _Paper.ink,
                ),
              ),
              Text(
                '6-12 ABR',
                style: AppText.mono(size: 7 * scale, color: _Paper.inkDim),
              ),
            ],
          ),
          SizedBox(height: 6 * scale),
          Container(height: 1, color: _Paper.ink),
        ],
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.color, required this.label, required this.scale});

  final Color color;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 4 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 5 * scale,
        vertical: 2.5 * scale,
      ),
      color: color,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: 6.5 * scale,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4 * scale,
          color: _Paper.sheet,
        ),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({
    required this.entries,
    required this.scale,
    required this.firstLine,
    required this.assemble,
  });

  final List<_Entry> entries;
  final double scale;
  final int firstLine;
  final Animation<double>? assemble;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          _RowView(
            entry: entries[i],
            scale: scale,
            line: firstLine + i,
            assemble: assemble,
          ),
      ],
    );
  }
}

class _RowView extends StatelessWidget {
  const _RowView({
    required this.entry,
    required this.scale,
    required this.line,
    required this.assemble,
  });

  final _Entry entry;
  final double scale;
  final int line;
  final Animation<double>? assemble;

  @override
  Widget build(BuildContext context) {
    final (time, title, name) = entry;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.2 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          _Ink(
            anim: _lineAnim(assemble, line),
            scale: scale,
            child: SizedBox(
              width: 22 * scale,
              child: Text(
                time,
                style: AppText.mono(size: 6.5 * scale, color: _Paper.inkDim),
              ),
            ),
          ),
          Expanded(
            child: _Ink(
              anim: _lineAnim(assemble, line),
              scale: scale,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 7 * scale,
                  fontWeight: FontWeight.w600,
                  color: _Paper.ink,
                ),
              ),
            ),
          ),
          if (name != null) ...[
            SizedBox(width: 6 * scale),
            // The rule is printed with the rest of the line; only the name
            // written on it waits.
            _Ink(
              anim: _lineAnim(assemble, line),
              scale: scale,
              child: Container(
                constraints: BoxConstraints(minWidth: 34 * scale),
                padding: EdgeInsets.only(bottom: 1.5 * scale),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _Paper.rule)),
                ),
                child: _Ink(
                  anim: _nameAnim(assemble, line),
                  scale: scale,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 7 * scale,
                      fontWeight: FontWeight.w700,
                      color: _Paper.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
