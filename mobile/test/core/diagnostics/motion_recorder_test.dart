import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:shared_preferences/shared_preferences.dart';

MotionEntry _e(String l, int planned, int actualMs, {int frames = 0, int dropped = 0, String? note}) =>
    MotionEntry(label: l, plannedMs: planned, startUs: 0, endUs: actualMs * 1000, frames: frames, dropped: dropped, note: note);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldPrint = debugPrint;
  setUpAll(() => debugPrint = (String? m, {int? wrapWidth}) {});
  tearDownAll(() => debugPrint = oldPrint);

  test('off: no-op handle, nothing recorded', () {
    final r = MotionRecorder();
    final h = r.start('SET', 320);
    expect(identical(h, MotionHandle.noop), isTrue);
    h.end();
    expect(r.entries, isEmpty);
  });

  test('records planned and actual, ends once', () {
    var t = 0;
    final r = MotionRecorder(nowUs: () => t)..recording = true;
    final h = r.start('SET', 320);
    t = 330000;
    h.end();
    h.end(interrupted: true);
    expect(r.entries, hasLength(1));
    expect(r.entries.single.actualMs, 330);
    expect(r.entries.single.interrupted, isFalse);
  });

  test('ring buffer drops the oldest after 200', () {
    var t = 0;
    final r = MotionRecorder(nowUs: () => t++)..recording = true;
    for (var i = 0; i < 205; i++) {
      r.start('M$i', 10).end();
    }
    expect(r.entries, hasLength(200));
    expect(r.entries.first.label, 'M5');
  });

  test('formatEntry table', () {
    expect(formatEntry(_e('COLUMN WIPE', 872, 880, frames: 53)), 'COLUMN WIPE   872 → 880 MS   53/53 F   0 DROP');
    expect(formatEntry(_e('SET', 320, 330, frames: 20, dropped: 2)), 'SET           320 → 330 MS   18/20 F   2 DROP');
    expect(formatEntry(_e('TRAILER SCRUB', 0, 900, frames: 212)), 'TRAILER SCRUB   GESTURE   212 F   0 DROP');
    expect(formatEntry(_e('SKIN RESTART', 1500, 1212, note: 'confirm → first splash frame')),
        'SKIN RESTART  confirm → first splash frame  1,212 MS',);
  });

  test('isLate table', () {
    expect(isLate(_e('SET', 320, 330, frames: 20)), isFalse);
    expect(isLate(_e('SET', 320, 340, frames: 20)), isTrue); // 20 ms over > 16.7
    expect(isLate(_e('SET', 320, 320, frames: 20, dropped: 1)), isTrue);
    expect(isLate(_e('TRAILER SCRUB', 0, 900, frames: 212)), isFalse);
    expect(isLate(_e('TRAILER SCRUB', 0, 900, frames: 212, dropped: 1)), isTrue);
    expect(isLate(_e('SKIN RESTART', 1500, 1600)), isTrue);
  });

  test('logSkinRestart reads, clears and records even when off', () async {
    SharedPreferences.setMockInitialValues({'mm.skin.t0': 1000});
    final prefs = await SharedPreferences.getInstance();
    final r = MotionRecorder();
    await logSkinRestart(prefs, recorder: r, nowMs: 2212);
    expect(r.recording, isFalse);
    expect(prefs.getInt('mm.skin.t0'), isNull);
    expect(formatEntry(r.entries.single), 'SKIN RESTART  confirm → first splash frame  1,212 MS');
    expect(isLate(r.entries.single), isFalse);
    await logSkinRestart(prefs, recorder: r, nowMs: 3000);
    expect(r.entries, hasLength(1));
  });

  test('overlay provider flips the singleton recorder', () {
    final c = ProviderContainer();
    addTearDown(() {
      c.dispose();
      MotionRecorder.instance.recording = false;
    });
    c.read(motionTimingsOverlayProvider);
    c.read(motionTimingsOverlayProvider.notifier).state = true;
    expect(MotionRecorder.instance.recording, isTrue);
    c.read(motionTimingsOverlayProvider.notifier).state = false;
    expect(MotionRecorder.instance.recording, isFalse);
  });
}
