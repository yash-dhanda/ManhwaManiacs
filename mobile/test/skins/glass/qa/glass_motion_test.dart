// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';

import 'package:manhwamaniacs/skins/contract.g.dart';
import '../motion_names_test.dart' show motionTableRows;
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'glass_qa_screens.dart';

String _norm(String s) => s.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

/// The planned number of a Duration cell: the first "settle N ms" in it (a cell such as "40 ms spacing, settle 431 ms each" plans the
/// settle, not the spacing), else a leading "N ms". Everything else (continuous, while stretched, per frame, finger-driven) has none.
int? plannedMsOf(String cell) {
  final m = RegExp(r'settle\s+([\d,]+)\s*ms').firstMatch(cell) ?? RegExp(r'^([\d,]+)\s*ms').firstMatch(cell);
  return m == null ? null : int.parse(m.group(1)!.replaceAll(',', ''));
}

void main() {
  final rows = motionTableRows();
  late GlassMotionRecorder recorder;

  setUp(() {
    recorder = GlassMotionRecorder();
    GlassMotion.recorder = recorder;
    GlassMotion.isReduced = () => false;
  });
  tearDown(() {
    GlassMotion.recorder = GlassMotionRecorder.instance;
    GlassMotion.isReduced = () => false;
  });

  // G3: the planned settle each move logs is the Duration column of 4.10, within one frame (8.3 ms).
  var checked = 0;
  for (final r in rows) {
    final want = plannedMsOf(r.duration);
    final name = MotionName.values.firstWhere((m) => _norm(m.label) == _norm(r.name));
    if (want == null) continue;
    checked++;
    testWidgets('planned ${r.name} is $want ms', (t) async {
      final c = AnimationController.unbounded(vsync: const TestVSync());
      addTearDown(c.dispose);
      final done = GlassMotion.play(name, controller: c, target: 1);
      await t.pump();
      final entry = recorder.entries.last;
      expect(entry.label, name.label);
      expect((entry.plannedMs - want).abs(), lessThanOrEqualTo(8.3), reason: '${r.name}: table says $want ms, the move plans ${entry.plannedMs}');
      c.stop();
      await done;
    });
  }
  test('the planned-settle walk covers a meaningful share of the 116 rows', () => expect(checked, greaterThan(60)));

  // G2: the Reduce Motion column. A "N ms ... fade" cell is a fade of N ms; "Instant", "None", "Frozen" are not fades.
  for (final r in rows) {
    final name = MotionName.values.firstWhere((m) => _norm(m.label) == _norm(r.name));
    final spec = glassMotionTable[name]!;
    final text = r.reduced;
    final fade = RegExp(r'(\d+) ms(?: cross-fade| fade)').firstMatch(text) ?? RegExp(r'^(\d+) ms cross-fade').firstMatch(text) ?? RegExp(r'fades? together over (\d+) ms').firstMatch(text);
    if (fade != null && !text.contains('no fade') && !text.startsWith('Fill shown')) {
      test('reduced ${r.name}: a ${fade.group(1)} ms fade', () {
        expect(spec.reduced.kind, GlassReducedKind.fade, reason: text);
        expect(spec.reduced.ms, int.parse(fade.group(1)!), reason: text);
      });
    } else if (RegExp(r'^(Instant|Hard stop|Values jump|Value jumps|Jumps)').hasMatch(text)) {
      test('reduced ${r.name}: no animation (instant)', () {
        expect(spec.reduced.kind, anyOf(GlassReducedKind.instant, GlassReducedKind.none, GlassReducedKind.frozen), reason: text);
      });
    } else if (RegExp(r'^(None|Off)\b').hasMatch(text)) {
      test('reduced ${r.name}: none', () {
        expect(spec.reduced.kind, anyOf(GlassReducedKind.none, GlassReducedKind.frozen), reason: text);
      });
    } else if (text.startsWith('Frozen')) {
      test('reduced ${r.name}: frozen', () => expect(spec.reduced.kind, GlassReducedKind.frozen, reason: text));
    }
  }

  screenMotionTests();

  // The field, the light and the headlines under Reduce Motion (4.11): frozen.
  for (final mode in const ['os', 'app']) {
    glassQaWidgets('reduced ($mode): the ambient anchors do not move over 15 s, and the light angle stays at 135 degrees', (t) async {
      final s = kGlassQaScreens.firstWhere((e) => e.id == ScreenId.tonight);
      final sensor = StreamController<AccelerometerEvent>.broadcast();
      addTearDown(sensor.close);
      final rig = await pumpGlassQa(t, s,
          reduced: mode == 'os',
          prefs: mode == 'app' ? const {'mm.a11y.p1.reduceMotion': true} : const {},
          extra: [gravitySensorProvider.overrideWithValue(() => sensor.stream)]);
      final sub = rig.shell.container.listen(glassLightAngleProvider, (_, __) {});
      for (var i = 0; i < 20; i++) {
        sensor.add(AccelerometerEvent(6, 0, 6, DateTime.now())); // a hard tilt
        await t.pump(const Duration(milliseconds: 33));
      }
      final field = t.state<GlassAmbientFieldState>(find.byType(GlassAmbientField).first);
      final before = field.anchors;
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(field.anchors, before);
      expect(sub.read().value, closeTo(135 * math.pi / 180, 1e-9)); // fake accelerometer events leave the light pinned
      sub.close();
      // The Home greeting shows its full text with no caret.
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_CaretPainter'), findsNothing);
      await disposeGlassQa(t, rig);
    });
  }

  // The two Flutter-only rows are in the table and reduce as 4.10 says.
  test('Stack fan and Address drain: 200 ms fades', () {
    expect(glassMotionTable[MotionName.stackFan]!.reduced.kind, GlassReducedKind.fade);
    expect(glassMotionTable[MotionName.stackFan]!.reduced.ms, 200);
    expect(glassMotionTable[MotionName.addressDrain]!.reduced.kind, GlassReducedKind.fade);
    expect(glassMotionTable[MotionName.addressDrain]!.reduced.ms, 200);
  });
}

// G1: every screen under Reduce Motion (the OS flag alone, then the in-app switch alone) settles with no ticker running except the
// allowed ones (14.1): static-opacity progress pulses, the Liquid spinner and thinking orbit's 1.2 s pulses, a user-started cruise.
/// What may still tick at rest under Reduce Motion (14.1): the text caret's fade in an autofocused field on the auth and profile
/// forms, and Wrapped's story clock (its capsule is a progress indicator, not decoration). Nothing else.
const _allowedTickers = {ScreenId.login: 1, ScreenId.register: 1, ScreenId.profiles: 1, ScreenId.profileNew: 1, ScreenId.annual: 1};

void screenMotionTests() {
  for (final mode in const ['os', 'app']) {
    for (final s in kGlassQaScreens) {
      if (s.id == ScreenId.reader || s.id == ScreenId.readAll || s.id == ScreenId.novel) continue;
      glassQaWidgets('reduced ($mode) ${s.id.id}: nothing animates at rest', (t) async {
        final rig = await pumpGlassQa(t, s,
            reduced: mode == 'os', prefs: mode == 'app' ? const {'mm.a11y.p1.reduceMotion': true} : const {});
        await t.pump(const Duration(seconds: 2));
        await t.pump(const Duration(seconds: 2));
        final n = t.binding.transientCallbackCount;
        expect(t.takeException(), isNull);
        expect(n, lessThanOrEqualTo(_allowedTickers[s.id] ?? 0), reason: '${s.id.id} ($mode): $n tickers still run at rest');
        await disposeGlassQa(t, rig);
      });
    }
  }
}
