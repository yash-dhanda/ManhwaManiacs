import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/glass/rim_painter.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';

/// Implemented by a surface that can play the specular sweep.
abstract interface class GlassSweepTarget {
  Future<void> playSweep();
}

/// One sweep at a time; a request within 300 ms of the last start is dropped (glass 2.4.4).
abstract final class GlassSweep {
  static const Duration minGap = Duration(milliseconds: 300);

  /// Test seam for the clock.
  @visibleForTesting
  static Duration Function() now = () => Duration(microseconds: DateTime.now().microsecondsSinceEpoch);

  static bool _running = false;
  static Duration? _lastStart;

  @visibleForTesting
  static void reset() {
    _running = false;
    _lastStart = null;
  }

  /// Plays a sweep on [target]; false when it was dropped.
  static bool request(GlassSweepTarget target) {
    final t = now();
    if (_running) return false;
    if (_lastStart != null && t - _lastStart! < minGap) return false;
    _running = true;
    _lastStart = t;
    target.playSweep().whenComplete(() => _running = false);
    return true;
  }
}

/// A 40 px band `0x2EFFFFFF` crossing the shape along the light angle, lit corner to far corner.
class GlassSweepPainter extends CustomPainter {
  const GlassSweepPainter({required this.shape, required this.angle, required this.progress});

  final GlassShape shape;
  final double angle;
  final double progress;

  static const double band = 40;
  static const Color color = Color(0x2EFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rect = Offset.zero & size;
    final d = lightDirection(angle);
    final line = lightLine(rect, angle);
    final length = (line.end - line.begin).distance;
    final pos = -band / 2 + progress * (length + band);
    final centre = line.begin + d * pos;
    canvas.save();
    canvas.clipPath(shape.path(rect));
    canvas.drawRect(
      rect.inflate(band),
      Paint()
        ..shader = ui.Gradient.linear(
          centre - d * (band / 2),
          centre + d * (band / 2),
          [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
          const [0, 0.5, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassSweepPainter old) => old.progress != progress || old.angle != angle || old.shape != shape;
}
