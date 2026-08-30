import 'pdf_theme.dart';

/// How much a sheet's layout was opened up to fill its page: [type] multiplies
/// the fonts (and everything sized off them), [air] the vertical gaps.
typedef SheetFit = ({double type, double air});

/// What one candidate layout measures: how tall the block comes out, and what
/// it had to break to get there — titles that wrapped, names that stacked.
typedef SheetProbe = ({double height, int titleBreaks, int nameBreaks});

const SheetFit noFit = (type: 1, air: 1);

/// Type scale granularity, in hundredths. Coarse on purpose: two weeks of
/// similar weight should print at the SAME size, and a finer search would give
/// one 12.3 pt and the next 12.1 pt for no visible gain. Integer rungs, so the
/// ladder lands exactly on its own bounds instead of a hair under them.
const int typeStepPercent = 5;

int _rungs(double scale) => (scale * 100).round();

/// Chooses how far one sheet's block may grow to fill [available] points of
/// page height, given a [probe] that lays the block out for a candidate fit and
/// reports what it measures.
///
/// A week is 14-odd rows on a Letter page: at the official 10 pt a third of the
/// sheet is left blank, so the type grows until the page is full. Two knobs,
/// handled differently because they behave differently:
///
///  * Type is NOT monotonic in height, and height is not the only thing that
///    matters about it. Bigger type eventually pushes a cell past the width of
///    its column, and the extra line can cost more than the size gained — so
///    this walks a ladder down from the ceiling and takes the largest size
///    that breaks nothing the official size did not already break, give or
///    take [nameTolerance]. Titles and names are held SEPARATELY rather than
///    as one total, so a size can never buy itself a wrapped title by stacking
///    a pair of names instead.
///    Measured against the official size rather than against zero: an
///    auxiliary-room sheet wraps at every size, including the official one,
///    and holding it to a standard it never met would freeze it at 10 pt.
///  * Air only ever adds fixed gaps, so height is affine in it. Two probes
///    (1× and the ceiling) determine the line and the answer is read off it.
///
/// A block that does not fit even at the official size goes the other way, down
/// to [S140Metrics.minTypeScale] — but only for a sheet that says it may. The
/// one-week sheet may not: it flows onto a second page instead. Returns [noFit]
/// when nothing in range fits, leaving the overflow to the caller.
SheetFit fitSheet({
  required SheetProbe Function(SheetFit) probe,
  required double available,
  required S140Metrics metrics,
  int nameTolerance = 0,
}) {
  final official = probe(noFit);
  if (official.height > available) {
    for (
      var rung = 100 - typeStepPercent;
      rung >= _rungs(metrics.minTypeScale);
      rung -= typeStepPercent
    ) {
      // No wrap test on the way down, and no air: smaller type breaks fewer
      // cells, not more, and a block that had to shrink has nothing spare.
      final t = rung / 100;
      if (probe((type: t, air: 1)).height <= available) {
        return (type: t, air: 1);
      }
    }
    return noFit;
  }

  var type = 1.0;
  var natural = official.height;
  for (
    var rung = _rungs(metrics.maxTypeScale);
    rung > 100;
    rung -= typeStepPercent
  ) {
    final t = rung / 100;
    final p = probe((type: t, air: 1));
    if (p.height <= available &&
        p.titleBreaks <= official.titleBreaks &&
        p.nameBreaks <= official.nameBreaks + nameTolerance) {
      type = t;
      natural = p.height;
      break;
    }
  }

  final maxAir = metrics.maxAirScale;
  final opened = probe((type: type, air: maxAir)).height;
  if (opened <= natural) return (type: type, air: 1);
  final air = 1 + (available - natural) / (opened - natural) * (maxAir - 1);
  return (type: type, air: air.clamp(1.0, maxAir));
}
