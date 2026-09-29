import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A glass silhouette (glass 2.3): capsule, circle, or a squircle of a given radius.
sealed class GlassShape {
  const GlassShape();
  const factory GlassShape.capsule() = _Capsule;
  const factory GlassShape.circle() = _Circle;
  const factory GlassShape.superellipse(double radius) = _Superellipse;

  /// The corner radius this shape has inside [size].
  double radiusFor(Size size);

  /// The continuous-corner border used to clip and to outline this shape.
  RoundedSuperellipseBorder border(Size size) => RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radiusFor(size)));

  Path path(Rect rect) => border(rect.size).getOuterPath(rect);

  bool get isCircle => false;
}

class _Capsule extends GlassShape {
  const _Capsule();
  @override
  double radiusFor(Size size) => size.shortestSide / 2;
}

class _Circle extends GlassShape {
  const _Circle();
  @override
  bool get isCircle => true;
  @override
  double radiusFor(Size size) => size.shortestSide / 2;
}

class _Superellipse extends GlassShape {
  const _Superellipse(this.radius);
  final double radius;
  @override
  double radiusFor(Size size) => math.min(radius, size.shortestSide / 2);
}

/// CSS-style angle (from up, clockwise) to a unit vector; 135 degrees points down-right.
Offset lightDirection(double radians) => Offset(math.sin(radians), -math.cos(radians));
