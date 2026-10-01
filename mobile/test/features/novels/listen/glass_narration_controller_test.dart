import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';
import 'package:manhwamaniacs/features/novels/utils/shake_detector.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../support/narration_harness.dart';

AccelSample s(double m, int ms) => (x: m, y: 0, z: 0, at: DateTime.utc(2026).add(Duration(milliseconds: ms)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late NarrationHarness h;
  late StreamController<AccelSample> accel;

  Future<void> boot(SkinId skin) async {
    accel = StreamController<AccelSample>.broadcast();
    addTearDown(accel.close);
    h = await NarrationHarness.create(
      extra: [
        skinIdProvider.overrideWithValue(skin),
        glassAccelerometerSourceProvider.overrideWithValue(() => accel.stream),
      ],
    );
    addTearDown(h.dispose);
  }

  test('A1: Glass keeps narration past the reader, Cinematic stops it', () async {
    await boot(SkinId.glass);
    expect(h.container.read(narrationStopOnReaderExitProvider), isFalse);
    h.dispose();
    await boot(SkinId.cinematic);
    expect(h.container.read(narrationStopOnReaderExitProvider), isTrue);
  });

  test('A2: the controller gives the handler the active skin\'s control set', () async {
    await boot(SkinId.glass);
    h.container.read(narrationControllerProvider);
    expect(h.handler.controlSet, NarrationControlSet.glass);
  });

  test('A2: the Glass lock screen\'s previous button reaches the reader', () async {
    await boot(SkinId.glass);
    var called = 0;
    h.controller.onSkipPrevious = () => called++;
    await h.handler.skipToPrevious();
    expect(called, 1);
  });

  test('A5: Glass shake is off by default and nothing subscribes', () async {
    await boot(SkinId.glass);
    await h.startAndSettle(listenTarget());
    h.controller.setSleep(SleepChoice.minutes(30));
    expect(accel.hasListener, isFalse);
  });

  test('A5: with the switch on it subscribes only while a timer runs and the app is resumed; two peaks in 280 ms extend, 320 do not', () async {
    await boot(SkinId.glass);
    await h.container.read(listenSettingsProvider.notifier).put({'glassShakeToExtend': true});
    final feedback = <NarrationFeedback>[];
    await h.startAndSettle(listenTarget());
    h.controller.onFeedback = feedback.add;
    expect(accel.hasListener, isFalse);

    h.controller.setSleep(SleepChoice.minutes(30));
    expect(accel.hasListener, isTrue);
    final before = h.controller.sleepState.value.remaining!;
    accel
      ..add(s(25, 0))
      ..add(s(1, 100))
      ..add(s(25, 280));
    await h.settle();
    expect(feedback, [NarrationFeedback.shakeExtended]);
    expect(h.controller.sleepState.value.remaining! > before, isTrue);

    feedback.clear();
    accel
      ..add(s(1, 1000))
      ..add(s(25, 1100))
      ..add(s(1, 1200))
      ..add(s(25, 1420));
    await h.settle();
    expect(feedback, isEmpty);

    h.controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(accel.hasListener, isFalse);
    h.controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(accel.hasListener, isTrue);

    h.controller.setSleep(SleepChoice.off);
    expect(accel.hasListener, isFalse);
  });
}
