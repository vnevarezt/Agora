/// Hybrid logical clock (docs/DATA_ARCHITECTURE.md §4): wall-clock ms +
/// counter + device id. Total order across devices even with clock skew —
/// the counter breaks ties when the wall clock stalls or jumps backwards.
///
/// Encoded as a fixed-width lexicographically-sortable string:
/// `0001752601402114-0003-a1b2c3d4` (16-digit ms · 4-hex counter · device).
class Hlc implements Comparable<Hlc> {
  const Hlc(this.physicalMs, this.counter, this.deviceId);

  final int physicalMs;
  final int counter;
  final String deviceId;

  static Hlc? tryParse(String s) {
    final parts = s.split('-');
    if (parts.length < 3) return null;
    final ms = int.tryParse(parts[0]);
    final counter = int.tryParse(parts[1], radix: 16);
    if (ms == null || counter == null) return null;
    return Hlc(ms, counter, parts.sublist(2).join('-'));
  }

  String encode() => '${physicalMs.toString().padLeft(16, '0')}-'
      '${counter.toRadixString(16).padLeft(4, '0')}-$deviceId';

  @override
  int compareTo(Hlc other) {
    if (physicalMs != other.physicalMs) {
      return physicalMs.compareTo(other.physicalMs);
    }
    if (counter != other.counter) return counter.compareTo(other.counter);
    return deviceId.compareTo(other.deviceId);
  }

  @override
  String toString() => encode();
}

/// Issues monotonic [Hlc] stamps for THIS device. `receive` folds in stamps
/// seen elsewhere (or persisted before a restart) so new stamps always sort
/// after everything already observed.
class HlcClock {
  HlcClock(this.deviceId, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final String deviceId;
  final DateTime Function() _now;

  int _lastMs = 0;
  int _lastCounter = 0;

  Hlc next() {
    final wall = _now().toUtc().millisecondsSinceEpoch;
    if (wall > _lastMs) {
      _lastMs = wall;
      _lastCounter = 0;
    } else {
      _lastCounter++;
    }
    return Hlc(_lastMs, _lastCounter, deviceId);
  }

  /// Advances past [other] (an observed stamp) without issuing one.
  void receive(Hlc other) {
    if (other.physicalMs > _lastMs) {
      _lastMs = other.physicalMs;
      _lastCounter = other.counter;
    } else if (other.physicalMs == _lastMs &&
        other.counter > _lastCounter) {
      _lastCounter = other.counter;
    }
  }
}
