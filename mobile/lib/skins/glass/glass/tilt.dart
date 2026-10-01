import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/widgets.dart' show Matrix4;

/// The hero card's tilt in radians (glass 2.4.2 rule 5): [x] rotates about the horizontal axis (pitch), [y] about the vertical (roll).
typedef HeroTiltAngles = ({double x, double y});

const double kHeroTiltMax = 6 * math.pi / 180;
const double _range = 30 * math.pi / 180;

/// The tilt for a gravity reading [g] (in g, screen-plane components) relative to the [pose] captured when Home subscribed:
/// `roll = asin(clamp(dx))`, `pitch = asin(clamp(dy))`, `rotateY = 6 deg x clamp(roll / 30 deg)`, `rotateX = -6 deg x clamp(pitch / 30 deg)`.
HeroTiltAngles heroTiltFromGravity(Offset g, {Offset pose = Offset.zero}) {
  final d = g - pose;
  final roll = math.asin(d.dx.clamp(-1.0, 1.0));
  final pitch = math.asin(d.dy.clamp(-1.0, 1.0));
  return (y: kHeroTiltMax * (roll / _range).clamp(-1.0, 1.0), x: -kHeroTiltMax * (pitch / _range).clamp(-1.0, 1.0));
}

/// The pointer's tilt over a card of [size] (tablet and desktop frames): the same +-6 degrees across the half extents.
HeroTiltAngles heroTiltFromPointer(Offset local, Offset size) {
  final nx = ((local.dx - size.dx / 2) / (size.dx / 2)).clamp(-1.0, 1.0);
  final ny = ((local.dy - size.dy / 2) / (size.dy / 2)).clamp(-1.0, 1.0);
  return (y: kHeroTiltMax * nx, x: -kHeroTiltMax * ny);
}

/// The card's transform: perspective `setEntry(3, 2, 0.001)`, then the two rotations.
Matrix4 heroTiltMatrix(HeroTiltAngles a) => Matrix4.identity()
  ..setEntry(3, 2, 0.001)
  ..rotateX(a.x)
  ..rotateY(a.y);
