import 'dart:math' as math;
import 'dart:ui';

import 'package:manhwamaniacs/features/reader/engine/camera.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';

/// Guided view geometry (glass 9.4.3, 4.3, 4.6, 11). Pure: the view calls these and owns the pixels.

/// The camera pose that fits [panel] (viewport px at scale 1) in [viewport] minus [padding] on every side, width or height whichever
/// binds, never above [maxScale] (3x). Centred.
CameraPose frameRect(Rect panel, Size viewport, {double padding = 24, double maxScale = 3}) =>
    CameraPose.of(fitRect(panel, viewport, margin: padding, maxScale: maxScale));

/// Where a panel taller than the viewport is walked: stops at `k x 0.8 V` while `k x 0.8 V < H - V`, then `H - V` (bottom-aligned).
/// [h] is the panel's height as framed and [v] the viewport height, both in px. A panel that fits gives `[0]`.
List<double> walkSteps(double h, double v) {
  if (h <= v) return const [0];
  final out = <double>[];
  for (var k = 0; k * 0.8 * v < h - v - 1e-9; k++) {
    out.add(k * 0.8 * v);
  }
  out.add(h - v);
  return out;
}

/// A position in the chapter: a page (1-based) and a panel on it (0-based).
class GuidedPos {
  const GuidedPos(this.page, this.panel);
  final int page, panel;

  @override
  bool operator ==(Object other) => other is GuidedPos && other.page == page && other.panel == panel;
  @override
  int get hashCode => Object.hash(page, panel);
  @override
  String toString() => 'GuidedPos($page, $panel)';
}

/// The next panel, crossing pages: the first panel of the next page after the last of this one. A page without panels counts as one
/// whole-page stop. Null past the last page. [counts] is panels per page (index 0 is page 1; 0 means the whole page).
GuidedPos? nextPanel(GuidedPos at, List<int> counts) {
  final here = math.max(1, counts[at.page - 1]);
  if (at.panel + 1 < here) return GuidedPos(at.page, at.panel + 1);
  if (at.page < counts.length) return GuidedPos(at.page + 1, 0);
  return null;
}

/// The previous panel, crossing pages: the last panel of the previous page. Null before the first.
GuidedPos? previousPanel(GuidedPos at, List<int> counts) {
  if (at.panel > 0) return GuidedPos(at.page, at.panel - 1);
  if (at.page > 1) return GuidedPos(at.page - 1, math.max(1, counts[at.page - 2]) - 1);
  return null;
}

/// A horizontal swipe's direction as a step: a left swipe goes forward, mirrored for right-to-left series. [dx] is the drag, [vx] the
/// release velocity; +1 forward, -1 back, 0 when it does not commit.
int swipeStep(double dx, double vx, {required bool rtl}) {
  if (!swipeCommits(dx, vx)) return 0;
  final left = dx != 0 ? dx < 0 : vx < 0;
  return (rtl ? !left : left) ? 1 : -1;
}

/// A tap on the side bands (30 %): the right band moves forward, the left back; mirrored for right-to-left. 0 in the centre.
int bandStep(double x, double width, {required bool rtl}) {
  final f = width <= 0 ? 0.5 : x / width;
  if (f > 0.7) return rtl ? -1 : 1;
  if (f < 0.3) return rtl ? 1 : -1;
  return 0;
}

/// A drag commits at 50 px or 500 px/s.
bool swipeCommits(double dx, double vx) => dx.abs() >= 50 || vx.abs() >= 500;

/// Direction lock: horizontal once `|dx| > 2 |dy|` after the slop.
bool horizontalLocked(double dx, double dy) => dx.abs() > 2 * dy.abs();

/// A downward drag leaves guided view when its projection `project(dy, vy)` passes 120 px.
bool exitByProjection(double dy, double vy) => project(dy, vy) > 120;

/// "Panel 4 of 38 · Page 7" once every page of the chapter has a panel result, otherwise "Panel 4 · Page 7"; "Finding panels…" while
/// the page is being analysed; "Page 7 · whole page" for a page with no panels.
String counterText({required int page, required int panel, required int panelsBefore, int? total, required bool finding, required bool whole}) {
  if (finding) return 'Finding panels…';
  if (whole) return 'Page $page · whole page';
  final n = panelsBefore + panel + 1;
  return total == null ? 'Panel $n · Page $page' : 'Panel $n of $total · Page $page';
}

/// The polite announcement of a step: "Panel 4 of 38, page 7".
String announcement({required int page, required int panel, required int panelsBefore, int? total}) {
  final n = panelsBefore + panel + 1;
  return total == null ? 'Panel $n, page $page' : 'Panel $n of $total, page $page';
}
