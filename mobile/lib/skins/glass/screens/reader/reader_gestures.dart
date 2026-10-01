import 'dart:ui';

/// Double tap (glass 4.6, 11): a second tap within 280 ms and 24 px.
const Duration kGlassDoubleTapWindow = Duration(milliseconds: 280);
const double kGlassDoubleTapSlop = 24;

/// The 30 / 40 / 30 tap bands.
const List<double> kGlassTapBands = [0.30, 0.70];

enum TapBand { left, centre, right }

TapBand tapBandOf(double x, double width) {
  final f = width <= 0 ? 0.5 : x / width;
  if (f < kGlassTapBands[0]) return TapBand.left;
  if (f >= kGlassTapBands[1]) return TapBand.right;
  return TapBand.centre;
}

enum TapZoneAction { previous, menu, next }

/// What a tap does. [zones] are the reader's own three bands (left, centre, right), or null for automatic (mirrored for
/// right-to-left).
TapZoneAction pagedTapAction(TapBand band, {required bool rtl, List<TapZoneAction>? zones}) {
  if (zones != null && zones.length == 3) return zones[band.index];
  return switch (band) {
    TapBand.left => rtl ? TapZoneAction.next : TapZoneAction.previous,
    TapBand.right => rtl ? TapZoneAction.previous : TapZoneAction.next,
    TapBand.centre => TapZoneAction.menu,
  };
}

/// "Tap to scroll" in the strip: the top third and the left-middle go back 75 %, the bottom third and the right-middle forward,
/// the centre toggles the chrome.
TapZoneAction stripScrollTapAction(Offset p, Size s) {
  final fy = p.dy / s.height, fx = p.dx / s.width;
  if (fy < 1 / 3) return TapZoneAction.previous;
  if (fy >= 2 / 3) return TapZoneAction.next;
  if (fx < kGlassTapBands[0]) return TapZoneAction.previous;
  if (fx >= kGlassTapBands[1]) return TapZoneAction.next;
  return TapZoneAction.menu;
}

/// Whether a double tap may be recognised at [p]: everywhere in the plain strip; only in the centre band in paged mode and
/// with Tap to scroll on (a side-band tap acts at once, without a double-tap window).
bool doubleTapAllowedAt(Offset p, Size s, {required bool paged, required bool tapToScroll}) {
  if (!paged && !tapToScroll) return true;
  if (paged) return tapBandOf(p.dx, s.width) == TapBand.centre;
  return stripScrollTapAction(p, s) == TapZoneAction.menu;
}

/// Two taps make a double when the second lands within the window and the slop.
bool isDoubleTap({required Duration gap, required double distance}) =>
    gap <= kGlassDoubleTapWindow && distance <= kGlassDoubleTapSlop;

/// The centre region of locked mode's five-tap unlock: 20-80 % x 15-85 %.
bool inUnlockRegion(Offset p, Size s) {
  final fx = p.dx / s.width, fy = p.dy / s.height;
  return fx >= 0.2 && fx <= 0.8 && fy >= 0.15 && fy <= 0.85;
}

/// Counts unlock taps: five inside the region within 2 s.
class UnlockCounter {
  final List<DateTime> _taps = [];

  /// Returns the count so far (5 unlocks and resets).
  int tap(DateTime now) {
    _taps
      ..removeWhere((t) => now.difference(t) > const Duration(seconds: 2))
      ..add(now);
    final n = _taps.length;
    if (n >= 5) _taps.clear();
    return n;
  }
}
