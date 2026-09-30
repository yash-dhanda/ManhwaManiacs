import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/brand_mark.g.dart';

/// The neutral Glass mark (glass 12.3): two stacked Ms in a column, drawn flat from the generated geometry.
class GlassMark extends StatelessWidget {
  const GlassMark({super.key, this.height = 96, this.color = GlassMarkGeometry.frost});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const col = GlassMarkGeometry.column;
    final w = height * col.width / col.height;
    return ExcludeSemantics(child: SizedBox(width: w, height: height, child: CustomPaint(painter: _MarkPainter(color))));
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const col = GlassMarkGeometry.column;
    final s = size.height / col.height;
    canvas
      ..save()
      ..scale(s)
      ..translate(-col.left, -col.top);
    Path poly(List<Offset> p) {
      final path = Path()..moveTo(p.first.dx, p.first.dy);
      for (final o in p.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      return path;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..strokeWidth = GlassMarkGeometry.stroke;
    canvas
      ..drawPath(poly(GlassMarkGeometry.topM), paint)
      ..drawPath(poly(GlassMarkGeometry.bottomM), paint)
      ..drawPath(GlassMarkGeometry.bar(), paint..strokeWidth = GlassMarkGeometry.barStroke)
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
