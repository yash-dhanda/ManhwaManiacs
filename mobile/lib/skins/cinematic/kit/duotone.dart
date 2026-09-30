import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// `#RRGGBB` to a [Color]; [fallback] (the ambient duo) when absent or malformed.
Color parseHex(String? hex, {Color fallback = CineColors.ambientFallbackDuo}) {
  if (hex == null) return fallback;
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return fallback;
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

/// The duotone matrix (§2.1.5): luminance maps black -> [duo] scaled, so an
/// image keeps its shading in one hue.
ColorFilter duotoneFilter(Color duo) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final r = duo.r, g = duo.g, b = duo.b;
  return ColorFilter.matrix(<double>[
    lr * r, lg * r, lb * r, 0, 0,
    lr * g, lg * g, lb * g, 0, 0,
    lr * b, lg * b, lb * b, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// A duotoned image with grain at [grain] opacity (0.06).
class DuotoneImage extends StatelessWidget {
  const DuotoneImage({super.key, required this.image, required this.duo, this.grain = 0.06, this.fit = BoxFit.cover, this.error});

  final ImageProvider image;
  final Color duo;
  final double grain;
  final BoxFit fit;
  final Widget? error;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Stack(fit: StackFit.expand, children: [
          ColorFiltered(
            colorFilter: duotoneFilter(duo),
            child: Image(image: image, fit: fit, gaplessPlayback: true, errorBuilder: (_, __, ___) => error ?? const ColoredBox(color: CineColors.paper1), frameBuilder: (context, child, frame, sync) => frame == null && !sync ? const ColoredBox(color: CineColors.paper1) : child),
          ),
          Grain(opacity: grain),
        ],),
      );
}

/// Static film grain: a fixed-seed dot field at [opacity].
class Grain extends StatelessWidget {
  const Grain({super.key, this.opacity = 0.06});
  final double opacity;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: IgnorePointer(child: CustomPaint(painter: _GrainPainter(opacity), size: Size.infinite)));
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter(this.opacity);
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;
    final rnd = math.Random(7);
    final n = ((size.width * size.height) / 90).clamp(200, 9000).toInt();
    final light = <Offset>[];
    final dark = <Offset>[];
    for (var i = 0; i < n; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      (rnd.nextBool() ? light : dark).add(p);
    }
    canvas.drawPoints(PointMode.points, light, Paint()..color = Colors.white.withValues(alpha: opacity * 2)..strokeWidth = 1.2);
    canvas.drawPoints(PointMode.points, dark, Paint()..color = Colors.black.withValues(alpha: opacity * 2)..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.opacity != opacity;
}
