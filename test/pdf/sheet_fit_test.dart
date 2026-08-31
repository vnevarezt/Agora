// How far a sheet is allowed to grow into its page.
//
// The rule is not "as big as fits": bigger type breaks cells onto a second
// line, and a sheet of broken cells reads worse than a smaller one. So the fit
// is capped by what the OFFICIAL size already breaks, and the leftover height
// goes into the row spacing instead.
//
// Only the two-per-sheet layout is allowed to do any of this. The one-week
// sheet is the official form and is pinned to its official size — see the last
// test here.

import 'package:agora/pdf/pdf_theme.dart';
import 'package:agora/pdf/sheet_fit.dart';
import 'package:flutter_test/flutter_test.dart';

/// The layout that fills its page: two weeks on one sheet.
const _fit = S140Metrics.compact;

/// A block whose height grows in proportion to the type and by [airCost] for
/// each extra unit of air, and which starts breaking cells once the type
/// passes [breaksAbove]. [breaksNames] picks which of the two counters the
/// breakage lands in.
SheetProbe Function(SheetFit) _block({
  required double natural,
  double airCost = 100,
  double breaksAbove = double.infinity,
  int officialBreaks = 0,
  bool breaksNames = false,
}) => (f) {
  final broken = officialBreaks + (f.type > breaksAbove + 1e-9 ? 3 : 0);
  return (
    height: natural * f.type + (f.air - 1) * airCost,
    titleBreaks: breaksNames ? 0 : broken,
    nameBreaks: breaksNames ? broken : 0,
  );
};

void main() {
  test('a one-week sheet that overflows is left exactly as it is', () {
    final fit = fitSheet(
      probe: _block(natural: 800),
      available: 700,
      metrics: S140Metrics.standard,
    );

    expect(
      S140Metrics.standard.minTypeScale,
      1,
      reason: 'this sheet may flow to a second page',
    );
    expect(
      fit,
      noFit,
      reason: 'the caller decides what to do about an overflow, not the fit',
    );
  });

  test('a sheet that cannot flow shrinks its type instead of overflowing', () {
    // The two-week sheet is one page by definition. Overflowing it means the
    // FittedBox photo-reduces the block, which gives back the WIDTH too and
    // dumps the whole reduction into the right margin. Shrinking only the type
    // keeps the full measure.
    final fit = fitSheet(
      probe: _block(natural: 800),
      available: 700,
      metrics: _fit,
    );

    expect(fit.type, lessThan(1));
    expect(fit.type, greaterThanOrEqualTo(_fit.minTypeScale));
    expect(fit.air, 1, reason: 'a block that had to shrink has nothing spare');
  });

  test('shrinking still gives up when the block is hopeless', () {
    final fit = fitSheet(
      probe: _block(natural: 2000),
      available: 700,
      metrics: _fit,
    );

    expect(fit, noFit);
  });

  test('a light block grows to the ceiling and stops there', () {
    final fit = fitSheet(
      probe: _block(natural: 200),
      available: 700,
      metrics: _fit,
    );

    expect(fit.type, _fit.maxTypeScale);
  });

  test('the type stops before the size that breaks more cells', () {
    // 1.10 would fit twice over on height alone; anything past it is refused
    // because a title no longer holds its line there.
    final fit = fitSheet(
      probe: _block(natural: 200, breaksAbove: 1.10),
      available: 700,
      metrics: _fit,
    );

    expect(fit.type, closeTo(1.10, 1e-9));
  });

  test('an auxiliary-room sheet may buy a size with a stacked pair', () {
    // The one sheet short of width: three columns of names on one page, and
    // no step of type that does not stack a pair. See [S140.auxNameTolerance].
    final fit = fitSheet(
      probe: _block(natural: 200, breaksAbove: 1.10, breaksNames: true),
      available: 700,
      metrics: _fit,
      nameTolerance: 3,
    );

    expect(fit.type, _fit.maxTypeScale);
  });

  test('a size that stacks a pair of names is refused just the same', () {
    // Held apart from the titles on purpose: counted as one total, a size
    // could stack a pair to unwrap a title and come out level. Unstacking the
    // names is the point of the whole layout, so they never get worse.
    final fit = fitSheet(
      probe: _block(natural: 200, breaksAbove: 1.10, breaksNames: true),
      available: 700,
      metrics: _fit,
    );

    expect(fit.type, closeTo(1.10, 1e-9));
  });

  test('a sheet that already breaks cells may still grow', () {
    // An auxiliary-room sheet with long titles wraps at every size, the
    // official one included. Holding it to zero breaks would freeze it at 10 pt
    // for a standard it never met.
    final fit = fitSheet(
      probe: _block(natural: 200, officialBreaks: 4),
      available: 700,
      metrics: _fit,
    );

    expect(fit.type, _fit.maxTypeScale);
  });

  test('the air opens up to land on the bottom of the page', () {
    final probe = _block(natural: 400, breaksAbove: 1.0, airCost: 400);
    final fit = fitSheet(probe: probe, available: 500, metrics: _fit);

    expect(fit.type, 1.0, reason: 'growing the type would break a cell');
    expect(probe(fit).height, closeTo(500, 1e-9));
  });

  test('the air stops at its ceiling rather than filling any page', () {
    final fit = fitSheet(
      probe: _block(natural: 300, breaksAbove: 1.0, airCost: 10),
      available: 700,
      metrics: _fit,
    );

    expect(fit.air, _fit.maxAirScale);
  });

  test('the official one-week sheet is never opened up at all', () {
    // Its ceilings are 1: whatever room is left on the page, the block keeps
    // the size and the spacing the form specifies. Growing the type and
    // spreading the rows to the foot of the paper did fill it, and stopped it
    // looking like the form — not a trade this sheet makes.
    const official = S140Metrics.standard;
    expect(official.maxTypeScale, 1.0);
    expect(official.maxAirScale, 1.0);

    final fit = fitSheet(
      probe: _block(natural: 200), // barely a third of the page
      available: 700,
      metrics: official,
    );

    expect(fit, noFit);
  });

  test('a block that fills the page on its own is left unopened', () {
    final fit = fitSheet(
      probe: _block(natural: 700, breaksAbove: 1.0),
      available: 700,
      metrics: _fit,
    );

    expect(fit, noFit);
  });
}
