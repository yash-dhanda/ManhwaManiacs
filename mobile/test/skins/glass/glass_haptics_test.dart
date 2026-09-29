// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

class _Driver implements HapticsDriver {
  final calls = <String>[];
  @override
  Future<void> named(HapticsType type) async => calls.add('named:${type.name}');
  @override
  Future<void> ahap(String json) async => calls.add('ahap');
  @override
  Future<void> impact(String style, double intensity) async => calls.add('impact:$style:${intensity.toStringAsFixed(2)}');
  @override
  Future<bool> perform(String pattern) async {
    calls.add('perform:$pattern');
    return true;
  }

  @override
  Future<bool> oneShot(int ms, int amplitude) async {
    calls.add('oneShot:$ms:$amplitude');
    return true;
  }

  @override
  Future<bool> systemEnabled() async => true;
}

class _Bundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => key;
}

GlassHaptics _make(_Driver d, Duration Function() clock, {bool enabled = true}) => GlassHaptics(
      haptics: SkinHaptics(skin: SkinId.glass, map: glassHaptics, enabled: enabled, driver: d, bundle: _Bundle()),
      clock: clock,
    );

void main() {
  setUp(GlassHaptics.debugLog.clear);

  test('intensity formulas', () {
    expect(GlassHaptics.intensityOf(HapticEvent.throwCommit, velocity: 1200), closeTo(0.6, 1e-9));
    expect(GlassHaptics.intensityOf(HapticEvent.throwCommit, velocity: 9000), 1.0);
    expect(GlassHaptics.intensityOf(HapticEvent.motionCatch, velocity: 9000), 0.5);
    expect(GlassHaptics.intensityOf(HapticEvent.motionCatch, velocity: 0), 0.3);
    expect(GlassHaptics.intensityOf(HapticEvent.navPush, depth: 3), closeTo(0.54, 1e-9));
    expect(GlassHaptics.intensityOf(HapticEvent.navPush, depth: 1, velocity: 3000), closeTo(1.0, 1e-9));
    expect(GlassHaptics.intensityOf(HapticEvent.detentMagnet), 0.4);
    expect(GlassHaptics.kindOf(HapticEvent.select), GlassHapticKind.tick);
    expect(GlassHaptics.kindOf(HapticEvent.stackPick), GlassHapticKind.impact);
  });

  test('ticks are limited to one per 40 ms', () {
    fakeAsync((async) {
      final d = _Driver();
      final h = _make(d, () => async.elapsed);
      h.fire(HapticEvent.select);
      async.elapse(const Duration(milliseconds: 10));
      h.fire(HapticEvent.select);
      async.elapse(const Duration(milliseconds: 10));
      h.fire(HapticEvent.select);
      expect(GlassHaptics.debugLog.length, 1);
      async.elapse(const Duration(milliseconds: 30)); // the window ends: the held one plays
      expect(GlassHaptics.debugLog.length, 2);
      async.elapse(const Duration(milliseconds: 100));
      h.fire(HapticEvent.select);
      expect(GlassHaptics.debugLog.length, 3);
      h.dispose();
    });
  });

  test('impacts are limited to one per 120 ms and a burst keeps the strongest', () {
    fakeAsync((async) {
      final d = _Driver();
      final h = _make(d, () => async.elapsed);
      h.fire(HapticEvent.tapPrimary); // 0.6, fires at once
      async.elapse(const Duration(milliseconds: 20));
      h.fire(HapticEvent.detentLimit); // 0.5, held
      h.fire(HapticEvent.throwCommit, velocity: 3000); // 1.0, replaces it
      h.fire(HapticEvent.detentLimit); // 0.5, does not replace the stronger one
      expect(GlassHaptics.debugLog.map((e) => e.event), [HapticEvent.tapPrimary]);
      async.elapse(const Duration(milliseconds: 100));
      expect(GlassHaptics.debugLog.map((e) => e.event), [HapticEvent.tapPrimary, HapticEvent.throwCommit]);
      h.dispose();
    });
  });

  test('a tick and an impact do not limit each other', () {
    fakeAsync((async) {
      final h = _make(_Driver(), () => async.elapsed);
      h.fire(HapticEvent.select);
      h.fire(HapticEvent.tapPrimary);
      expect(GlassHaptics.debugLog.length, 2);
      h.dispose();
    });
  });

  test('the Haptics switch off fires and logs nothing', () {
    fakeAsync((async) {
      final d = _Driver();
      final h = _make(d, () => async.elapsed, enabled: false);
      h.fire(HapticEvent.tapPrimary);
      async.flushMicrotasks();
      expect(GlassHaptics.debugLog, isEmpty);
      expect(d.calls, isEmpty);
    });
  });

  test('a velocity event reaches the platform with its scaled intensity', () async {
    final d = _Driver();
    final h = _make(d, () => Duration.zero);
    await h.fire(HapticEvent.throwCommit, velocity: 1200);
    expect(d.calls.single, 'oneShot:12:153');
    h.dispose();
  });
}
