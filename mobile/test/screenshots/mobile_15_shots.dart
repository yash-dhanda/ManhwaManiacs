// ignore_for_file: require_trailing_commas, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Override, ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/audio_save_state.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/voice_row.dart';

import '../features/novels/support/fake_novels_repository.dart';
import '../skins/cinematic/feature/feature_test_support.dart';
import '../skins/cinematic/listen/listen_test_support.dart';
import '../support/downloads_test_support.dart';
import '../support/test_overrides.dart';
import 'support/series_shots.dart';
import 'support/shot_covers.dart';
import 'support/skin_shots.dart';

/// The mobile-15 proof shots: Listen mode, "The reading", over the Alice fixture chapter, the 31
/// fixture voices and a fake player. No real audio plays on this box.
void mobile15Shots() {
  final phone = kSkinShotSizes[0];
  final tablet = kSkinShotSizes[1];

  Future<ListenRig> rig(
    WidgetTester tester, {
    SkinShotSize? size,
    bool owner = true,
    bool stale = false,
    bool reduced = false,
    bool online = true,
    bool audio = true,
    bool legacy = false,
    int probe = 206,
    Set<String> narrated = const {'1', '2', '3'},
    Map<String, Object> prefs = const {},
    List<Override> extra = const [],
  }) async {
    final s = size ?? phone;
    final png = await tester.runAsync(() => const ShotCoverArt(title: 'Tower of Dawn', seed: 3).toPng(width: 480, height: 720));
    final l = await pumpListen(
      tester,
      size: s.logical,
      padding: s.padding,
      owner: owner,
      stale: stale,
      reduced: reduced,
      online: online,
      audio: audio,
      legacy: legacy,
      narrated: narrated,
      prefsValues: prefs,
      boundaryKey: kSkinShotKey,
      extra: [narrationProbeProvider.overrideWithValue((url, headers) async => (status: probe, retryAfter: const Duration(seconds: 3600))), ...extra],
    );
    CineImage.providerBuilder = (url, headers) => MemoryImage(png!);
    await settleNovel(tester, ms: 800);
    return l;
  }

  Future<void> start(ListenRig l) async {
    await l.tester.tap(find.byKey(const Key('opener-listen')));
    await l.settle();
  }

  Future<void> openRoom(ListenRig l) async {
    await l.tester.tap(find.bySemanticsLabel(RegExp('Open the reading room')));
    await settleNovel(l.tester, ms: 900);
  }

  Future<void> shot(ListenRig l, String name, SkinShotSize size) async {
    await captureSeriesShot(l.tester, name, size);
  }

  Future<void> end(ListenRig l) async {
    await leaveListen(l);
  }

  Future<void> showChrome(WidgetTester tester, SkinShotSize size) async {
    await tester.tapAt(Offset(size.logical.width / 2, size.logical.height / 2));
    await settleNovel(tester, ms: 500);
  }

  testWidgets('mobile-15 mini player', (tester) async {
    for (final size in [phone, tablet]) {
      final l = await rig(tester, size: size);
      await start(l);
      await showChrome(tester, size);
      await shot(l, 'mini-player', size);
      await end(l);
    }
    var l = await rig(tester, probe: 503);
    await start(l);
    await showChrome(tester, phone);
    await shot(l, 'mini-player-preparing', phone);
    await end(l);
    await tester.pump(const Duration(seconds: 3601));
    l = await rig(tester, probe: 500);
    await start(l);
    await showChrome(tester, phone);
    await shot(l, 'mini-player-failed', phone);
    await end(l);
  });

  testWidgets('mobile-15 following along', (tester) async {
    for (final size in [phone, tablet]) {
      final l = await rig(tester, size: size);
      await start(l);
      await l.tick(9000);
      await settleNovel(tester, ms: 100);
      await shot(l, 'follow-along-sweep', size);
      await settleNovel(tester, ms: 600);
      await shot(l, 'follow-along', size);
      await end(l);
    }
    var l = await rig(tester);
    await l.rig.settings({'layout': 'paged'});
    await settleNovel(tester, ms: 800);
    await start(l);
    await l.tick(20000);
    await settleNovel(tester, ms: 700);
    await shot(l, 'follow-along-paged', phone);
    await end(l);

    l = await rig(tester);
    await start(l);
    await l.tick(9000);
    await settleNovel(tester, ms: 500);
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await settleNovel(tester, ms: 500);
    await shot(l, 'back-to-the-voice', phone);
    await end(l);
  });

  testWidgets('mobile-15 reading room', (tester) async {
    for (final size in [phone, tablet]) {
      final l = await rig(tester, size: size);
      await start(l);
      await l.tick(9000);
      await openRoom(l);
      await settleNovel(tester, ms: 400);
      await shot(l, 'reading-room', size);
      await end(l);
    }
    var l = await rig(tester);
    await start(l);
    await l.tick(31000);
    await openRoom(l);
    await settleNovel(tester, ms: 600);
    await shot(l, 'reading-room-dialogue-kickers', phone);
    await end(l);

    l = await rig(tester, stale: true);
    await start(l);
    await l.tick(500);
    await openRoom(l);
    await shot(l, 'reading-room-highlight-paused', phone);
    await end(l);

    for (final size in [phone, tablet]) {
      l = await rig(tester, size: size);
      await start(l);
      await openRoom(l);
      l.player.finish();
      await l.settle();
      await settleNovel(tester, ms: 800);
      await shot(l, 'reading-room-post-play', size);
      await end(l);
      await tester.pump(const Duration(seconds: 6));
    }
    l = await rig(tester);
    await start(l);
    l.player.finish();
    await l.settle();
    await settleNovel(tester, ms: 900);
    await shot(l, 'post-play-above-mini-player', phone);
    await end(l);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('mobile-15 sheets', (tester) async {
    var l = await rig(tester);
    await start(l);
    await openRoom(l);
    await tester.tap(find.byKey(const Key('tile-speed')));
    await settleNovel(tester, ms: 800);
    await shot(l, 'speed-sheet', phone);
    await end(l);

    l = await rig(tester);
    await start(l);
    await openRoom(l);
    await tester.tap(find.byKey(const Key('tile-sleep')));
    await settleNovel(tester, ms: 800);
    await shot(l, 'sleep-sheet', phone);
    await end(l);

    l = await rig(tester);
    await start(l);
    l.narration.setSleep(SleepChoice.minutes(15));
    await openRoom(l);
    await settleNovel(tester, ms: 1200);
    await shot(l, 'sleep-countdown-tile', phone);
    l.narration.setSleep(SleepChoice.off);
    await end(l);
  });

  Future<ListenRig> castSheet(WidgetTester tester, {bool owner = true, SkinShotSize? size, List<Override> extra = const []}) async {
    final l = await rig(tester, owner: owner, size: size, extra: extra);
    await showChrome(tester, size ?? phone);
    await tester.tap(find.bySemanticsLabel('Voices').first);
    await settleNovel(tester, ms: 800);
    return l;
  }

  testWidgets('mobile-15 cast and voices', (tester) async {
    var l = await castSheet(tester);
    await shot(l, 'cast-sheet-owner', phone);
    await tester.tap(find.text('Alice'));
    await settleNovel(tester, ms: 800);
    await shot(l, 'voice-picker', phone);
    await tester.tap(find.text('ALL'));
    await settleNovel(tester, ms: 400);
    final hear = find.descendant(of: find.widgetWithText(VoiceRow, 'Voice 22'), matching: find.text('Hear'));
    await tester.ensureVisible(hear);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(hear);
    await l.settle();
    await settleNovel(tester, ms: 300);
    await shot(l, 'voice-picker-hear-pulse', phone);
    await end(l);

    l = await castSheet(tester, owner: false);
    await shot(l, 'cast-sheet-readonly', phone);
    await end(l);

    l = await castSheet(tester, size: tablet);
    await tester.tap(find.text('Alice'));
    await settleNovel(tester, ms: 800);
    await tester.tap(find.text('ALL'));
    await settleNovel(tester, ms: 400);
    await shot(l, 'voice-picker', tablet);
    await end(l);

    l = await castSheet(tester, extra: [emptyVoicesOverride()]);
    await tester.tap(find.text('Alice'));
    await settleNovel(tester, ms: 800);
    await shot(l, 'voice-picker-empty', phone);
    await end(l);

    l = await castSheet(tester, extra: [seriesAudioDetailProvider.overrideWith((ref, k) async => seriesDetailWithStale())]);
    await settleNovel(tester, ms: 600);
    await shot(l, 're-narrate-footer', phone);
    await end(l);
  });

  Future<void> book(WidgetTester tester, String name, {bool canRender = true, bool unavailable = false, List<NovelAudioJob> jobs = const [], bool save = false, bool listenOnly = false}) async {
    final repo = FakeNovelsRepository()
      ..seriesAudioDetailResult = Ok((renderedAt: {'c1': DateTime.utc(2026, 9), 'c2': DateTime.utc(2026, 9, 10), 'c3': DateTime.utc(2026, 9, 25)}, narratable: {for (var i = 1; i <= 11; i++) 'c$i'}, canRender: canRender, castChangedAt: DateTime.utc(2026, 9, 20)))
      ..activeJobsResult = Ok(jobs)
      ..audioJobsResults = [Ok(jobs)];
    if (unavailable) repo.requestAudioResult = const Err(ApiError(statusCode: 503, code: 'narration_unavailable', message: 'unavailable'));
    final harness = save ? (await tester.runAsync(TestDownloadsHarness.create))! : null;
    final r = FeatureRig(narrated: const {'c1', 'c2', 'c3'}, extra: [
      authenticatedAuthOverride(),
      novelsRepositoryProvider.overrideWithValue(repo),
      seriesAudioDetailProvider.overrideWith((ref, k) async => repo.seriesAudioDetailResult.value),
      if (harness != null) downloadsStoreProvider.overrideWithValue(harness.storeFor('u1p1')),
    ]);
    await pumpFeature(tester, rig: r, novel: true, size: phone.logical, child: BookView(data: fixtureData('novel-short')));
    tester.view.padding = FakeViewPadding(top: phone.padding.top, bottom: phone.padding.bottom);
    await settleFeature(tester, by: const Duration(seconds: 2));
    if (!listenOnly) {
      await tester.tap(find.byKey(const Key('audiobook-button')));
      await settleFeature(tester, by: const Duration(milliseconds: 900));
      if (save) {
        await tester.tap(find.text('SAVE TO THIS DEVICE'));
        await settleFeature(tester, by: const Duration(milliseconds: 400));
        await tester.ensureVisible(find.text('ALL NARRATED'));
        await tester.tap(find.text('ALL NARRATED'));
      } else if (!canRender || !unavailable) {
        await tester.ensureVisible(find.text('ALL UN-NARRATED'));
        await tester.tap(find.text('ALL UN-NARRATED'));
      }
      await settleFeature(tester, by: const Duration(milliseconds: 500));
      if (unavailable) {
        await tester.tap(find.textContaining('Narrate '));
        await settleFeature(tester, by: const Duration(milliseconds: 600));
      }
    }
    await captureSeriesShot(tester, name, phone);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
    if (harness != null) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.runAsync(harness.dispose);
    }
  }

  testWidgets('mobile-15 audiobook', (tester) async {
    await book(tester, 'audiobook-narrate');
    await book(tester, 'audiobook-save', save: true);
    await book(tester, 'audiobook-jobs', jobs: const [
      NovelAudioJob(jobId: 'j1', chapterKey: 'c4', chapterNumber: 4, status: 'queued', progress: 0, errorCode: null),
      NovelAudioJob(jobId: 'j2', chapterKey: 'c5', chapterNumber: 5, status: 'rendering', progress: 0.4, errorCode: null),
      NovelAudioJob(jobId: 'j3', chapterKey: 'c6', chapterNumber: 6, status: 'failed', progress: 0.1, errorCode: 'render_failed', errorDetail: 'The render box dropped the job.'),
    ]);
    await book(tester, 'audiobook-unavailable', unavailable: true);
    await book(tester, 'book-page-listen', listenOnly: true);
  });

  testWidgets('mobile-15 states', (tester) async {
    var l = await rig(tester, narrated: const {});
    await shot(l, 'opener-not-narrated-owner', phone);
    await end(l);

    l = await rig(tester, audio: false, online: false);
    await shot(l, 'offline-no-audio', phone);
    await end(l);

    l = await rig(tester, reduced: true);
    await start(l);
    await l.tick(9000);
    await openRoom(l);
    await settleNovel(tester, ms: 400);
    await shot(l, 'reduced-motion-reading-room', phone);
    await end(l);

    l = await rig(tester, legacy: true);
    await showChrome(tester, phone);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await l.settle();
    await settleNovel(tester, ms: 500);
    await shot(l, 'legacy-audio-player', phone);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('mobile-15 audio save states', (tester) async {
    Widget row(SavedAudioState s, String title) => ProviderScope(
          overrides: [
            savedAudioStateProvider.overrideWith((ref, key) => s),
            downloadQueueControllerProvider.overrideWith(() => RecordingQueue(Recorder())),
          ],
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: AudioSaveRow(chapter: (sourceId: 's', seriesKey: 'b', chapterKey: title))),
        );
    await captureSkinWidget(
      tester,
      name: 'audio-save-states',
      size: phone,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: featureTheme(TargetPlatform.android),
        home: Scaffold(body: Container(
        color: const Color(0xFF0F0E0C),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final s in [SavedAudioState.none, SavedAudioState.preparing, SavedAudioState.saving, SavedAudioState.saved, SavedAudioState.failed, SavedAudioState.unplayable]) row(s, s.name),
        ]),
      ),),),
      overrides: [matureGateOpenProvider.overrideWithValue(true)],
      settle: (t) async {
        for (var i = 0; i < 12; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      },
    );
  });
}
