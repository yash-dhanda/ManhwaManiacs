import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/novels/services/voice_sample_player.dart';

import '../../../support/narration_harness.dart';

class _FakeEngine implements SampleEngine {
  final List<String> log = [];
  final List<Uint8List> loaded = [];
  bool playing = true;
  double position = 0;
  List<double> wave = List.filled(256, 0.5);

  @override
  Future<void> init() async => log.add('init');

  @override
  Future<Object> play(String name, Uint8List bytes) async {
    log.add('play $name');
    loaded.add(bytes);
    return name;
  }

  @override
  List<double> waveform() => wave;

  @override
  ({double position, double length})? progress(Object handle) => (position: position, length: 10);

  @override
  bool isPlaying(Object handle) => playing;

  @override
  Future<void> stop(Object handle) async => log.add('stop $handle');
}

void main() {
  late NarrationHarness h;
  late _FakeEngine engine;
  late List<String> session;

  Future<void> setUpHarness() async {
    engine = _FakeEngine();
    session = [];
    h = await NarrationHarness.create(
      extra: [
        sampleEngineProvider.overrideWithValue(engine),
        voiceSampleSessionProvider.overrideWithValue((
          begin: () async => session.add('begin'),
          end: () async => session.add('end'),
        ),),
      ],
    );
  }

  VoiceSamplePlayer player() => h.container.read(voiceSamplePlayerProvider.notifier);
  SampleState state() => h.container.read(voiceSamplePlayerProvider);

  testWidgets('Hear fetches through the authenticated client, plays via loadMem, and stops', (tester) async {
    await tester.runAsync(setUpHarness);
    addTearDown(h.dispose);
    await tester.runAsync(() async {
      await player().play('voice-03');
    });
    expect(h.repo.voiceSampleRequests, ['voice-03']);
    expect(engine.log, ['init', 'play voice-sample-voice-03.ogg']);
    expect(engine.loaded.single, [1, 2, 3]);
    expect(state().isPlaying('voice-03'), isTrue);
    expect(session, ['begin']);

    await tester.runAsync(() => player().stop());
    expect(engine.log.last, 'stop voice-sample-voice-03.ogg');
    expect(state().status, SampleStatus.idle);
    expect(session, ['begin', 'end']);
  });

  testWidgets('the pulse follows the RMS and progress follows the clip', (tester) async {
    await tester.runAsync(setUpHarness);
    addTearDown(h.dispose);
    await tester.runAsync(() => player().play('voice-03'));
    engine.position = 5;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    expect(player().pulse.value, greaterThan(0.1));
    expect(state().progress, closeTo(0.5, 0.01));
    engine.wave = List.filled(256, 0);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(player().pulse.value, lessThan(0.05));
    await tester.runAsync(() => player().stop());
  });

  testWidgets('a sample ends by itself when the engine says it stopped', (tester) async {
    await tester.runAsync(setUpHarness);
    addTearDown(h.dispose);
    await tester.runAsync(() => player().play('voice-03'));
    engine.playing = false;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect(state().status, SampleStatus.idle);
    expect(session, ['begin', 'end']);
  });

  testWidgets('only one sample at a time; the second replaces the first', (tester) async {
    await tester.runAsync(setUpHarness);
    addTearDown(h.dispose);
    await tester.runAsync(() async {
      await player().play('voice-03');
      await player().play('voice-05');
    });
    expect(engine.log.where((l) => l.startsWith('stop')), ['stop voice-sample-voice-03.ogg']);
    expect(state().voiceId, 'voice-05');
    await tester.runAsync(() => player().stop());
  });

  testWidgets('a sample pauses narration and resumes it', (tester) async {
    await tester.runAsync(setUpHarness);
    addTearDown(h.dispose);
    await tester.runAsync(() async {
      await h.startAndSettle(listenTarget());
      expect(h.player.playing, isTrue);
      await player().play('voice-03');
      await h.settle();
      expect(h.player.playing, isFalse);
      await player().stop();
      await h.settle();
      expect(h.player.playing, isTrue);
    });
  });

  testWidgets('the last 8 clips stay in memory; a repeat does not refetch', (tester) async {
    await tester.runAsync(setUpHarness);
    addTearDown(h.dispose);
    await tester.runAsync(() async {
      for (var i = 1; i <= 10; i++) {
        await player().play('v$i');
      }
      expect(h.repo.voiceSampleRequests, hasLength(10));
      expect(player().cached('v1'), isNull);
      expect(player().cached('v2'), isNull);
      expect(player().cached('v3'), isNotNull);
      await player().play('v10');
      expect(h.repo.voiceSampleRequests, hasLength(10));
      await player().stop();
    });
  });

  testWidgets('a failed fetch is a failed state, not a crash', (tester) async {
    await tester.runAsync(setUpHarness);
    addTearDown(h.dispose);
    h.repo.voiceSampleResult = const Err(NetworkError(message: 'offline'));
    await tester.runAsync(() => player().play('voice-03'));
    expect(state().failed, isTrue);
    expect(state().status, SampleStatus.idle);
    expect(engine.log, isEmpty);
  });
}
