/// Pace of the reader: pages per minute over the samples since the chapter opened (cinematic
/// 8.14.3 "time left"). Null until [minWindow] of samples exist, so the caption never guesses.
class PaceTracker {
  PaceTracker({this.minWindow = const Duration(minutes: 2)});

  final Duration minWindow;
  ({int page, DateTime at})? _first;
  ({int page, DateTime at})? _last;

  /// Records that the reader is on [page] at [now]. Moving backwards restarts the window.
  void sample(int page, DateTime now) {
    final last = _last;
    if (_first == null || last == null || page < last.page) {
      _first = (page: page, at: now);
    }
    _last = (page: page, at: now);
  }

  /// Pages per minute, or null while under [minWindow] of samples or with no forward progress.
  double? get pagesPerMinute {
    final f = _first, l = _last;
    if (f == null || l == null) return null;
    final span = l.at.difference(f.at);
    if (span < minWindow) return null;
    final pages = l.page - f.page;
    if (pages <= 0) return null;
    return pages / (span.inMilliseconds / 60000);
  }
}

/// Whole minutes left in a chapter of [pageCount] pages when the reader is on [page], at
/// [pagesPerMinute]. Null when the pace is unknown.
int? minutesLeft({required int page, required int pageCount, required double? pagesPerMinute}) {
  if (pagesPerMinute == null || pagesPerMinute <= 0) return null;
  final remaining = (pageCount - page).clamp(0, pageCount);
  return (remaining / pagesPerMinute).ceil();
}
