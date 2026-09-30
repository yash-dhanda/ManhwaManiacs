/// The ruler scrubber's geometry (cinematic 8.14.4), free of widgets.

/// Page ticks are dropped above this many pages.
const int kRulerTickLimit = 120;

/// The unit position (0..1) of [page] (1-based) on a track of [count] pages, mirrored for RTL.
double rulerUnit(int page, int count, {bool rtl = false}) {
  if (count <= 1) return rtl ? 1 : 0;
  final t = ((page - 1) / (count - 1)).clamp(0.0, 1.0);
  return rtl ? 1 - t : t;
}

/// The x of [page] on a track [width] wide.
double rulerX(int page, int count, double width, {bool rtl = false}) => rulerUnit(page, count, rtl: rtl) * width;

/// The page under [x] on a track [width] wide (1-based, clamped).
int rulerPage(double x, int count, double width, {bool rtl = false}) {
  if (count <= 1 || width <= 0) return 1;
  var t = (x / width).clamp(0.0, 1.0);
  if (rtl) t = 1 - t;
  return (t * (count - 1)).round() + 1;
}

/// Whether the ruler draws a tick per page.
bool rulerShowsTicks(int count) => count > 1 && count <= kRulerTickLimit;

/// The x of every page tick (empty above [kRulerTickLimit] pages).
List<double> rulerTickXs(int count, double width, {bool rtl = false}) =>
    rulerShowsTicks(count) ? [for (var p = 1; p <= count; p++) rulerX(p, count, width, rtl: rtl)] : const [];

/// The x of each bookmark (chapter-local page numbers).
List<double> rulerBookmarkXs(Iterable<int> pages, int count, double width, {bool rtl = false}) =>
    [for (final p in pages) rulerX(p.clamp(1, count < 1 ? 1 : count), count, width, rtl: rtl)];
