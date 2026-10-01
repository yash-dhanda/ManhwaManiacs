// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart' show AccelerometerEvent;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart' show gravitySensorProvider;
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_audio_handler_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart' show seriesAudioProvider;
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';
import 'package:manhwamaniacs/features/novels/services/narration_player.dart';
import 'package:manhwamaniacs/features/novels/services/voice_sample_player.dart';
import 'package:manhwamaniacs/features/novels/utils/shake_detector.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_sheets.dart' show registerListenSheets;
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../features/novels/support/fake_novels_repository.dart';
import '../../../support/fake_narration_player.dart';
import '../../../support/test_overrides.dart';
import '../novel/novel_rig.dart';

Map<String, dynamic> listenJson(String name) => jsonDecode(File('test/fixtures/listen/$name.json').readAsStringSync()) as Map<String, dynamic>;

List<NovelVoice> listenVoices() => [for (final v in (listenJson('voices')['voices'] as List).cast<Map<String, dynamic>>()) NovelVoice.fromJson(v)];

NovelAudio listenAudioFixture({bool stale = false}) => NovelAudio.fromJson(listenJson(stale ? 'audio-stale' : 'audio'));

/// An attribution whose cast has a narrator voice (voice-20) and three characters, two with voices.
NovelAttribution listenAttributionFixture() => NovelAttribution.fromJson(listenJson('attribution'));

class StubSampleEngine implements SampleEngine {
  final List<String> played = [];
  final List<Object> stopped = [];
  @override
  Future<void> init() async {}
  @override
  Future<Object> play(String name, Uint8List bytes) async {
    played.add(name);
    return name;
  }

  @override
  List<double> waveform() => List.filled(256, 0.4);
  @override
  ({double position, double length})? progress(Object handle) => (position: 2, length: 8);
  @override
  bool isPlaying(Object handle) => true;
  @override
  Future<void> stop(Object handle) async => stopped.add(handle);
}

/// The Glass novel reader with Listen wired to fakes: a fake player, no probe, no audio session, the fixture audio for the
/// narrated chapters, the 31 fixture voices and the fixture attribution; the signed-in user is the admin.
class GlassListenRig {
  GlassListenRig({required this.novel, required this.players, required this.repo, required this.handler, required this.sessions, required this.sampler});
  final GlassNovelRig novel;
  final List<FakeNarrationPlayer> players;
  final FakeNovelsRepository repo;
  final NarrationAudioHandler handler;
  final List<AudioSessionState> sessions;
  final StubSampleEngine sampler;

  WidgetTester get tester => novel.tester;
  FakeNarrationPlayer get player => players.last;
  ProviderContainer get container => novel.container;
  NarrationController get narration => container.read(narrationControllerProvider.notifier);
  NarrationState get state => container.read(narrationControllerProvider);

  Future<void> settle({int ms = 100}) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
    await tester.pump(Duration(milliseconds: ms));
  }

  /// Starts the fixture chapter's narration through the host and lets the load finish.
  Future<void> startNarration({int startMs = 0, bool stale = false}) async {
    await tester.runAsync(() => container.read(narrationControllerProvider.notifier).start(_target(stale: stale), startMs: startMs));
    await settle();
  }

  NarrationTarget _target({bool stale = false}) => NarrationTarget(
        key: (sourceId: kNovelSource, seriesKey: kNovelSeries, chapterKey: '1'),
        audio: listenAudioFixture(stale: stale),
        paragraphs: novelChapterFor('1').paragraphs,
        bookTitle: 'Omniscient Reader',
        chapterNumber: 12,
        chapterTitle: 'The Tower',
        narratorName: 'Iris',
      );

  Future<void> tick(int ms) async {
    player.tick(ms);
    await settle();
  }
}

List<String> listenParagraphsFixture() => (listenJson('unit-chapter')['paragraphs'] as List).cast<String>();

/// The fakes and overrides every listen test and proof capture shares: a fake player, the scripted probe, no audio session, the
/// fixture audio for the narrated chapters, the 31 fixture voices and the fixture attribution.
class ListenFakes {
  ListenFakes({this.probeStatus = 206, this.failLoad = false}) {
    repo
      ..voicesResult = Ok(listenVoices())
      ..attributionResult = Ok(listenAttributionFixture())
      ..voiceSampleResult = const Ok(<int>[79, 103, 103, 83]);
  }

  final List<FakeNarrationPlayer> players = [];
  final List<AudioSessionState> sessions = [];
  final FakeNovelsRepository repo = FakeNovelsRepository();
  final NarrationAudioHandler handler = NarrationAudioHandler();
  final StubSampleEngine sampler = StubSampleEngine();
  int probeStatus;
  bool failLoad;

  List<Override> overrides({bool owner = true, bool online = true, bool stale = false, Set<String> narrated = const {'1', '2', '3'}, bool audio = true}) => [
        if (owner) authenticatedAuthOverride(),
        activeDownloadsScopeIdProvider.overrideWithValue(null),
        novelsRepositoryProvider.overrideWithValue(repo),
        audioHandlerProvider.overrideWithValue(handler),
        deviceOnlineProvider.overrideWith((ref) => Stream.value(online)),
        narrationPlayerFactoryProvider.overrideWithValue(() {
          final p = FakeNarrationPlayer()..failLoad = failLoad;
          players.add(p);
          return p;
        }),
        narrationProbeProvider.overrideWithValue((url, headers) async => (status: probeStatus, retryAfter: const Duration(seconds: 2))),
        narrationSessionProvider.overrideWithValue((s) async => sessions.add(s)),
        accelerometerSourceProvider.overrideWithValue(() => const Stream<AccelSample>.empty()),
        glassAccelerometerSourceProvider.overrideWithValue(() => const Stream<AccelSample>.empty()),
        voiceSampleSessionProvider.overrideWithValue((begin: () async {}, end: () async {})),
        sampleEngineProvider.overrideWithValue(sampler),
        gravitySensorProvider.overrideWithValue(() => const Stream<AccelerometerEvent>.empty()),
        playableNovelAudioProvider.overrideWith((ref, key) async {
          if (!audio || !narrated.contains(key.chapterKey)) return null;
          return (audio: listenAudioFixture(stale: stale), file: null);
        }),
        novelVoicesProvider.overrideWith((ref) async => listenVoices()),
        seriesAudioProvider.overrideWith((ref, k) async => (rendered: narrated, narratable: {for (var i = 1; i <= 12; i++) '$i'}, canRender: true)),
      ];
}

class _RouterHolder {
  GoRouter? router;
}

Future<GlassListenRig> pumpGlassListen(
  WidgetTester tester, {
  bool owner = true,
  bool online = true,
  bool stale = false,
  Set<String> narrated = const {'1', '2', '3'},
  bool audio = true,
  Size size = const Size(390, 844),
  bool reduced = false,
  bool android = false,
  String chapterKey = '1',
  String query = '',
  Map<String, Object> prefs = const {},
  List<Override> extra = const [],
  bool pushed = true,
  Key? boundaryKey,
  bool accessibleNavigation = false,
}) async {
  registerListenSheets();
  // Covers go through the cache manager, which asks for a temp directory.
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, (_) async => Directory.systemTemp.path);
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null));
  final fakes = ListenFakes();
  final holder = _RouterHolder();
  final novel = await pumpGlassNovel(
    tester,
    size: size,
    reduced: reduced,
    android: android,
    chapterKey: chapterKey,
    query: query,
    prefs: prefs,
    pushed: pushed,
    attribution: listenAttributionFixture(),
    boundaryKey: boundaryKey,
    accessibleNavigation: accessibleNavigation,
    extra: [
      ...fakes.overrides(owner: owner, online: online, stale: stale, narrated: narrated, audio: audio),
      skinRouterProvider.overrideWith((ref) => holder.router!),
      ...extra,
    ],
  );
  holder.router = novel.router;
  return GlassListenRig(novel: novel, players: fakes.players, repo: fakes.repo, handler: fakes.handler, sessions: fakes.sessions, sampler: fakes.sampler);
}
