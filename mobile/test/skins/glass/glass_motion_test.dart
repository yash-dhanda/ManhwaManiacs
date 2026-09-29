import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:motor/motor.dart';

void main() {
  late MotionRecorder recorder;
  var clock = 0;

  setUp(() {
    clock = 0;
    recorder = MotionRecorder(clock: () => clock += 1000);
    GlassMotion.recorder = recorder;
    GlassMotion.isReduced = () => false;
  });

  tearDown(() {
    GlassMotion.recorder = MotionRecorder.instance;
    GlassMotion.isReduced = () => false;
  });

  test('every MotionName has a table entry with a spring, a curve or a documented absence', () {
    expect(MotionName.values.every(glassMotionTable.containsKey), isTrue);
    expect(glassMotionTable.length, MotionName.values.length);
    expect(glassMotionTable[MotionName.pressSwell]!.ms, 253);
    expect(glassMotionTable[MotionName.sheetPresent]!.ms, 447);
    expect(glassMotionTable[MotionName.push]!.ms, 615);
    expect(glassMotionTable[MotionName.tabDroplet]!.ms, 518);
    expect(glassMotionTable[MotionName.letterReveal]!.ms, 345);
    expect(glassMotionTable[MotionName.push]!.spring, GlassSprings.page);
    expect(glassMotionTable[MotionName.materialise]!.curve, GlassCurves.materialize);
    expect(glassMotionTable[MotionName.push]!.reduced.kind, GlassReducedKind.fade);
    expect(glassMotionTable[MotionName.push]!.reduced.ms, 200);
    expect(glassMotionTable[MotionName.dematerialise]!.reduced.ms, 120);
    expect(glassMotionTable[MotionName.ambientDrift]!.reduced.kind, GlassReducedKind.frozen);
    expect(glassMotionTable[MotionName.catchMove]!.reduced.kind, GlassReducedKind.same);
  });

  testWidgets('play runs the row spring and records name, planned ms and end', (tester) async {
    final c = AnimationController.unbounded(vsync: const TestVSync());
    addTearDown(c.dispose);
    final done = GlassMotion.play(MotionName.push, controller: c, target: 100);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.value, greaterThan(0));
    expect(c.value, lessThan(100));
    await tester.pumpAndSettle();
    await done;
    expect(c.value, closeTo(100, 0.5));
    final e = recorder.entries.single;
    expect(e.label, 'PUSH');
    expect(e.plannedMs, 615);
    expect(e.endMicros, isNotNull);
  });

  testWidgets('reduced motion swaps in the reduced replacement (the fade, the jump)', (tester) async {
    GlassMotion.isReduced = () => true;
    final c = AnimationController.unbounded(vsync: const TestVSync());
    addTearDown(c.dispose);
    // Push: a 200 ms linear cross-fade replaces the 615 ms spring.
    final done = GlassMotion.play(MotionName.push, controller: c, target: 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.value, closeTo(0.5, 0.05));
    await tester.pump(const Duration(milliseconds: 110));
    await done;
    expect(c.value, 1);
    expect(recorder.entries.last.plannedMs, 200);
    // Frozen and instant moves jump.
    await GlassMotion.play(MotionName.ambientDrift, controller: c, target: 5);
    expect(c.value, 5);
    await GlassMotion.play(MotionName.dimShift, controller: c, target: 7);
    expect(c.value, 7);
  });

  testWidgets('the "same" moves ignore reduced motion (catching is not motion)', (tester) async {
    GlassMotion.isReduced = () => true;
    final c = AnimationController(vsync: const TestVSync(), duration: const Duration(milliseconds: 1));
    addTearDown(c.dispose);
    await GlassMotion.play(MotionName.catchMove, controller: c, target: 1);
    expect(c.value, 1);
  });

  testWidgets('a spring retarget keeps the velocity', (tester) async {
    final c = AnimationController.unbounded(vsync: const TestVSync());
    addTearDown(c.dispose);
    unawaited(c.springTo(500, GlassSprings.zoom));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final before = c.value;
    final v = c.velocity;
    expect(v, greaterThan(0));
    unawaited(c.springTo(800, GlassSprings.zoom)); // retarget mid flight, velocity handed over
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(c.value, greaterThan(before), reason: 'no reversal or stall at the retarget');
    expect(c.velocity, greaterThan(v * 0.5));
    // catchMotion stops and reports the state.
    final caught = c.catchMotion();
    expect(caught.velocity, greaterThan(0));
    expect(c.isAnimating, isFalse);
    expect(c.value, caught.value);
  });

  testWidgets('release velocity is handed to the spring (law 4)', (tester) async {
    final slow = AnimationController.unbounded(vsync: const TestVSync());
    final fast = AnimationController.unbounded(vsync: const TestVSync());
    addTearDown(slow.dispose);
    addTearDown(fast.dispose);
    unawaited(GlassMotion.play(MotionName.rubberBand, controller: slow, target: 100));
    unawaited(GlassMotion.play(MotionName.rubberBand, controller: fast, target: 100, velocityPxPerS: 2000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(fast.value, greaterThan(slow.value));
    await tester.pumpAndSettle();
  });

  testWidgets('playMotor sets the row spring, hands the velocity over and records', (tester) async {
    final c = SingleMotionController(motion: const Motion.none(), vsync: const TestVSync());
    addTearDown(c.dispose);
    final done = GlassMotion.playMotor(MotionName.sheetSnap, c, 1, withVelocity: 2);
    expect(c.motion, isA<SpringMotion>());
    await tester.pumpAndSettle();
    await done;
    expect(c.value, closeTo(1, 0.01));
    expect(recorder.entries.single.label, 'SHEET SNAP');
    GlassMotion.isReduced = () => true;
    await GlassMotion.playMotor(MotionName.dimShift, c, 0);
    expect(recorder.entries.length, 2);
    expect(c.value, 0);
  });

  testWidgets('every call reaches the recorder and its frames are sampled', (tester) async {
    final c = AnimationController.unbounded(vsync: const TestVSync());
    addTearDown(c.dispose);
    for (final n in [MotionName.pressSwell, MotionName.zoom, MotionName.tabSwitch]) {
      unawaited(GlassMotion.play(n, controller: c, target: 1));
    }
    expect(recorder.entries.length, 3);
    final e = recorder.entries.first;
    recorder.sampleFrame(buildStartMicros: e.startMicros + 1, totalMs: 4);
    recorder.sampleFrame(buildStartMicros: e.startMicros + 2, totalMs: 40);
    expect(e.frames, 2);
    expect(e.dropped, 1);
    expect(e.flagged, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('the overlay lists the last 20 moves, flags a dropped one in danger, and Clear and Copy log work', (tester) async {
    final log = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') log.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    for (var i = 0; i < 25; i++) {
      final e = recorder.begin('MOVE $i', 250);
      recorder.end(e);
    }
    final bad = recorder.begin('BAD', 100);
    recorder.end(bad);
    bad.dropped = 2;
    await tester.pumpWidget(
      MaterialApp(home: Stack(children: [GlassMotionTimingsOverlay(recorder: recorder)])),
    );
    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    final rows = texts.where((t) => (t.data ?? '').contains('MS')).toList();
    expect(rows.length, 20);
    final badRow = texts.firstWhere((t) => (t.data ?? '').startsWith('BAD'));
    expect(badRow.style!.color, glassTokens.colorDanger);
    await tester.tap(find.text('Copy log'));
    await tester.pump();
    expect(log.single, contains('"label": "BAD"'));
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(recorder.entries, isEmpty);
  });

  test('the ring buffer keeps 200 entries and marks restarts', () {
    for (var i = 0; i < 230; i++) {
      recorder.end(recorder.begin('M$i', 1));
    }
    recorder.mark('SKIN RESTART');
    expect(recorder.entries.length, 200);
    expect(recorder.entries.last.label, 'SKIN RESTART');
    expect(recorder.entries.last.marker, isTrue);
  });
}
