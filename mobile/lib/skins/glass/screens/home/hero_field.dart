import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/glass/palette.dart' show fieldColours;

/// The spotlight's own enlargement (glass 8.8): the palette's three blobs at 36 % behind the card area, radial gradients in one
/// `CustomPaint`, no filter. It is content, so it sits in the scroll and moves with it.
class HeroField extends StatelessWidget {
  const HeroField({super.key, required this.palette, this.opacity = 0.36});
  final CoverPalette? palette;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: HeroFieldPainter(palette, opacity), size: Size.infinite)));
}

class HeroFieldPainter extends CustomPainter {
  const HeroFieldPainter(this.palette, this.opacity);
  final CoverPalette? palette;
  final double opacity;

  static const List<Offset> anchors = [Offset(0.2, 0.3), Offset(0.8, 0.4), Offset(0.5, 0.75)];

  @override
  void paint(Canvas canvas, Size size) {
    final f = fieldColours(palette, moodColour(Mood.neutral));
    final r = size.shortestSide * 0.7;
    for (var i = 0; i < 3; i++) {
      final c = Offset(size.width * anchors[i].dx, size.height * anchors[i].dy);
      final radius = r * f.scales[i];
      canvas.drawCircle(
        c,
        radius,
        Paint()..shader = RadialGradient(colors: [f.colors[i].withValues(alpha: opacity), f.colors[i].withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(HeroFieldPainter old) => old.palette != palette || old.opacity != opacity;
}
