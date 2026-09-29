import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold.dart';

void main() {
  const o = Offset.zero;

  test('a release before 200 ms within 8 px is a click', () {
    final m = HoldMachine()..down(0, o);
    expect(m.up(150).whereType<HoldClick>(), hasLength(1));
  });

  test('8 px of movement before 200 ms cancels and the release does nothing', () {
    final m = HoldMachine()..down(0, o);
    expect(m.move(100, const Offset(8, 0)).whereType<HoldCancel>(), hasLength(1));
    expect(m.up(150), isEmpty);
  });

  test('7 px of movement is still a click', () {
    final m = HoldMachine()..down(0, o);
    expect(m.move(50, const Offset(7, 0)), isEmpty);
    expect(m.up(100).whereType<HoldClick>(), hasLength(1));
  });

  test('a pointer cancel cancels', () {
    final m = HoldMachine()..down(0, o);
    expect(m.cancel().whereType<HoldCancel>(), hasLength(1));
    expect(m.up(50), isEmpty);
  });

  test('the fill starts at 200 ms; movement after that does not cancel', () {
    final m = HoldMachine()..down(0, o);
    expect(m.tick(199), isEmpty);
    expect(m.tick(200).whereType<HoldFillStart>(), hasLength(1));
    expect(m.move(300, const Offset(40, 40)).whereType<HoldCancel>(), isEmpty);
    expect(m.levelAt(700), closeTo(0.5, 1e-9));
  });

  test('hold.ramp fires every 150 ms from the fill start, 0.2 rising to 0.8', () {
    final m = HoldMachine()..down(0, o);
    final ramps = <double>[];
    for (var t = 0.0; t <= 1300; t += 10) {
      ramps.addAll(m.tick(t).whereType<HoldRamp>().map((r) => r.intensity));
    }
    expect(ramps.length, 7);
    expect(ramps.first, closeTo(0.2, 1e-9));
    expect(ramps.last, closeTo(0.2 + 0.6 * 900 / 1000, 1e-9));
    for (var i = 1; i < ramps.length; i++) {
      expect(ramps[i], greaterThan(ramps[i - 1]));
    }
  });

  test('hold.done fires at 1,200 ms and the release after it does nothing', () {
    final m = HoldMachine()..down(0, o);
    expect(m.tick(1199).whereType<HoldDone>(), isEmpty);
    expect(m.tick(1200).whereType<HoldDone>(), hasLength(1));
    expect(m.levelAt(1200), 1);
    expect(m.up(1300).whereType<HoldAborted>(), isEmpty);
  });

  test('a release between 200 and 1,200 ms is an aborted hold from its level', () {
    final m = HoldMachine()..down(0, o);
    final ev = m.up(700);
    final a = ev.whereType<HoldAborted>().single;
    expect(a.level, closeTo(0.5, 1e-9));
  });

  test('reduced motion steps the level in four 25 % increments 250 ms apart', () {
    final m = HoldMachine()..down(0, o)..tick(200);
    expect(m.levelAt(200 + 249, stepped: true), 0);
    expect(m.levelAt(200 + 250, stepped: true), 0.25);
    expect(m.levelAt(200 + 500, stepped: true), 0.5);
    expect(m.levelAt(200 + 750, stepped: true), 0.75);
    expect(m.levelAt(200 + 1000, stepped: true), 1);
  });
}
