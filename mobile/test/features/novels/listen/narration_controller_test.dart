import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/shake_detector.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

import '../../../support/narration_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late NarrationHarness h;

  setUp(() async => h = await NarrationHarness.create());
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    h.dispose();
  });

  test('a streamed chapter is probed, then played with bearer and profile headers', () async {
    h.container.read(narrationControllerProvider);
    await h.startAndSettle(listenTarget());
    expect(h.probeUrls.single, contains('/novels/audio/file?source=src&series=book&chapter=c12'));
    expect(h.player.url, h.probeUrls.single);
    expect(h.player.calls, containsAllInOrder(['setUrl', 'setSpeed', 'play']));
    expect(h.state.status, NarrationStatus.playing);
    expect(h.state.active, isTrue);
    expect(h.container.read(narrationActiveProvider), isTrue);
    // Narration enters State B; leaving restores State A.
    expect(h.sessionStates, [AudioSessionState.narration]);
    await h.controller.stop();
    expect(h.sessionStates.last, AudioSessionState.idle);
    expect(h.container.read(narrationActiveProvider), isFalse);
  });

  test('an iPhone asks for m4a', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await h.startAndSettle(listenTarget());
    expect(h.probeUrls.single, contains('format=m4a'));
  });

  test('a saved narration plays from its file with no probe', () async {
    await h.startAndSettle(listenTarget(file: '/tmp/x.m4a'));
    expect(h.probeUrls, isEmpty);
    expect(h.player.file, '/tmp/x.m4a');
    expect(h.player.calls, isNot(contains('setUrl')));
  });

  test('503 audio_preparing waits and retries, showing preparing', () async {
    h.probeStatuses.addAll([503, 503, 206]);
    final done = h.controller.start(listenTarget());
    await done;
    await h.settle();
    expect(h.state.status, NarrationStatus.preparing);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    await h.settle();
    expect(h.probeUrls.length, 3);
    expect(h.state.status, NarrationStatus.playing);
  });

  test('a failed load says so, and retry starts again', () async {
    h.probeStatuses.add(500);
    await h.startAndSettle(listenTarget());
    expect(h.state.status, NarrationStatus.failed);
    expect(h.state.failure, isNotNull);
    expect(h.state.active, isFalse);
    await h.controller.retry();
    await h.settle();
    expect(h.state.status, NarrationStatus.playing);
  });

  test('position ticks move the active segment; a stale map moves nothing', () async {
    await h.startAndSettle(listenTarget());
    h.player.tick(12000);
    await h.settle();
    expect(h.controller.position.value, 12000);
    expect(h.controller.segment.value, 1);
    h.player.tick(59000);
    await h.settle();
    expect(h.controller.segment.value, 5);

    await h.startAndSettle(listenTarget(stale: true));
    h.player.tick(12000);
    await h.settle();
    expect(h.state.highlightSafe, isFalse);
    expect(h.controller.segment.value, -1);
  });

  test('seeks: by 15 s, to a segment, to a paragraph, by sentence', () async {
    await h.startAndSettle(listenTarget());
    h.player.tick(30000);
    await h.settle();
    await h.controller.seekBy(const Duration(seconds: 15));
    expect(h.player.seeks.last, const Duration(seconds: 45));
    await h.controller.seekBy(const Duration(seconds: -60));
    expect(h.player.seeks.last, Duration.zero);
    await h.controller.seekToSegment(3);
    expect(h.player.seeks.last, const Duration(seconds: 30));
    await h.controller.seekToParagraph(3);
    expect(h.player.seeks.last, const Duration(seconds: 40));
    h.player.tick(41000);
    await h.settle();
    await h.controller.stepSentence(1);
    expect(h.player.seeks.last, const Duration(seconds: 50));
    await h.controller.stepSentence(-1);
    expect(h.player.seeks.last, const Duration(seconds: 40));
    await h.controller.seek(const Duration(seconds: 500));
    expect(h.player.seeks.last, const Duration(seconds: 60));
  });

  test('speed is normalised, applied without touching pitch, and remembered per profile', () async {
    await h.startAndSettle(listenTarget());
    await h.controller.setSpeed(1.27);
    expect(h.state.speed, 1.25);
    expect(h.player.speeds.last, 1.25);
    await h.controller.setSpeed(9);
    expect(h.state.speed, 3.0);
    await h.startAndSettle(listenTarget(chapter: 'c13'));
    expect(h.state.speed, 3.0);
  });

  test('the end of a chapter is announced once, and the sleep timer can stop it', () async {
    await h.startAndSettle(listenTarget());
    final events = <NarrationEnded>[];
    final sub = h.controller.ended.listen(events.add);
    h.player.finish();
    await h.settle();
    expect(events.single.sleepStop, isFalse);
    expect(h.state.status, NarrationStatus.completed);
    expect(h.state.active, isFalse);

    await h.startAndSettle(listenTarget(chapter: 'c13'));
    h.controller.setSleep(SleepChoice.endOfChapter);
    h.player.finish();
    await h.settle();
    expect(events.last.sleepStop, isTrue);
    await sub.cancel();
  });

  test('seeking back after the end and finishing again announces the end again', () async {
    await h.startAndSettle(listenTarget());
    final events = <NarrationEnded>[];
    final sub = h.controller.ended.listen(events.add);
    h.player.finish();
    await h.settle();
    await h.controller.seekToSegment(0);
    await h.controller.play();
    h.player.finish();
    await h.settle();
    expect(events, hasLength(2));
    await sub.cancel();
  });

  test('play from the end restarts; stop releases the player and clears the lock screen', () async {
    await h.startAndSettle(listenTarget());
    h.player.finish();
    await h.settle();
    await h.controller.play();
    expect(h.player.seeks.last, Duration.zero);

    final p = h.player;
    await h.controller.stop();
    expect(p.disposed, isTrue);
    expect(h.state.status, NarrationStatus.idle);
    expect(h.handler.mediaItem.value, isNull);
  });

  test('starting another chapter disposes the previous player', () async {
    await h.startAndSettle(listenTarget());
    final first = h.player;
    await h.startAndSettle(listenTarget(chapter: 'c13'));
    expect(first.disposed, isTrue);
    expect(h.players.length, 2);
    expect(h.state.key!.chapterKey, 'c13');
  });

  test('the lock screen mirrors the player: item, controls, and commands come back', () async {
    await h.startAndSettle(listenTarget());
    expect(h.handler.mediaItem.value!.title, 'Chapter 12 · The Tower');
    expect(h.handler.mediaItem.value!.artist, 'Read by Iris');
    expect(h.handler.playbackState.value.playing, isTrue);
    expect(h.handler.playbackState.value.controls[1], MediaControl.pause);

    await h.handler.pause();
    expect(h.player.calls.last, 'pause');
    await h.settle();
    expect(h.handler.playbackState.value.playing, isFalse);

    h.player.tick(20000);
    await h.settle();
    await h.handler.fastForward();
    expect(h.player.seeks.last, const Duration(seconds: 35));
    await h.handler.rewind();
    expect(h.player.seeks.last, const Duration(seconds: 20));

    var skipped = 0;
    h.controller.onSkipNext = () => skipped++;
    await h.handler.skipToNext();
    expect(skipped, 1);
  });

  test('a voice sample pauses narration and resumes it after', () async {
    await h.startAndSettle(listenTarget());
    final resume = await h.controller.pauseForSample();
    await h.settle();
    expect(h.player.playing, isFalse);
    await resume();
    await h.settle();
    expect(h.player.playing, isTrue);

    await h.controller.pause();
    final resume2 = await h.controller.pauseForSample();
    await resume2();
    await h.settle();
    expect(h.player.playing, isFalse);
  });

  test('shake listens to the accelerometer only in the last minute of a sleep timer', () async {
    final accel = StreamController<AccelSample>.broadcast();
    addTearDown(accel.close);
    h.dispose();
    h = await NarrationHarness.create(extra: [accelerometerSourceProvider.overrideWithValue(() => accel.stream)]);
    final feedback = <NarrationFeedback>[];
    await h.startAndSettle(listenTarget());
    h.controller.onFeedback = feedback.add;

    expect(accel.hasListener, isFalse);
    h.controller.setSleep(SleepChoice.minutes(30));
    expect(accel.hasListener, isFalse);
    h.controller.setSleep(SleepChoice.endOfChapter);
    expect(accel.hasListener, isFalse);

    h.controller.setSleep(SleepChoice.minutes(1));
    expect(accel.hasListener, isTrue);
    expect(h.controller.shakeListening, isTrue);
    AccelSample s(double m, int ms) => (x: m, y: 0, z: 0, at: DateTime.utc(2026).add(Duration(milliseconds: ms)));
    accel
      ..add(s(30, 0))
      ..add(s(1, 100))
      ..add(s(30, 250));
    await h.settle();
    expect(h.controller.sleepState.value.remaining! > const Duration(minutes: 5), isTrue);
    expect(feedback, [NarrationFeedback.shakeExtended]);
    // Now outside the last minute again: the sensor is released.
    expect(accel.hasListener, isFalse);

    h.controller.setSleep(SleepChoice.off);
    expect(accel.hasListener, isFalse);
  });

  test('shake to extend off never subscribes', () async {
    final accel = StreamController<AccelSample>.broadcast();
    addTearDown(accel.close);
    h.dispose();
    h = await NarrationHarness.create(extra: [accelerometerSourceProvider.overrideWithValue(() => accel.stream)]);
    await h.container.read(listenSettingsProvider.notifier).put({'shakeToExtend': false});
    await h.startAndSettle(listenTarget());
    h.controller.setSleep(SleepChoice.minutes(1));
    expect(accel.hasListener, isFalse);
  });
}
