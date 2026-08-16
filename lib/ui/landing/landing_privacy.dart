import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import '../theme/tokens.dart';
import '../widgets/motion.dart';
import '../widgets/segmented_control.dart';
import 'landing_layout.dart';
import 'landing_motion.dart';

/// How much of a row's slice is spent clearing the old value. The rest brings
/// the new one in, so the two never overlap — a cross-fade between two short
/// strings in the same spot reads as a smudge.
const double _exitShare = .4;

/// How far a value travels. Small: it is a word changing, not a panel moving,
/// and the direction is the whole point of the movement, not the distance.
const double _valueTravel = 12;

/// Slice of the transition each row gets, and how far apart they start. Four
/// rows at .1 apart leaves the last one .3 to .1 + .7 — late enough to read
/// as a sweep down the table, early enough that it is not a queue.
const double _rowSpan = .7;
const double _rowStep = .1;

/// Rows in the comparison. Fixed because the table compares a fixed set of
/// questions; the stagger intervals are built once against it.
const int _rowCount = 4;

class LandingPrivacy extends StatefulWidget {
  const LandingPrivacy({super.key});

  @override
  State<LandingPrivacy> createState() => _LandingPrivacyState();
}

class _LandingPrivacyState extends State<LandingPrivacy>
    with SingleTickerProviderStateMixin {
  bool _team = false;

  /// The mode being left, held only while the swap runs. Null the rest of the
  /// time so the outgoing values are genuinely gone from the tree rather than
  /// parked at zero opacity on top of the new ones.
  bool? _from;

  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: Motion.med,
  );

  /// Built once rather than per build: a `CurvedAnimation` owns a listener on
  /// its parent and has to be disposed, so handing a fresh one to each row on
  /// every frame of the swap would leak four of them per frame.
  late final List<Animation<double>> _rowProgress = [
    for (var i = 0; i < _rowCount; i++)
      CurvedAnimation(
        parent: _swap,
        curve: Interval(i * _rowStep, i * _rowStep + _rowSpan),
      ),
  ];

  @override
  void initState() {
    super.initState();
    _swap.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _from = null);
      }
    });
  }

  @override
  void dispose() {
    for (final anim in _rowProgress) {
      (anim as CurvedAnimation).dispose();
    }
    _swap.dispose();
    super.dispose();
  }

  void _select(bool team) {
    if (team == _team) return;
    setState(() {
      _from = _team;
      _team = team;
    });
    _swap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t;
    final p = tr.landing.privacy;
    // Set here rather than in initState: the reduced-motion answer comes from
    // MediaQuery, and it can change under a running app.
    _swap.duration = Motion.of(context, Motion.med);

    final labels = [
      p.accountLabel,
      p.whereLabel,
      p.whoSeesLabel,
      p.offlineLabel,
    ];
    const soloIndex = 0;
    final values = [
      [p.accountSolo, p.whereSolo, p.whoSeesSolo, p.offlineSolo],
      [p.accountTeam, p.whereTeam, p.whoSeesTeam, p.offlineTeam],
    ];
    final current = values[_team ? 1 : soloIndex];
    final previous = _from == null ? null : values[_from! ? 1 : soloIndex];

    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BentoRow(
            align: CrossAxisAlignment.center,
            cells: [
              BentoCell(
                flex: BentoSplit.heading,
                child: Reveal(
                  child: LandingHeadingColumn(
                    child: LandingHeading(text: p.title),
                  ),
                ),
              ),
              BentoCell(
                flex: BentoSplit.panel,
                child: Reveal(
                  delay: const Duration(milliseconds: 70),
                  child: BentoTile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedTabs(
                          segments: [
                            (icon: null, label: p.modeSolo),
                            (icon: null, label: p.modeTeam),
                          ],
                          index: _team ? 1 : 0,
                          onChanged: (i) => _select(i == 1),
                        ),
                        const SizedBox(height: LandingSpace.s24),
                        for (var i = 0; i < _rowCount; i++)
                          _ValueRow(
                            label: labels[i],
                            value: current[i],
                            previous: previous?[i],
                            // The values enter from the side the indicator
                            // just travelled towards, so the table reads as
                            // part of the same movement as the control.
                            forward: _team,
                            progress: _rowProgress[i],
                            divided: i > 0,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LandingSpace.gap),
          Reveal(
            child: _Note(
              text: _team ? p.teamNote : p.soloWarning,
              emphasis: !_team,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.previous,
    required this.forward,
    required this.progress,
    required this.divided,
  });

  final String label;
  final String value;

  /// The value being replaced, or null when nothing is in flight.
  final String? previous;

  final bool forward;
  final Animation<double> progress;
  final bool divided;

  /// Wide enough for the longest label at both shipped locales without
  /// wrapping, so the values start on a straight edge down the table.
  static const double _labelWidth = 132;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divided ? Border(top: BorderSide(color: t.border2)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LandingSpace.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _labelWidth,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppText.body,
                  fontWeight: FontWeight.w500,
                  color: t.textMute,
                ),
              ),
            ),
            const SizedBox(width: LandingSpace.s12),
            // Only the value changes between modes; the label is the same word
            // either way. Animating the whole row would move four labels that
            // are not going anywhere and bury the one thing that is.
            Expanded(child: _value(t)),
          ],
        ),
      ),
    );
  }

  Widget _value(AppTokens t) {
    final text = _text(value, t);
    if (previous == null) return text;

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final p = progress.value;
        final leaving = p < _exitShare;
        final phase = leaving
            ? p / _exitShare
            : (p - _exitShare) / (1 - _exitShare);
        // Out to the near side, in from the far side: one continuous sweep in
        // the direction of travel rather than two unrelated fades.
        final direction = forward ? 1.0 : -1.0;
        final offset = leaving
            ? -direction * _valueTravel * phase
            : direction * _valueTravel * (1 - Motion.arrive.transform(phase));

        return Opacity(
          opacity: leaving ? 1 - phase : phase,
          child: Transform.translate(
            offset: Offset(offset, 0),
            // Both strings are one or two lines, and rarely the same count:
            // easing the box keeps the rows below from stepping.
            child: MotionSize(
              duration: Motion.fast,
              alignment: Alignment.topLeft,
              child: leaving ? _text(previous!, t) : text,
            ),
          ),
        );
      },
    );
  }

  Widget _text(String value, AppTokens t) => Text(
    value,
    style: TextStyle(
      fontSize: AppText.bodyLarge,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
      height: 1.35,
      color: t.text,
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.emphasis});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.med),
      curve: Motion.curve,
      padding: const EdgeInsets.symmetric(
        horizontal: LandingSpace.s24,
        vertical: LandingSpace.s20,
      ),
      decoration: BoxDecoration(
        color: emphasis ? t.alertSoft : t.surface2,
        borderRadius: BorderRadius.circular(Dimens.rCard),
      ),
      // The note is a block replacing a block, not a word changing in place:
      // it fades through while the table sweeps, which keeps the two legible
      // as separate answers to the same question.
      child: MotionSize(
        alignment: Alignment.topCenter,
        child: FadeThroughSwitcher(
          child: Row(
            key: ValueKey(emphasis),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Optical: the icon's box is taller than the text's cap
                // height, so matching their tops leaves the icon riding high.
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  emphasis ? Icons.warning_amber_rounded : Icons.lock_outline,
                  size: 20,
                  color: emphasis ? t.alert : t.textMute,
                ),
              ),
              const SizedBox(width: LandingSpace.s16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    fontWeight: emphasis ? FontWeight.w600 : FontWeight.w500,
                    height: 1.5,
                    letterSpacing: -0.1,
                    color: t.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
