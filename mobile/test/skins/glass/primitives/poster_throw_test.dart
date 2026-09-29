import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster_throw.dart';

void main() {
  const view = Size(390, 844);
  const mid = Offset(195, 500);

  test('lift: nothing before 150 ms, 1.06 at 450 ms', () {
    expect(liftScale(100), 1);
    expect(liftScale(150), 1);
    expect(liftScale(300), closeTo(1.03, 1e-9));
    expect(liftScale(450), closeTo(1.06, 1e-9));
    expect(liftScale(900), closeTo(1.06, 1e-9));
  });

  test('open by position: the projected centre above the top 20 %', () {
    expect(decideThrow(centre: const Offset(195, 120), velocity: Offset.zero, viewport: view), isA<ThrowOpen>());
    expect(decideThrow(centre: mid, velocity: Offset.zero, viewport: view), isA<ThrowDrop>());
  });

  test('open by velocity: -1,200 px/s', () {
    expect(decideThrow(centre: mid, velocity: const Offset(0, -1200), viewport: view), isA<ThrowOpen>());
    expect(decideThrow(centre: mid, velocity: const Offset(0, -300), viewport: view), isA<ThrowDrop>());
  });

  test('away only with allowAway', () {
    expect(decideThrow(centre: mid, velocity: const Offset(1500, 0), viewport: view), isA<ThrowDrop>());
    expect(decideThrow(centre: mid, velocity: const Offset(1500, 0), viewport: view, allowAway: true), isA<ThrowAway>());
    expect(decideThrow(centre: mid, velocity: const Offset(-1500, 0), viewport: view, allowAway: true), isA<ThrowAway>());
    expect(decideThrow(centre: mid, velocity: const Offset(100, 0), viewport: view, allowAway: true), isA<ThrowDrop>());
  });

  test('a target within 64 px captures; at 65 it does not', () {
    const t = MagnetTarget(Offset(100, 700), 'friend');
    final near = decideThrow(centre: const Offset(164, 700), velocity: Offset.zero, viewport: view, targets: [t]);
    expect(near, isA<ThrowTarget>());
    expect((near as ThrowTarget).target.id, 'friend');
    expect(decideThrow(centre: const Offset(165, 700), velocity: Offset.zero, viewport: view, targets: [t]), isA<ThrowDrop>());
  });
}
