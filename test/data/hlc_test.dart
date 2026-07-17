import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/hlc.dart';

void main() {
  test('encode/parse roundtrip and lexicographic order matches compareTo',
      () {
    const a = Hlc(1752601402114, 3, 'aaaa1111');
    final parsed = Hlc.tryParse(a.encode())!;
    expect(parsed.physicalMs, a.physicalMs);
    expect(parsed.counter, a.counter);
    expect(parsed.deviceId, a.deviceId);

    const later = Hlc(1752601402115, 0, 'aaaa1111');
    const sameMsHigherCounter = Hlc(1752601402114, 4, 'aaaa1111');
    expect(a.encode().compareTo(later.encode()) < 0, true);
    expect(a.encode().compareTo(sameMsHigherCounter.encode()) < 0, true);
    expect(a.compareTo(later) < 0, true);
    expect(a.compareTo(sameMsHigherCounter) < 0, true);
  });

  test('clock is monotonic through a stalled or regressing wall clock', () {
    var wall = DateTime.utc(2026, 7, 16, 10);
    final clock = HlcClock('dev1', now: () => wall);

    final first = clock.next();
    final stalled = clock.next(); // same wall ms → counter bumps
    expect(stalled.compareTo(first) > 0, true);
    expect(stalled.counter, first.counter + 1);

    wall = wall.subtract(const Duration(minutes: 5)); // clock jumped back
    final regressed = clock.next();
    expect(regressed.compareTo(stalled) > 0, true,
        reason: 'stamps never go backwards');

    wall = DateTime.utc(2026, 7, 16, 11); // clock recovered
    final recovered = clock.next();
    expect(recovered.counter, 0);
    expect(recovered.compareTo(regressed) > 0, true);
  });

  test('receive folds observed stamps in so new ones sort after them', () {
    var wall = DateTime.utc(2026, 7, 16, 10);
    final clock = HlcClock('dev1', now: () => wall);
    final observed =
        Hlc(wall.add(const Duration(hours: 2)).millisecondsSinceEpoch, 7, 'dev2');

    clock.receive(observed);
    final next = clock.next();
    expect(next.compareTo(observed) > 0, true);
  });
}
