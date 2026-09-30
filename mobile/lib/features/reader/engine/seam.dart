
/// How far a chapter seam has travelled through the viewport: 0 when its top enters at the
/// bottom, 1 when its bottom leaves at the top; null when it does not overlap the viewport.
double? seamProgress(double seamTop, double seamHeight, double viewportHeight) {
  if (seamTop >= viewportHeight || seamTop + seamHeight <= 0) return null;
  return ((viewportHeight - seamTop) / (viewportHeight + seamHeight)).clamp(0.0, 1.0);
}

enum SeamEventKind { readingLine, top }

enum SeamDirection { forward, back }

class SeamEvent {
  const SeamEvent.readingLine(this.chapterId, this.direction) : kind = SeamEventKind.readingLine;
  const SeamEvent.top(this.chapterId)
      : kind = SeamEventKind.top,
        direction = SeamDirection.forward;
  final SeamEventKind kind;
  final String chapterId;
  final SeamDirection direction;

  @override
  String toString() => 'SeamEvent(${kind.name} $chapterId ${direction.name})';
}

/// Turns a seam's successive viewport positions into [SeamEvent]s, with a 4 px hysteresis so a seam
/// wobbling +-2 px around a line fires once.
class SeamWatcher {
  static const _hyst = 4.0;
  bool? _pastLine; // seam centre above the reading line
  bool? _pastTop;

  /// [seamTop] and [seamHeight] in viewport px; [readingLineY] is 38 % of the viewport height.
  List<SeamEvent> update(String chapterId, double seamTop, double seamHeight, double readingLineY) {
    final out = <SeamEvent>[];
    final centre = seamTop + seamHeight / 2;
    final line = centre - readingLineY; // > 0: still below the line
    final pl = _pastLine;
    if (pl == null) {
      _pastLine = line <= 0;
    } else if (!pl && line <= -_hyst) {
      _pastLine = true;
      out.add(SeamEvent.readingLine(chapterId, SeamDirection.forward));
    } else if (pl && line >= _hyst) {
      _pastLine = false;
      out.add(SeamEvent.readingLine(chapterId, SeamDirection.back));
    }
    final bottom = seamTop + seamHeight;
    final pt = _pastTop;
    if (pt == null) {
      _pastTop = bottom <= 0;
    } else if (!pt && bottom <= -_hyst) {
      _pastTop = true;
      out.add(SeamEvent.top(chapterId));
    } else if (pt && bottom >= _hyst) {
      _pastTop = false;
    }
    return out;
  }

  void reset() {
    _pastLine = null;
    _pastTop = null;
  }
}

