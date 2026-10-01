// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/shake_detector.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/audio_save_state.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/narrating_indicator.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import '../../../support/downloads_test_support.dart';
import '../feature/feature_test_support.dart';
import 'listen_test_support.dart';

void main() {
  initSqfliteFfiForTests();

  testWidgets('?listen=1 starts the narrator once the first frame is laid out', (tester) async {
    final l = await pumpListen(tester, query: '?listen=1');
    await settleNovel(tester, ms: 800);
    await l.settle();
    expect(l.players, hasLength(1));
    expect(l.state.status, NarrationStatus.playing);
    expect(l.state.key!.chapterKey, '1');
    await leaveListen(l);
  });

  testWidgets('without ?listen=1 nothing plays until asked', (tester) async {
    final l = await pumpListen(tester);
    await settleNovel(tester, ms: 800);
    await l.settle();
    expect(l.players, isEmpty);
    await leaveListen(l);
  });

  testWidgets('offline with no saved audio the opener says so', (tester) async {
    final l = await pumpListen(tester, audio: false, online: false);
    await settleNovel(tester, ms: 800);
    expect(find.byKey(const Key('opener-offline-no-audio')), findsOneWidget);
    expect(find.text("This chapter's audio isn't saved on this device."), findsOneWidget);
    expect(find.byKey(const Key('opener-listen')), findsNothing);
    await leaveListen(l);
  });

  testWidgets('shake to extend: the accelerometer is read only in the last minute, and a shake adds five minutes with a toast', (tester) async {
    final accel = StreamController<AccelSample>.broadcast();
    addTearDown(accel.close);
    final l = await pumpListen(tester, extra: [accelerometerSourceProvider.overrideWithValue(() => accel.stream)]);
    await settleNovel(tester, ms: 800);
    await tester.tap(find.byKey(const Key('opener-listen')));
    await l.settle();
    l.narration.setSleep(SleepChoice.minutes(30));
    expect(accel.hasListener, isFalse);
    l.narration.setSleep(SleepChoice.minutes(1));
    expect(accel.hasListener, isTrue);
    AccelSample s(double m, int ms) => (x: m, y: 0, z: 0, at: DateTime.utc(2026).add(Duration(milliseconds: ms)));
    accel
      ..add(s(30, 0))
      ..add(s(1, 100))
      ..add(s(30, 250));
    await l.settle(ms: 200);
    expect(l.narration.sleepState.value.remaining! > const Duration(minutes: 5), isTrue);
    expect(find.text('Sleep timer +5 min'), findsOneWidget);
    expect(l.rig.rec.haptics, contains('select'));
    await tester.pump(const Duration(seconds: 5));
    l.narration.setSleep(SleepChoice.off);
    await leaveListen(l);
  });

  testWidgets('the sleep fade fires the sleep.fade haptic at its start and the player is paused at the end', (tester) async {
    final l = await pumpListen(tester);
    await settleNovel(tester, ms: 800);
    await tester.tap(find.byKey(const Key('opener-listen')));
    await l.settle();
    l.narration.setSleep(SleepChoice.minutes(1));
    await settleNovel(tester, ms: 53000);
    expect(l.rig.rec.haptics, contains('sleep.fade'));
    expect(l.player.volumes.isNotEmpty, isTrue);
    expect(l.player.volumes.last, lessThan(1));
    await settleNovel(tester, ms: 9000);
    await l.settle();
    expect(l.player.playing, isFalse);
    expect(l.player.volumes.last, 1);
    await leaveListen(l);
  });

  testWidgets('reduced motion: the room and the band appear at once', (tester) async {
    final l = await pumpListen(tester, reduced: true);
    await settleNovel(tester, ms: 800);
    await tester.tap(find.byKey(const Key('opener-listen')));
    await l.settle();
    await l.tick(500);
    final audio = fixtureParagraphs()[0];
    final para = tester.widget<NovelParagraph>(find.byWidgetPredicate((w) => w is NovelParagraph && w.text == audio).first);
    final band = para.decorations.where((d) => d.fill == cinematicTokens.colorSpotWash).single;
    expect(band.sweep, 1.0);
    await tester.tap(find.bySemanticsLabel(RegExp('Open the reading room')));
    await settleNovel(tester, ms: 250);
    expect(find.text('NOW READING ALOUD'), findsOneWidget);
    await leaveListen(l);
  });

  group('saved audio on the device', () {
    Future<void> pumpRow(WidgetTester tester, SavedAudioState state, {List<Override> extra = const []}) async {
      final harness = (await tester.runAsync(TestDownloadsHarness.create))!;
      addTearDown(harness.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matureGateOpenProvider.overrideWithValue(true),
            downloadsStoreProvider.overrideWithValue(harness.storeFor('u1p1')),
            savedAudioStateProvider.overrideWith((ref, key) => state),
            downloadQueueControllerProvider.overrideWith(() => RecordingQueue(Recorder())),
            ...extra,
          ],
          child: MaterialApp(
            theme: featureTheme(TargetPlatform.android),
            home: const Scaffold(body: AudioSaveRow(chapter: (sourceId: 's', seriesKey: 'b', chapterKey: 'c1'))),
          ),
        ),
      );
      await tester.pump();
    }

    test('the words of each state', () {
      expect(audioSaveCaption(SavedAudioState.none), isNull);
      expect(audioSaveCaption(SavedAudioState.preparing), 'Preparing the audio…');
      expect(audioSaveCaption(SavedAudioState.saving), 'Saving audio…');
      expect(audioSaveCaption(SavedAudioState.saved), 'Audio saved');
      expect(audioSaveCaption(SavedAudioState.failed), "Couldn't save the audio. Tap to try again.");
      expect(audioSaveCaption(SavedAudioState.unplayable), "The saved audio can't play on this device. Tap to save it again.");
    });

    for (final (state, text) in [
      (SavedAudioState.none, 'Save audio to this device'),
      (SavedAudioState.preparing, 'Preparing the audio…'),
      (SavedAudioState.saving, 'Saving audio…'),
      (SavedAudioState.saved, 'Audio saved'),
      (SavedAudioState.failed, "Couldn't save the audio. Tap to try again."),
      (SavedAudioState.unplayable, "The saved audio can't play on this device. Tap to save it again."),
    ]) {
      testWidgets('the row reads "$text" for ${state.name}', (tester) async {
        await pumpRow(tester, state);
        expect(find.text(text), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a saved chapter asks before removing, with the arm', (tester) async {
      await pumpRow(tester, SavedAudioState.saved);
      await tester.tap(find.text('Audio saved'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Remove saved audio?'), findsOneWidget);
      expect(find.text('The chapter stays on this device to read.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the row is not built without a downloads scope', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [downloadsStoreProvider.overrideWithValue(null)],
          child: MaterialApp(theme: featureTheme(TargetPlatform.android), home: const Scaffold(body: AudioSaveRow(chapter: (sourceId: 's', seriesKey: 'b', chapterKey: 'c1')))),
        ),
      );
      expect(find.byKey(const Key('audio-save-row')), findsNothing);
    });
  });

  group('NarratingIndicator', () {
    testWidgets('NARRATING 3 CHAPTERS with the average progress', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: featureTheme(TargetPlatform.android),
            home: const Scaffold(body: NarratingIndicator(jobs: [NarrationJob(sourceId: 's', seriesKey: 'b', title: 'Book', done: 0, total: 3, average: 0.25)])),
          ),
        ),
      );
      expect(find.text('NARRATING 3 CHAPTERS'), findsOneWidget);
    });

    testWidgets('nothing when nothing is narrating', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: featureTheme(TargetPlatform.android), home: const Scaffold(body: NarratingIndicator(jobs: [])))));
      expect(find.byKey(const Key('narrating-indicator')), findsNothing);
    });
  });
}
