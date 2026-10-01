@Tags(['screenshots'])
library;

// ignore_for_file: require_trailing_commas, directives_ordering

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart' show SavedAudioState;
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/repositories/novels_repository.dart' show NovelSeriesAudioDetail;
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/listen/audiobook_button.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/player_column.dart' show GlassPlayerColumn;
import 'package:manhwamaniacs/skins/glass/listen/post_play_card.dart' show glassPostPlayProvider;
import 'package:manhwamaniacs/skins/glass/listen/save_audio.dart' show saveAudioLabel;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show SkinGlassRoot;

import '../../skins/cinematic/novel/novel_test_support.dart' as cine;
import '../../skins/glass/listen/listen_rig.dart';
import '../glass_shell_shots_support.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/37 proof captures (glass 8.16): Listen mode through the real Glass router on the `mobile/15` fixtures, with the fakes of
/// `test/skins/glass/listen/listen_rig.dart`. Written only when `MM_PROOF_DIR` is set; otherwise rasterised and discarded.

const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
const _tablet = SkinShotSize('tablet', Size(834, 1194), 2.0, EdgeInsets.only(top: 24, bottom: 20));

class _Wake implements ReaderWakelock {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

class _Reduced extends GlassInAppPrefsController {
  @override
  GlassInAppPrefs build() => const GlassInAppPrefs(reduceMotion: true);
}

List<Override> _novel({bool online = true}) => [
      readerWakelockProvider.overrideWithValue(_Wake()),
      sourcesListProvider.overrideWith((ref) async => const [SourceSummary(id: 'demo', name: 'Demo Source', description: '', browsable: true, supportsImport: false)]),
      sourceSeriesDetailProvider.overrideWith((ref, k) async => SourceSeriesDetailData(series: cine.loadSeriesFixture('manga-ongoing').series, chapters: cine.novelChapters())),
      resolvedNovelChapterProvider.overrideWith((ref, key) async => cine.novelChapterFor(key.chapterKey)),
      novelChapterNeighboursProvider.overrideWith((ref, key) async {
        final n = int.tryParse(key.chapterKey) ?? 1;
        return (previousChapterKey: n > 1 ? '${n - 1}' : null, nextChapterKey: n < 12 ? '${n + 1}' : null);
      }),
      novelAttributionProvider.overrideWith((ref, key) async => listenAttributionFixture()),
      seriesChapterDownloadStatusProvider.overrideWith((ref, k) async => const {}),
      deviceOnlineProvider.overrideWith((ref) => Stream.value(online)),
    ];

const _key1 = (sourceId: 'demo', seriesKey: 'k', chapterKey: '1');

Future<void> _frames(WidgetTester t, int ms) async {
  for (var e = 0; e < ms; e += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _end(WidgetTester t, [ShotSession? s]) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(seconds: 11));
}

String _name(String n) => n.endsWith('-desktop-frame') ? n.substring(0, n.length - '-desktop-frame'.length) : n;

Future<void> _snap(ShotSession s, String name, SkinShotSize size) => s.snap(_name(name), size);

class _Open {
  _Open(this.s, this.fakes);
  final ShotSession s;
  final ListenFakes fakes;
  WidgetTester get t => s.t;
  ProviderContainer get c => s.container;
  NarrationController get narr => c.read(narrationControllerProvider.notifier);
  GlassNarrationActions get actions => c.read(glassNarrationActionsProvider);

  /// Starts the fixture chapter's narration (the first sentence, playing) and lets the frames after it run.
  Future<void> start({int startMs = 0, bool stale = false}) async {
    final audio = listenAudioFixture(stale: stale);
    final target = NarrationTarget(
      key: _key1,
      audio: audio,
      paragraphs: cine.novelChapterFor('1').paragraphs,
      bookTitle: 'Omniscient Reader',
      chapterNumber: 1,
      chapterTitle: 'Down the Rabbit-Hole',
      narratorName: 'Voice 20',
    );
    await t.runAsync(() => narr.start(target, startMs: startMs));
    for (var i = 0; i < 8; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
    await _frames(t, 300);
  }

  void tick(int ms) => fakes.players.last.tick(ms);

  Future<void> chrome(SkinShotSize size) async {
    await t.tapAt(Offset(size.logical.width / 2, size.logical.height * 0.55));
    await _frames(t, 600);
  }

  Future<void> sheet(String query, {int ms = 1500}) async {
    final uri = s.router.routerDelegate.currentConfiguration.uri;
    s.router.go('${uri.path}?$query');
    await _frames(t, ms);
  }
}

Future<_Open> _open(WidgetTester t, SkinShotSize size, {String start = '/novels/demo/k/1', ListenFakes? fakes, List<Override> extra = const [], bool owner = true, bool online = true, Set<String> narrated = const {'1', '2', '3'}, bool stale = false, Map<String, dynamic>? settings}) async {
  final f = fakes ?? ListenFakes();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, (_) async => Directory.systemTemp.path);
  addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null));
  final s = await openShell(t, size, start: start, extra: [..._novel(online: online), ...f.overrides(owner: owner, online: online, narrated: narrated, stale: stale), ...extra], settle: false);
  if (settings != null) await s.container.read(novelSettingsProvider.notifier).put(settings);
  for (var i = 0; i < 6; i++) {
    await s.settle(300);
  }
  return _Open(s, f);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('listen row and accessories', (t) async {
    var o = await _open(t, _phone);
    await o.start();
    await o.chrome(_phone);
    await _snap(o.s, 'listen-row', _phone);
    await _end(t, o.s);

    // 503 audio_preparing: the play button shows the liquid ring.
    o = await _open(t, _phone, fakes: ListenFakes(probeStatus: 503));
    await o.start();
    await o.chrome(_phone);
    await _frames(t, 300);
    await _snap(o.s, 'listen-row-preparing', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone, fakes: ListenFakes(failLoad: true));
    await o.start();
    await o.chrome(_phone);
    await _snap(o.s, 'listen-row-failed', _phone);
    await _end(t, o.s);

    o = await _open(t, kSkinShotLandscape);
    await o.start();
    await o.chrome(kSkinShotLandscape);
    await _snap(o.s, 'listen-row', kSkinShotLandscape);
    await _end(t, o.s);

    o = await _open(t, _phone, start: '/library');
    await o.start();
    await _frames(t, 600);
    await _snap(o.s, 'accessory-narrating', _phone);
    await t.fling(find.byType(Scrollable).first, const Offset(0, -500), 1200);
    await _frames(t, 900);
    await _snap(o.s, 'accessory-minimised', _phone);
    await _end(t, o.s);

    o = await _open(t, kSkinShotTabletWide, start: '/library');
    await o.start();
    await _frames(t, 600);
    await _snap(o.s, 'desktop-accessory-desktop-frame', kSkinShotTabletWide);
    await _end(t, o.s);

    o = await _open(t, _tablet, start: '/library');
    await o.start();
    await _frames(t, 600);
    await _snap(o.s, 'desktop-accessory-rail', _tablet);
    await _end(t, o.s);
  });

  testWidgets('the full player', (t) async {
    var o = await _open(t, _phone);
    await o.start();
    o.tick(1000);
    await o.sheet('sheet=player');
    // ignore: avoid_print
    print('PLAYER? ${find.text('Now narrating').evaluate().length} ${glassSheetSpec('player') != null} ${glassSheetClaimed('player')} ${find.byType(GlassPlayerColumn).evaluate().length} ${o.s.router.routerDelegate.currentConfiguration.uri}');
    await _snap(o.s, 'player-medium', _phone);
    // Drag the sheet up to large.
    await t.dragFrom(const Offset(195, 440), const Offset(0, -420));
    await _frames(t, 900);
    await _snap(o.s, 'player-large', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone);
    await o.start();
    o.tick(25000);
    await o.sheet('sheet=player');
    await _snap(o.s, 'speaking-orb-speaker', _phone);
    await _end(t, o.s);

    o = await _open(t, kSkinShotTabletWide);
    await o.start();
    o.tick(1000);
    await o.sheet('sheet=player');
    await _snap(o.s, 'player-window-desktop-frame', kSkinShotTabletWide);
    await _end(t, o.s);

    o = await _open(t, kSkinShotTabletWide);
    await o.start();
    o.tick(1000);
    await o.chrome(kSkinShotTabletWide);
    await _frames(t, 800);
    await _snap(o.s, 'player-listen-tab-desktop-frame', kSkinShotTabletWide);
    await _end(t, o.s);

    o = await _open(t, _phone);
    await o.start();
    o.tick(1000);
    await o.sheet('sheet=player');
    await t.dragFrom(const Offset(195, 700), const Offset(0, -200));
    await _frames(t, 500);
    await _snap(o.s, 'sentence-list-decoupled', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone);
    await o.start();
    await o.sheet('sheet=player');
    o.c.read(glassPostPlayProvider.notifier).state = _key1;
    await _frames(t, 900);
    await _snap(o.s, 'post-play', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone, online: false);
    await o.sheet('sheet=player');
    await o.start();
    await _frames(t, 600);
    await _snap(o.s, 'offline-no-audio', _phone);
    await _end(t, o.s);
  });

  testWidgets('speed, sleep, voices and cast', (t) async {
    var o = await _open(t, _phone);
    await o.start();
    await o.sheet('sheet=player');
    await t.tapAt(const Offset(60, 790));
    await _frames(t, 900);
    await _snap(o.s, 'speed-dial', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone);
    await o.start();
    await o.sheet('sheet=player');
    await t.tapAt(const Offset(330, 790));
    await _frames(t, 900);
    await _snap(o.s, 'sleep-menu', _phone);
    await t.tap(find.text('15 min'));
    await _frames(t, 900);
    await _snap(o.s, 'sleep-countdown-tile', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone);
    await o.sheet('sheet=cast');
    await _snap(o.s, 'cast-owner', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone, owner: false);
    await o.sheet('sheet=cast');
    await _snap(o.s, 'cast-readonly', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone);
    await o.sheet('sheet=voices');
    await _frames(t, 800);
    await _snap(o.s, 'orbit-playing-transcript', _phone);
    await t.dragFrom(const Offset(300, 500), const Offset(-176, 0));
    await _frames(t, 100);
    await _snap(o.s, 'orbit', _phone);
    await _end(t, o.s);

    o = await _open(t, kSkinShotTabletWide);
    await o.sheet('sheet=voices');
    await t.tap(find.text('Grid'));
    await _frames(t, 700);
    await _snap(o.s, 'orbit-grid-desktop-frame', kSkinShotTabletWide);
    await _end(t, o.s);

    final empty = ListenFakes();
    o = await _open(t, _phone, fakes: empty, extra: [novelVoicesProvider.overrideWith((ref) async => const <NovelVoice>[])]);
    await o.sheet('sheet=voices');
    await _snap(o.s, 'orbit-empty', _phone);
    await _end(t, o.s);
  });

  testWidgets('audiobook', (t) async {
    NovelSeriesAudioDetail detail({bool canRender = true}) => (
          renderedAt: {'1': DateTime.utc(2026, 9), '2': DateTime.utc(2026, 9, 2), '3': DateTime.utc(2026, 9, 3)},
          narratable: {for (var i = 1; i <= 10; i++) '$i'},
          canRender: canRender,
          castChangedAt: null,
        );
    Future<_Open> open({bool canRender = true, List<NovelAudioJob> jobs = const []}) async {
      final f = ListenFakes();
      f.repo
        ..seriesAudioDetailResult = Ok(detail(canRender: canRender))
        ..audioJobsResults = [Ok(jobs)];
      final o = await _open(t, _phone, fakes: f, extra: [seriesAudioProvider.overrideWith((ref, k) async => (rendered: {'1', '2', '3'}, narratable: {for (var i = 1; i <= 10; i++) '$i'}, canRender: canRender))]);
      await o.sheet('sheet=audiobook&series=demo:k');
      return o;
    }

    var o = await open();
    await t.tap(find.text('Next 10'));
    await _frames(t, 400);
    await _snap(o.s, 'audiobook-narrate', _phone);
    await _end(t, o.s);

    o = await open(jobs: const [
      NovelAudioJob(jobId: 'j1', chapterKey: '4', status: 'queued', progress: 0, errorCode: null, chapterNumber: 4),
      NovelAudioJob(jobId: 'j2', chapterKey: '5', status: 'rendering', progress: 0.42, errorCode: null, chapterNumber: 5),
      NovelAudioJob(jobId: 'j3', chapterKey: '6', status: 'failed', progress: 0, errorCode: 'lease_expired', chapterNumber: 6),
      NovelAudioJob(jobId: 'j4', chapterKey: '7', status: 'cancelled', progress: 0, errorCode: null, chapterNumber: 7),
    ]);
    await _snap(o.s, 'audiobook-jobs', _phone);
    await _end(t, o.s);

    o = await open(canRender: false);
    await _snap(o.s, 'audiobook-unavailable', _phone);
    await _end(t, o.s);

    final f = ListenFakes();
    f.repo.audioJobsResults = [const Ok([NovelAudioJob(jobId: 'j2', chapterKey: '5', status: 'rendering', progress: 0.42, errorCode: null, chapterNumber: 5)])];
    o = await _open(t, _phone, start: '/downloads', fakes: f, extra: [
      activeNarrationJobsProvider.overrideWith((ref) => const [NarrationJob(sourceId: 'demo', seriesKey: 'k', title: 'Omniscient Reader', done: 0, total: 3, average: 0.4)]),
    ]);
    await _frames(t, 600);
    await _snap(o.s, 'narrating-chip', _phone);
    await _end(t, o.s);
  });

  testWidgets('highlight, follow and states', (t) async {
    var o = await _open(t, _phone);
    await o.start();
    o.tick(1000);
    await _frames(t, 700);
    await _snap(o.s, 'highlight-band', _phone);
    o.tick(11000);
    await _frames(t, 900);
    await _snap(o.s, 'highlight-band-multiline', _phone);
    await t.dragFrom(const Offset(195, 600), const Offset(0, 200));
    await _frames(t, 500);
    await o.chrome(_phone);
    await _snap(o.s, 'back-to-the-voice', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone, stale: true);
    await o.start(stale: true);
    await _frames(t, 700);
    await _snap(o.s, 'highlight-paused', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone, settings: {'layout': 'paged'});
    await _frames(t, 800);
    await o.start();
    o.tick(35000);
    await _frames(t, 1200);
    await _snap(o.s, 'paged-narration-turn', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone);
    await o.start();
    await o.sheet('sheet=player');
    await _snap(o.s, 'solid-player', _phone);
    await _end(t, o.s);

    o = await _open(t, _phone, extra: [glassInAppPrefsProvider.overrideWith(_Reduced.new)]);
    await o.start();
    await o.sheet('sheet=player');
    await _snap(o.s, 'reduced-motion-player', _phone);
    await _end(t, o.s);
  });

  testWidgets('book page status and save states', (t) async {
    final f = ListenFakes();
    Widget col(List<Widget> kids) => Material(color: const Color(0xFF000000), child: Padding(padding: const EdgeInsets.fromLTRB(20, 80, 20, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: kids)));
    await captureSkinWidget(
      t,
      name: 'book-page-audiobook-status',
      size: _phone,
      overrides: [
        ...f.overrides(),
        seriesAudioProvider.overrideWith((ref, k) async => (rendered: {for (var i = 1; i <= 40; i++) '$i'}, narratable: {for (var i = 1; i <= 40; i++) '$i'}, canRender: true)),
      ],
      child: SkinGlassRoot(child: col(const [GlassAudiobookButton(sourceId: 'demo', seriesKey: 'k')])),
    );
    await captureSkinWidget(
      t,
      name: 'save-audio-states',
      size: _phone,
      child: col([
        for (final st in SavedAudioState.values) Text(saveAudioLabel(st), style: const TextStyle(color: Color(0xFFF2F2F7), fontSize: 17)),
      ]),
    );
  });
}
