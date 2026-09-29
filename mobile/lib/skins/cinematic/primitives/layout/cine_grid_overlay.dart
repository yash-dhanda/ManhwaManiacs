import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Debug overlay: the columns at 6 % `spot` and the 4 px baseline at 4 % bone, shown while
/// `layoutGridOverlayProvider` is on. mobile/06 mounts it app-wide at `z.debug`.
class CineGridOverlay extends ConsumerWidget {
  const CineGridOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(layoutGridOverlayProvider)) return const SizedBox.shrink();
    final c = context.cine;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(painter: _GridPainter(CineGrid.of(context), c.colorSpot.withValues(alpha: 0.06), c.colorInk100.withValues(alpha: 0.04)), size: Size.infinite),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.grid, this.column, this.baseline);
  final CineGridSpec grid;
  final Color column, baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final cp = Paint()..color = column;
    for (var i = 0; i < grid.columns; i++) {
      canvas.drawRect(Rect.fromLTWH(grid.col(i), 0, grid.colWidth, size.height), cp);
    }
    final bp = Paint()
      ..color = baseline
      ..strokeWidth = 1;
    for (var y = 4.0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y - 0.5), Offset(size.width, y - 0.5), bp);
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => o.grid.width != grid.width || o.grid.left != grid.left || o.column != column;
}
