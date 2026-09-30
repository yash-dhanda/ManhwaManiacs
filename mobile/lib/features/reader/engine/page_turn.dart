/// How a tap, key, volume key or the ruler turns a page (a swipe always tracks the finger).
enum PageTurn { cut, slide, fade }

/// A release commits to the neighbour when the drag passed [kTurnCommitPx] or the velocity
/// exceeds [kTurnCommitVelocity] (cinematic 11).
const double kTurnCommitPx = 72;
const double kTurnCommitVelocity = 600;

/// Whether a drag release turns the page. [dx] is the finger travel and [vx] its velocity along
/// the x axis (positive rightwards); [rtl] mirrors which way is forward. Returns the page step
/// (+1 forward, -1 back, 0 return) in reading order.
int turnDecision(double dx, double vx, {bool rtl = false}) {
  // Reading order: a leftward swipe goes forward in LTR, rightward in RTL.
  final d = rtl ? -dx : dx;
  final v = rtl ? -vx : vx;
  final passed = d.abs() >= kTurnCommitPx;
  final fast = v.abs() >= kTurnCommitVelocity;
  if (!passed && !fast) return 0;
  // The velocity wins the direction when it is what committed; else the travel does.
  final dir = fast && !passed ? v : d;
  if (dir == 0) return 0;
  return dir < 0 ? 1 : -1;
}

/// Pure commit decision: true when a release at [dx] px / [vx] px/s turns the page. [width] is
/// the viewport width (kept for the spread-step callers; the thresholds are absolute).
bool shouldCommitTurn(double dx, double vx, double width, {bool rtl = false}) => turnDecision(dx, vx, rtl: rtl) != 0;

/// The page a turn from [current] lands on: one page in a single layout, one whole view in a
/// double, clamped to 1..[pageCount]. [viewLeads] are the lead pages of each view (double only).
int turnTarget(int current, int step, int pageCount, {List<int>? viewLeads}) {
  if (viewLeads == null || viewLeads.isEmpty) return (current + step).clamp(1, pageCount);
  var i = viewLeads.lastIndexWhere((l) => l <= current);
  if (i < 0) i = 0;
  return viewLeads[(i + step).clamp(0, viewLeads.length - 1)];
}
