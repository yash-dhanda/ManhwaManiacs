// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_audio_handler_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';
import 'package:manhwamaniacs/features/novels/services/narration_player.dart';
import 'package:manhwamaniacs/features/novels/services/voice_sample_player.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

import '../../../features/novels/support/fake_novels_repository.dart';
import '../../../support/fake_narration_player.dart';
import '../../../support/test_overrides.dart';
import '../novel/novel_test_support.dart';

export '../novel/novel_test_support.dart' show settleNovel, disposeNovel, fixtureParagraphs;

Map<String, dynamic> fixtureJson(String name) => jsonDecode(File('test/fixtures/listen/$name.json').readAsStringSync()) as Map<String, dynamic>;

List<NovelVoice> fixtureVoices() => [for (final v in (fixtureJson('voices')['voices'] as List).cast<Map<String, dynamic>>()) NovelVoice.fromJson(v)];

NovelAttribution listenAttribution() {
  final base = fixtureAttribution();
  return NovelAttribution(
    attributed: true,
    narrator: 'Iris',
    narratorVoiceId: 'voice-20',
    cast: [
      const NovelCastMember(name: 'Alice', gender: 'female', voiceId: 'voice-21', locked: true, lineCount: 34),
      const NovelCastMember(name: 'White Rabbit', gender: 'male', voiceId: 'voice-03', lineCount: 12),
    ],
    textFingerprint: base.textFingerprint,
    spans: base.spans,
  );
}

class _StubSampleEngine implements SampleEngine {
  @override
  Future<void> init() async {}
  @override
  Future<Object> play(String name, Uint8List bytes) async => name;
  @override
  List<double> waveform() => List.filled(256, 0.4);
  @override
  ({double position, double length})? progress(Object handle) => (position: 2, length: 8);
  @override
  bool isPlaying(Object handle) => true;
  @override
  Future<void> stop(Object handle) async {}
}

/// The Cinematic novel reader with Listen wired to fakes: a fake player, no probe, no audio
/// session, the fixture audio for every chapter, the 31 fixture voices and a narrator.
class ListenRig {
  ListenRig({required this.rig, required this.players, required this.repo, required this.handler, required this.sessions});
  final NovelRig rig;
  final List<FakeNarrationPlayer> players;
  final FakeNovelsRepository repo;
  final NarrationAudioHandler handler;
  final List<AudioSessionState> sessions;

  FakeNarrationPlayer get player => players.last;
  ProviderContainer get container => rig.container;
  NarrationController get narration => container.read(narrationControllerProvider.notifier);
  NarrationState get state => container.read(narrationControllerProvider);
  WidgetTester get tester => rig.tester;

  /// Lets the narration's async loading and the frames after it run.
  Future<void> settle({int ms = 100}) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
    await settleNovel(tester, ms: ms);
  }

  Future<void> tick(int ms) async {
    player.tick(ms);
    await settle();
  }
}

Future<ListenRig> pumpListen(
  WidgetTester tester, {
  bool owner = true,
  bool stale = false,
  Set<String> narrated = const {'1', '2', '3'},
  bool audio = true,
  Size? size,
  bool wide = false,
  EdgeInsets padding = EdgeInsets.zero,
  bool reduced = false,
  double textScale = 1,
  TargetPlatform platform = TargetPlatform.android,
  String query = '',
  Map<String, Object> prefsValues = const {},
  List<String>? paragraphs,
  List<Override> extra = const [],
  Key? boundaryKey,
  bool legacy = false,
}) async {
  // No network and no cache directory for the cover behind the reading room.
  final probe = CineImage.cacheProbe, builder = CineImage.providerBuilder;
  CineImage.cacheProbe = (_) async => true;
  CineImage.providerBuilder = (url, headers) => MemoryImage(base64Decode(_kPng));
  addTearDown(() {
    CineImage.cacheProbe = probe;
    CineImage.providerBuilder = builder;
  });
  final players = <FakeNarrationPlayer>[];
  final sessions = <AudioSessionState>[];
  final repo = FakeNovelsRepository()
    ..voicesResult = Ok(fixtureVoices())
    ..voiceSampleResult = const Ok(<int>[79, 103, 103, 83]);
  final handler = NarrationAudioHandler();
  final rig = await pumpNovel(
    tester,
    size: size,
    wide: wide,
    padding: padding,
    reduced: reduced,
    textScale: textScale,
    platform: platform,
    query: query,
    prefsValues: prefsValues,
    paragraphs: paragraphs,
    boundaryKey: boundaryKey,
    attribution: listenAttribution(),
    legacy: legacy,
    rig: FeatureRig(narrated: narrated),
    extra: [
      if (owner) authenticatedAuthOverride(),
      // The open-chapter scope releases its claim in a microtask that outlives the container.
      activeDownloadsScopeIdProvider.overrideWithValue(null),
      novelsRepositoryProvider.overrideWithValue(repo),
      audioHandlerProvider.overrideWithValue(handler),
      narrationPlayerFactoryProvider.overrideWithValue(() {
        final p = FakeNarrationPlayer();
        players.add(p);
        return p;
      }),
      narrationProbeProvider.overrideWithValue((url, headers) async => (status: 206, retryAfter: null)),
      narrationSessionProvider.overrideWithValue((s) async => sessions.add(s)),
      voiceSampleSessionProvider.overrideWithValue((begin: () async {}, end: () async {})),
      sampleEngineProvider.overrideWithValue(_StubSampleEngine()),
      playableNovelAudioProvider.overrideWith((ref, key) async {
        if (!audio || !narrated.contains(key.chapterKey)) return null;
        return (audio: NovelAudio.fromJson(fixtureJson(stale ? 'audio-stale' : 'audio')), file: null);
      }),
      novelVoicesProvider.overrideWith((ref) async => fixtureVoices()),
      ...extra,
    ],
  );
  return ListenRig(rig: rig, players: players, repo: repo, handler: handler, sessions: sessions);
}

/// Leaves the reader the way a person does (the back arrow), so its progress save runs while the
/// container is alive, then tears the tree down.
Future<void> leaveListen(ListenRig l) async {
  if (l.rig.router.canPop()) l.rig.router.pop();
  await settleNovel(l.tester, ms: 600);
  await l.tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await disposeNovel(l.tester);
}

/// A 1 x 1 PNG.
const _kPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
