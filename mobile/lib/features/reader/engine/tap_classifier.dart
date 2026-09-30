import 'dart:ui';

/// What a tap turned out to be.
enum TapKind { single, double }

/// Tells a single tap from the second tap of a double tap, by time and distance. The window and
/// the slop are parameters: the legacy reader keeps 280 ms and no distance limit, the Cinematic
/// skin passes 300 ms and 24 px (cinematic 11).
class TapClassifier {
  TapClassifier({this.doubleTapWindow = const Duration(milliseconds: 280), this.doubleTapSlop});

  final Duration doubleTapWindow;

  /// Largest distance between the two taps, or null for none.
  final double? doubleTapSlop;

  ({DateTime at, Offset position})? _last;

  /// Classifies a tap at [position] made at [now]. A double resets, so a third tap is a single.
  TapKind classify(Offset position, DateTime now) {
    final last = _last;
    if (last != null &&
        now.difference(last.at) <= doubleTapWindow &&
        (doubleTapSlop == null || (position - last.position).distance <= doubleTapSlop!)) {
      _last = null;
      return TapKind.double;
    }
    _last = (at: now, position: position);
    return TapKind.single;
  }

  void reset() => _last = null;
}
