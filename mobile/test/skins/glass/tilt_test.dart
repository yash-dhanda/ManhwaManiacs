import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/tilt.dart';

void main() {
  const six = 6 * math.pi / 180;
  test('rest is flat and the extremes clamp at plus and minus six degrees', () {
    expect(heroTiltFromGravity(Offset.zero), (x: 0.0, y: 0.0));
    final hard = heroTiltFromGravity(const Offset(1, 1));
    expect(hard.y, closeTo(six, 1e-9));
    expect(hard.x, closeTo(-six, 1e-9));
    final back = heroTiltFromGravity(const Offset(-1, -1));
    expect(back.y, closeTo(-six, 1e-9));
    expect(back.x, closeTo(six, 1e-9));
  });

  test('30 degrees of roll reaches the full tilt; 15 degrees is half', () {
    expect(heroTiltFromGravity(Offset(math.sin(30 * math.pi / 180), 0)).y, closeTo(six, 1e-9));
    expect(heroTiltFromGravity(Offset(math.sin(15 * math.pi / 180), 0)).y, closeTo(six / 2, 1e-9));
  });

  test('the pose is subtracted', () {
    const pose = Offset(0.3, -0.2);
    expect(heroTiltFromGravity(pose, pose: pose), (x: 0.0, y: 0.0));
    expect(heroTiltFromGravity(const Offset(0.8, 0), pose: pose).y, closeTo(six, 1e-9));
  });

  test('a reading beyond one g does not throw', () {
    expect(heroTiltFromGravity(const Offset(5, -5)).y, closeTo(six, 1e-9));
  });

  test('the pointer tilts toward the pointer by the same six degrees', () {
    final a = heroTiltFromPointer(const Offset(240, 270), const Offset(240, 360));
    expect(a.y, closeTo(six, 1e-9));
    expect(a.x, closeTo(-six / 2, 1e-9));
    expect(heroTiltMatrix(a).storage[11], closeTo(0.001, 1e-5));
  });
}
