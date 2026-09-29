import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Column wipe geometry (cinematic 8.14.2). Pure.
///
/// The viewport is divided into the grid's columns, margins and gutters included: 4 blades below
/// 600 px, 8 from 600 px (the app never uses 12). Blade i runs from column i's left edge (the
/// first from x = 0) to column i + 1's left edge (the last to the right edge), so blade edges land
/// on column edges and the margins and gutters are covered.
int wipeBladeCount(double width) => width >= 600 ? 8 : 4;

typedef WipeBlade = ({double left, double right});

List<WipeBlade> wipeBlades(double width, {double viewLeft = 0, double viewRight = 0}) {
  final g = CineGrid.resolve(width, viewLeft: viewLeft, viewRight: viewRight);
  return [
    for (var i = 0; i < g.columns; i++)
      (
        left: i == 0 ? 0.0 : g.col(i),
        right: i == g.columns - 1 ? width : g.col(i + 1),
      ),
  ];
}

const int kWipeStaggerMs = 16;
const int kWipeHoldMs = 40;

int wipeCloseMs(int blades) => CineDur.wipeClose.inMilliseconds + (blades - 1) * kWipeStaggerMs;
int wipeOpenMs(int blades) => CineDur.wipeOpen.inMilliseconds + (blades - 1) * kWipeStaggerMs;

/// 616 ms for 4 blades, 744 ms for 8.
int wipeTotalMs(int blades) => wipeCloseMs(blades) + kWipeHoldMs + wipeOpenMs(blades);

/// One blade's `scaleY` at [ms] on the wipe clock: 0 -> 1 from the top while closing, hold, then
/// 1 -> 0 toward the bottom while opening. Returns (scale, fromTop).
({double scale, bool fromTop}) wipeBladeAt(int index, int blades, double ms) {
  final closeEnd = wipeCloseMs(blades);
  final openStart = closeEnd + kWipeHoldMs;
  final stagger = index * kWipeStaggerMs;
  if (ms < openStart) {
    final p = ((ms - stagger) / CineDur.wipeClose.inMilliseconds).clamp(0.0, 1.0);
    return (scale: CineCurves.settle.transform(p), fromTop: true);
  }
  final p = ((ms - openStart - stagger) / CineDur.wipeOpen.inMilliseconds).clamp(0.0, 1.0);
  return (scale: 1 - CineCurves.settle.transform(p), fromTop: false);
}

enum WipePhase { close, hold, open }

WipePhase wipePhaseAt(double ms, int blades) {
  final closeEnd = wipeCloseMs(blades);
  if (ms < closeEnd) return WipePhase.close;
  if (ms < closeEnd + kWipeHoldMs) return WipePhase.hold;
  return WipePhase.open;
}

/// Paints the blades: each `#000`, `scaleY` 0 -> 1 from the top edge while closing (200 ms
/// `settle`, staggered 16 ms left to right), 40 ms hold, then 1 -> 0 toward the bottom edge (280 ms
/// `settle`, the same stagger), as intervals of one route animation. [progress] is the route
/// animation's value over [wipeTotalMs]`(blades)`.
class ColumnWipePainter extends CustomPainter {
  ColumnWipePainter({required this.progress, required this.blades, this.phase, this.viewLeft = 0, this.viewRight = 0, this.opacity = 1});

  final double progress;
  final int blades;

  /// Derived from [progress] when null.
  final WipePhase? phase;
  final double viewLeft, viewRight;
  final double opacity;

  double get ms => progress * wipeTotalMs(blades);

  @override
  void paint(Canvas canvas, Size size) {
    final geo = wipeBlades(size.width, viewLeft: viewLeft, viewRight: viewRight);
    final paint = Paint()..color = Color.fromRGBO(0, 0, 0, opacity);
    final n = geo.length;
    for (var i = 0; i < n; i++) {
      final b = wipeBladeAt(i, n, ms);
      if (b.scale <= 0) continue;
      final h = size.height * b.scale;
      final top = b.fromTop ? 0.0 : size.height - h;
      // Overlap by half a pixel so no seam shows between blades.
      canvas.drawRect(Rect.fromLTRB(geo[i].left, top, geo[i].right + 0.5, top + h), paint);
    }
  }

  @override
  bool shouldRepaint(ColumnWipePainter o) =>
      o.progress != progress || o.blades != blades || o.opacity != opacity || o.viewLeft != viewLeft || o.viewRight != viewRight;
}
