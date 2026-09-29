// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

class RecordingDriver implements HapticsDriver {
  RecordingDriver({this.system = true, this.oneShotOk = true});
  final bool system;
  final bool oneShotOk;
  final calls = <String>[];

  @override
  Future<void> named(HapticsType type) async => calls.add('named:${type.name}');
  @override
  Future<void> ahap(String json) async => calls.add('ahap:$json');
  @override
  Future<void> impact(String style, double intensity) async =>
      calls.add('impact:$style:${intensity.toStringAsFixed(2)}');
  @override
  Future<bool> perform(String pattern) async {
    calls.add('perform:$pattern');
    return true;
  }

  @override
  Future<bool> oneShot(int ms, int amplitude) async {
    calls.add('oneShot:$ms:$amplitude');
    return oneShotOk;
  }

  @override
  Future<bool> systemEnabled() async => system;
}

class FakeBundle extends CachingAssetBundle {
  final loaded = <String>[];
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    loaded.add(key);
    return key;
  }
}

SkinHaptics make(SkinId skin, RecordingDriver d,
    {bool enabled = true, FakeBundle? bundle, Map<HapticEvent, List<HapticStep>>? map,}) {
  return SkinHaptics(
    skin: skin,
    map: map ?? (skin == SkinId.glass ? glassHaptics : cinematicHaptics),
    enabled: enabled,
    driver: d,
    bundle: bundle ?? FakeBundle(),
  );
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('parser', () {
    test('vectors', () {
      final a = HapticPattern.parse('soft:0.4');
      expect((a.name, a.intensity), ('soft', 0.4));
      final b = HapticPattern.parse('rigid:velocity');
      expect((b.velocity, b.velocityCap), (true, null));
      final c = HapticPattern.parse('soft:velocity<=0.5');
      expect((c.velocity, c.velocityCap), (true, 0.5));
      final d = HapticPattern.parse('ahap:rise{depth}');
      expect((d.isAhap, d.name, d.depth), (true, 'rise', true));
      expect(HapticPattern.parse('none').isNone, isTrue);
      expect(() => HapticPattern.parse('wobble'), throwsFormatException);
      expect(() => HapticPattern.parse('soft:2'), throwsFormatException);
    });

    test('every shipped pattern parses', () {
      for (final m in [cinematicHaptics, glassHaptics]) {
        for (final steps in m.values) {
          for (final s in steps) {
            HapticPattern.parse(s.pattern);
          }
        }
      }
    });
  });

  group('velocity', () {
    test('curve', () {
      expect(velocityIntensity(0), 0.3);
      expect(velocityIntensity(1000), closeTo(0.55, 1e-9));
      expect(velocityIntensity(-2800), 1.0);
      expect(velocityIntensity(9000), 1.0);
    });

    test('motion.catch is capped at 0.5 on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final d = RecordingDriver();
      await make(SkinId.glass, d).fire(HapticEvent.motionCatch, velocity: 9000);
      expect(d.calls, ['impact:soft:0.50']);
    });
  });

  group('routing', () {
    Future<List<String>> run(SkinId s, TargetPlatform p, String pattern, {double v = 1000}) async {
      debugDefaultTargetPlatformOverride = p;
      final d = RecordingDriver();
      await make(s, d, map: {
        HapticEvent.tapPrimary: [HapticStep(pattern: pattern)],
      },).fire(HapticEvent.tapPrimary, velocity: v);
      return d.calls;
    }

    test('plain', () async {
      expect(await run(SkinId.cinematic, TargetPlatform.iOS, 'success'), ['named:success']);
      expect(await run(SkinId.cinematic, TargetPlatform.android, 'success'), ['named:success']);
      expect(await run(SkinId.glass, TargetPlatform.android, 'success'), ['perform:success']);
    });

    test('literal intensity', () async {
      expect(await run(SkinId.glass, TargetPlatform.iOS, 'rigid:0.6'), ['impact:rigid:0.60']);
      expect(await run(SkinId.cinematic, TargetPlatform.android, 'rigid:0.6'), ['named:rigid']);
      expect(await run(SkinId.glass, TargetPlatform.android, 'rigid:0.6'), ['perform:rigid']);
    });

    test('velocity', () async {
      expect(await run(SkinId.glass, TargetPlatform.iOS, 'soft:velocity'), ['impact:soft:0.55']);
      expect(await run(SkinId.cinematic, TargetPlatform.android, 'soft:velocity'), ['named:soft']);
      expect(await run(SkinId.glass, TargetPlatform.android, 'soft:velocity'), ['oneShot:12:140']);
    });

    test('glass velocity falls back to perform below API 26', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final d = RecordingDriver(oneShotOk: false);
      await make(SkinId.glass, d, map: {
        HapticEvent.tapPrimary: [const HapticStep(pattern: 'soft:velocity')],
      },).fire(HapticEvent.tapPrimary);
      expect(d.calls, ['oneShot:12:77', 'perform:soft']);
    });

    test('toggles and drag', () async {
      expect(await run(SkinId.cinematic, TargetPlatform.iOS, 'toggleOn'), ['impact:rigid:0.50']);
      expect(await run(SkinId.cinematic, TargetPlatform.iOS, 'toggleOff'), ['impact:soft:0.40']);
      expect(await run(SkinId.cinematic, TargetPlatform.iOS, 'rigidBack'), ['impact:soft:0.30']);
      expect(await run(SkinId.cinematic, TargetPlatform.iOS, 'dragStart'), ['named:light']);
      expect(await run(SkinId.cinematic, TargetPlatform.android, 'toggleOn'), ['named:medium']);
      expect(await run(SkinId.cinematic, TargetPlatform.android, 'toggleOff'), ['named:light']);
      expect(await run(SkinId.glass, TargetPlatform.android, 'toggleOn'), ['perform:toggleOn']);
    });

    test('ahap loads the skin folder and plays', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final d = RecordingDriver();
      final b = FakeBundle();
      await make(SkinId.cinematic, d, bundle: b).fire(HapticEvent.tapPrimary);
      expect(b.loaded, ['assets/haptics/cinematic/impress.ahap.json']);
      expect(d.calls.single, startsWith('ahap:'));
    });

    test('nav.push at depth 3 loads glass rise3', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final b = FakeBundle();
      await make(SkinId.glass, RecordingDriver(), bundle: b).fire(HapticEvent.navPush, depth: 3);
      expect(b.loaded, ['assets/haptics/glass/rise3.ahap.json']);
    });
  });

  group('gates', () {
    test('switch off fires nothing', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final d = RecordingDriver();
      await make(SkinId.cinematic, d, enabled: false).fire(HapticEvent.tapPrimary);
      expect(d.calls, isEmpty);
    });

    test('Android system haptics off skips vibrator paths', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final d = RecordingDriver(system: false);
      final c = make(SkinId.cinematic, d);
      await c.fire(HapticEvent.tapPrimary); // ahap
      await c.fire(HapticEvent.toggleOn); // named
      final g = make(SkinId.glass, d, map: {
        HapticEvent.tapPrimary: [const HapticStep(pattern: 'soft:velocity')],
      },);
      await g.fire(HapticEvent.tapPrimary);
      expect(d.calls.where((c) => c.startsWith('ahap') || c.startsWith('oneShot') || c.startsWith('named')), isEmpty);
    });
  });

  group('sequences', () {
    test('chapter.complete: medium then light 120 ms later', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      fakeAsync((async) {
        final d = RecordingDriver();
        make(SkinId.cinematic, d).fire(HapticEvent.chapterComplete);
        async.flushMicrotasks();
        expect(d.calls, ['named:medium']);
        async.elapse(const Duration(milliseconds: 119));
        expect(d.calls, ['named:medium']);
        async.elapse(const Duration(milliseconds: 2));
        async.flushMicrotasks();
        expect(d.calls, ['named:medium', 'named:light']);
      });
    });

    test('repeat: nav.root fires 4 times 40 ms apart', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      fakeAsync((async) {
        final d = RecordingDriver();
        make(SkinId.glass, d).fire(HapticEvent.navRoot);
        async.elapse(const Duration(milliseconds: 500));
        expect(d.calls.length, 4);
      });
    });
  });
}
