import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// A 2-up stat cell (glass 7.7): slab radius 26, padding 16: a 20 px glyph in `iris400`, a `numeral` value,
/// a label `footnote` `label2`, and an optional 7-point sparkline 24 px tall in `iris500`.
class GlassStatCard extends StatelessWidget {
  const GlassStatCard({super.key, required this.icon, required this.value, required this.label, this.spark, this.onTap});
  final IconData icon;
  final String value;
  final String label;

  /// Seven values, any scale.
  final List<double>? spark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GlassSlab(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        semanticsLabel: '$label, $value',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: gt.colorIris400),
            const SizedBox(height: 8),
            GlassLabel(value, role: gt.typeNumeral, color: gt.colorLabel1),
            GlassLabel(label, role: gt.typeFootnote, color: gt.colorLabel2),
            if (spark != null && spark!.length >= 2) ...[
              const SizedBox(height: 8),
              SizedBox(height: 24, width: double.infinity, child: CustomPaint(painter: _SparkPainter(spark!))),
            ],
          ],
        ),
      );
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final range = hi - lo == 0 ? 1.0 : hi - lo;
    final p = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - lo) / range * (size.height - 2) - 1;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = gt.colorIris500);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values;
}
