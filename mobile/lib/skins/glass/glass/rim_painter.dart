import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/core/color/oklch.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';

/// The tier's drop shadow, drawn only when the surface floats over content (glass 2.4.3).
class GlassShadowPainter extends CustomPainter {
  const GlassShadowPainter({required this.shape, required this.offsetY, required this.blur, required this.color});

  final GlassShape shape;
  final double offsetY;
  final double blur;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Offset.zero & size;
    final huge = Rect.fromLTWH(-2000, -2000, size.width + 4000, size.height + 4000);
    canvas.save();
    // Only the part outside the surface shows: glass never reads its own shadow.
    canvas.clipPath(Path.combine(PathOperation.difference, Path()..addRect(huge), shape.path(body)));
    canvas.drawPath(
      shape.path(body.shift(Offset(0, offsetY))),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassShadowPainter old) =>
      old.shape != shape || old.offsetY != offsetY || old.blur != blur || old.color != color;
}

/// A gradient running along the light: from the lit corner to the far corner of [rect] (CSS gradient line).
({Offset begin, Offset end}) lightLine(Rect rect, double angle) {
  final d = lightDirection(angle);
  final half = (d.dx.abs() * rect.width + d.dy.abs() * rect.height) / 2;
  final c = rect.center;
  return (begin: c - d * half, end: c + d * half);
}

/// The specular rim, the inner light and the Increase Contrast border of one surface.
///
/// The rim is 0.5 px, or one physical pixel on a DPR of 2 or more, a linear gradient along the light
/// angle with stops S at 0, 0.06 at 0.35, 0.02 at 0.65 and S x 0.55 at 1, its first stop mixed with the
/// field's rim tint at 18 % in OKLab (glass 2.4.4, 2.1.8).
class GlassRimPainter extends CustomPainter {
  const GlassRimPainter({
    required this.shape,
    required this.angle,
    required this.specular,
    required this.devicePixelRatio,
    this.rimTint,
    this.specularColor = const Color(0xFFFFFFFF),
    this.innerLight = true,
    this.solid = false,
    this.highContrast = false,
    this.opacity = 1,
    this.flatRim,
  });

  final GlassShape shape;
  final double angle;
  final double specular;
  final double devicePixelRatio;
  final Color? rimTint;
  final Color specularColor;

  /// T2 and up.
  final bool innerLight;

  /// The solid path: a flat 1 px `0x1AFFFFFF` rim and the inner light at S x 0.5.
  final bool solid;
  final bool highContrast;

  /// The materialise opacity ramp.
  final double opacity;

  /// A twin that fixes its rim colour (`onGlass`, `cover`, `tinted`) instead of the specular gradient.
  final Color? flatRim;

  static const Color hcBorder = Color(0x8CFFFFFF);
  static const Color solidRim = Color(0x1AFFFFFF);

  Color _white(double a) => specularColor.withValues(alpha: (a * specularColor.a).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (opacity < 1) {
      canvas.saveLayer(rect.inflate(4), Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)));
      _paint(canvas, size);
      canvas.restore();
    } else {
      _paint(canvas, size);
    }
  }

  void _paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final line = lightLine(rect, angle);
    ui.Shader gradient(List<Color> colors, List<double> stops) =>
        ui.Gradient.linear(line.begin, line.end, colors, stops);

    final w = devicePixelRatio >= 2 ? 1 / devicePixelRatio : 0.5;

    if (highContrast) {
      canvas.drawPath(
        shape.path(rect.deflate(0.5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = hcBorder,
      );
    }

    if (solid) {
      if (!highContrast) {
        canvas.drawPath(
          shape.path(rect.deflate(0.5)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = solidRim,
        );
      }
      _innerLight(canvas, rect, gradient, specular * 0.5, shade: false);
      return;
    }

    var firstColor = _white(specular);
    if (rimTint != null) firstColor = mixOklab(firstColor, rimTint!.withValues(alpha: firstColor.a), 0.18);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    if (flatRim != null) {
      rim.color = flatRim!;
    } else {
      rim.shader = gradient(
        [firstColor, _white(0.06), _white(0.02), _white(specular * 0.55)],
        const [0, 0.35, 0.65, 1],
      );
    }
    canvas.drawPath(shape.path(rect.deflate(w / 2)), rim);
    if (innerLight) _innerLight(canvas, rect, gradient, specular * 0.35, shade: true);
  }

  void _innerLight(Canvas canvas, Rect rect, ui.Shader Function(List<Color>, List<double>) gradient, double alpha, {required bool shade}) {
    canvas.drawPath(
      shape.path(rect.deflate(1.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = gradient(
          [_white(alpha), _white(0), const Color(0x00000000), shade ? const Color(0x59000000) : const Color(0x00000000)],
          const [0, 0.4, 0.6, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(GlassRimPainter old) =>
      old.shape != shape ||
      old.angle != angle ||
      old.specular != specular ||
      old.devicePixelRatio != devicePixelRatio ||
      old.rimTint != rimTint ||
      old.specularColor != specularColor ||
      old.innerLight != innerLight ||
      old.solid != solid ||
      old.highContrast != highContrast ||
      old.opacity != opacity ||
      old.flatRim != flatRim;
}
