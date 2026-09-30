import 'package:flutter/widgets.dart';

/// `color.matte.guided` (black at 85 %) over the whole viewport with the current panel's viewport
/// rect cut out, so the rest of the page reads at 15 %. One `CustomPainter`, moving with the camera.
class GuidedMatte extends StatelessWidget {
  const GuidedMatte({super.key, required this.panel, required this.color});

  /// The panel's rect in viewport px, or null for no cut-out (a whole page is not dimmed).
  final Rect? panel;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(painter: _MattePainter(panel, color), size: Size.infinite),
      );
}

class _MattePainter extends CustomPainter {
  const _MattePainter(this.panel, this.color);
  final Rect? panel;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = panel;
    if (p == null) return;
    final path = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRect(p));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MattePainter old) => old.panel != panel || old.color != color;
}
