/// Signed px/s over a 100 ms window of `(timestamp, position)` samples; 0 after 100 ms without one.
class VelocityTracker100 {
  static const window = Duration(milliseconds: 100);
  final List<(Duration, double)> _s = [];

  void add(Duration t, double position) {
    _s.add((t, position));
    _trim(t);
  }

  void _trim(Duration now) {
    while (_s.isNotEmpty && now - _s.first.$1 > window) {
      _s.removeAt(0);
    }
  }

  void reset() => _s.clear();

  /// Velocity at [now] (defaults to the last sample's time).
  double velocity([Duration? now]) {
    if (_s.isEmpty) return 0;
    final at = now ?? _s.last.$1;
    if (at - _s.last.$1 >= window) return 0;
    _trim(at);
    if (_s.length < 2) return 0;
    final dt = (_s.last.$1 - _s.first.$1).inMicroseconds / 1e6;
    if (dt <= 0) return 0;
    return (_s.last.$2 - _s.first.$2) / dt;
  }
}
