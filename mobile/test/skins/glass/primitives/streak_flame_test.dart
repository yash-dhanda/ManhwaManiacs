import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

Future<Widget> host(Widget child, {required StreamController<AccelerometerEvent> sensor, ScrollController? c}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return primHost(
    SizedBox(height: 800, child: SingleChildScrollView(controller: c, child: Column(children: [child, const SizedBox(height: 2000)]))),
    overrides: [sharedPrefsProvider.overrideWithValue(prefs), gravitySensorProvider.overrideWithValue(() => sensor.stream)],
  );
}

void main() {
  test('the state follows the server streak and the clock', () {
    expect(flameStateOf(days: 0, readToday: false, atRisk: false), FlameState.none);
    expect(flameStateOf(days: 3, readToday: true, atRisk: false), FlameState.litToday);
    expect(flameStateOf(days: 3, readToday: false, atRisk: false), FlameState.notYetToday);
    expect(flameStateOf(days: 12, readToday: false, atRisk: true), FlameState.atRisk);
    expect(flameSemantics(FlameState.atRisk, 12), '12-day streak, at risk');
    expect(flameSemantics(FlameState.none, 0), 'No streak');
    expect(flameCaption(FlameState.none, 0, longest: 31), 'Longest: 31 days. Start a new one today.');
    expect(flameCaption(FlameState.atRisk, 12), 'Read one chapter to keep your 12-day streak');
  });

  testWidgets('the tilt subscription exists only while the flame is visible', (t) async {
    final sensor = StreamController<AccelerometerEvent>.broadcast();
    addTearDown(sensor.close);
    final c = ScrollController();
    await t.pumpWidget(await host(const StreakFlame(size: 96, state: FlameState.litToday, days: 12), sensor: sensor, c: c));
    final container = ProviderScope.containerOf(t.element(find.byType(StreakFlame)));
    await t.pump(const Duration(milliseconds: 50));
    expect(container.read(gravityProvider).sensorSubscriptions, 1);
    c.jumpTo(1500);
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));
    expect(container.read(gravityProvider).sensorSubscriptions, 0);
    c.jumpTo(0);
    await t.pump(const Duration(milliseconds: 50));
    expect(container.read(gravityProvider).sensorSubscriptions, 1);
  });

  testWidgets('semantics names the state and the flare runs without error', (t) async {
    final sensor = StreamController<AccelerometerEvent>.broadcast();
    addTearDown(sensor.close);
    final h = t.ensureSemantics();
    Future<Widget> w(int f) => host(StreakFlame(size: 44, state: FlameState.notYetToday, days: 12, flare: f), sensor: sensor);
    await t.pumpWidget(await w(0));
    expect(find.bySemanticsLabel('12-day streak, not read yet today'), findsOneWidget);
    await t.pumpWidget(await w(1));
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(seconds: 1));
    h.dispose();
  });
}
