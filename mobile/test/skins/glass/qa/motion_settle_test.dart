import 'dart:convert';
import 'dart:io';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show CatchableSpring, glassSpringTolerance, springOf;

/// The spec's settle (design/lib/spring.mjs): the last instant |1 - x| > 0.005, searched at 0.1 ms.
double specSettleMs(SpringDescription s) {
  final sim = SpringSimulation(s, 0, 1, 0);
  var last = 0.0;
  for (var t = 0.0; t <= 3.0; t += 0.0001) {
    if ((1 - sim.x(t)).abs() > 0.005) last = t;
  }
  return last * 1000;
}

/// What `springTo` actually runs: frames at 60 Hz until `isDone` under [glassSpringTolerance] (Flutter's default 1e-3 when
/// [flutterDefault]).
double controllerSettleMs(SpringDescription s, {double hz = 60, bool flutterDefault = false}) {
  final sim = SpringSimulation(s, 0, 1, 0, tolerance: flutterDefault ? Tolerance.defaultTolerance : glassSpringTolerance(1));
  var t = 0.0;
  while (!sim.isDone(t) && t < 5) {
    t += 1 / hz;
  }
  return t * 1000;
}

/// Every spring-driven row of glass 4.10: its planned settle, the spec's settle of its spring and what the controller runs.
/// `MM_WRITE_MOTION_SETTLE=1` writes the record to docs/redesign/proof/mobile-45/audit/motion-settle.json.
/// Rows whose Duration cell is a composite (a per-grapheme step, a hold, a sequence), not the spring's own settle.
const _composite = {'TYPING REVEAL', 'STEP INTO THE LIGHT', 'HOLD FILL', 'DROPLET REVEAL', 'GOAL RING CLOSE'};

void main() {
  final rows = [
    for (final e in glassMotionTable.entries)
      if (e.value.spring != null && e.value.ms > 0)
        (
          name: e.key.label,
          planned: e.value.ms,
          spec: specSettleMs(springOf(e.value.spring!)),
          controller: controllerSettleMs(springOf(e.value.spring!)),
          flutterDefault: controllerSettleMs(springOf(e.value.spring!), flutterDefault: true),
        ),
  ];

  test('every spring row plans its spring\'s spec settle (within one 60 Hz frame)', () {
    expect(rows, isNotEmpty);
    final off = [for (final r in rows) if (!_composite.contains(r.name) && (r.spec - r.planned).abs() > 1000 / 60) '${r.name}: planned ${r.planned} ms, the spring settles at ${r.spec.toStringAsFixed(1)} ms'];
    expect(off, isEmpty);
  });

  test('springTo stops at the spec settle: never early, at most 3 frames late', () {
    for (final r in rows) {
      expect(r.controller, greaterThanOrEqualTo(r.spec - 1000 / 60), reason: r.name);
      expect(r.controller, lessThanOrEqualTo(r.spec + 3 * 1000 / 60), reason: r.name);
    }
  });

  testWidgets('springTo lands exactly on its target', (t) async {
    final c = AnimationController(vsync: const TestVSync());
    addTearDown(c.dispose);
    final run = c.springTo(1, glassMotionTable.values.firstWhere((s) => s.spring != null).spring!);
    for (var i = 0; i < 120 && c.isAnimating; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    await run;
    await t.pump();
    expect(c.value, 1);
  });

  test('record', () {
    if (Platform.environment['MM_WRITE_MOTION_SETTLE'] != '1') return;
    final out = File('../docs/redesign/proof/mobile-45/audit/motion-settle.json');
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert([
      for (final r in rows) {'label': r.name, 'plannedMs': r.planned, 'specSettleMs': double.parse(r.spec.toStringAsFixed(1)), 'controllerSettleMs60Hz': double.parse(r.controller.toStringAsFixed(1)), 'flutterDefaultToleranceMs60Hz': double.parse(r.flutterDefault.toStringAsFixed(1))},
    ])}\n');
  });
}
