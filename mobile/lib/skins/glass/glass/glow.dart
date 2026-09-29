import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';

/// Where a press glow sits: a point in the surface's local coordinates and whether it is on.
@immutable
class GlassPressGlow {
  const GlassPressGlow(this.local, {required this.on});
  final Offset local;
  final bool on;
}

/// glass 2.4.2 rule 3: a `RadialGradient` of radius 140 px at the press point, `0x29FFFFFF` (tinted
/// `0x38BCB0FF`), in over 150 ms and out over 60 ms. Glass never dims on press.
class GlassGlowPainter extends CustomPainter {
  const GlassGlowPainter({required this.shape, required this.at, required this.amount, required this.tinted});

  final GlassShape shape;
  final Offset at;
  final double amount;
  final bool tinted;

  static const double radius = 140;
  static const Color regular = Color(0x29FFFFFF);
  static const Color tint = Color(0x38BCB0FF);

  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= 0) return;
    final c = tinted ? tint : regular;
    canvas.save();
    canvas.clipPath(shape.path(Offset.zero & size));
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          at,
          radius,
          [c.withValues(alpha: c.a * amount), c.withValues(alpha: 0)],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassGlowPainter old) => old.amount != amount || old.at != at || old.tinted != tinted || old.shape != shape;
}
