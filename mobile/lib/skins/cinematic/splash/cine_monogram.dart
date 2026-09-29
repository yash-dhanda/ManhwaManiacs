import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/brand_mark.g.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The monogram (cinematic 12.2): the upright and italic M's in bone over the 1024 canvas,
/// scaled so the mark is [width] px wide (112 on phones, 160 on tablets), the intersection filled
/// `#000000` at first and taking `spot` as [intersection] goes 0 -> 1, with a blurred `spot.glow`
/// bloom behind it (opacity 0 -> [glow]).
class CineMonogram extends StatelessWidget {
  const CineMonogram({super.key, required this.width, this.intersection = 0, this.glow = 0});
  final double width;

  /// 0..1: how far the intersection has turned from black to `spot`.
  final double intersection;

  /// Bloom opacity, 0..0.35.
  final double glow;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final bounds = CineMarkPaths.upright().getBounds().expandToInclude(CineMarkPaths.italic().getBounds());
    final scale = width / bounds.width;
    return SizedBox(
      width: width,
      height: bounds.height * scale,
      child: CustomPaint(
        painter: _MonogramPainter(
          bounds: bounds,
          scale: scale,
          bone: c.colorInk100,
          spot: c.colorSpot,
          glowColor: c.colorSpotGlow,
          intersection: intersection,
          glow: glow,
        ),
      ),
    );
  }
}

class _MonogramPainter extends CustomPainter {
  _MonogramPainter({
    required this.bounds,
    required this.scale,
    required this.bone,
    required this.spot,
    required this.glowColor,
    required this.intersection,
    required this.glow,
  });
  final Rect bounds;
  final double scale, intersection, glow;
  final Color bone, spot, glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(scale)
      ..translate(-bounds.left, -bounds.top);
    final inter = CineMarkPaths.intersection();
    if (glow > 0) {
      canvas.drawCircle(
        inter.getBounds().center,
        inter.getBounds().longestSide * 0.9,
        Paint()
          ..color = glowColor.withValues(alpha: glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 / scale),
      );
    }
    final bonePaint = Paint()..color = bone;
    canvas
      ..drawPath(CineMarkPaths.upright(), bonePaint)
      ..drawPath(CineMarkPaths.italic(), bonePaint)
      ..drawPath(inter, Paint()..color = Color.lerp(const Color(0xFF000000), spot, intersection)!)
      ..restore();
  }

  @override
  bool shouldRepaint(_MonogramPainter o) => o.intersection != intersection || o.glow != glow || o.scale != scale;
}
