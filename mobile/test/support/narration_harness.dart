import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_audio_handler_provider.dart';
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';
import 'package:manhwamaniacs/features/novels/services/narration_player.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/novels/support/fake_novels_repository.dart';
import 'fake_narration_player.dart';
import 'test_overrides.dart';

Map<String, dynamic> listenFixture(String name) =>
    jsonDecode(File('test/fixtures/listen/$name.json').readAsStringSync()) as Map<String, dynamic>;

NovelAudio listenAudio({bool stale = false}) => NovelAudio.fromJson(listenFixture(stale ? 'audio-stale' : 'audio'));

List<String> listenParagraphs() => (listenFixture('chapter')['paragraphs'] as List).cast<String>();

NarrationTarget listenTarget({String chapter = 'c12', bool stale = false, String? file}) => NarrationTarget(
      key: (sourceId: 'src', seriesKey: 'book', chapterKey: chapter),
      audio: listenAudio(stale: stale),
      paragraphs: listenParagraphs(),
      bookTitle: 'Omniscient Reader',
      chapterNumber: 12,
      chapterTitle: 'The Tower',
      narratorName: 'Iris',
      file: file,
    );

/// A container wired with a fake player, a scripted probe, a manual clock and a fake repository.
class NarrationHarness {
  NarrationHarness._();

  final players = <FakeNarrationPlayer>[];
  final probeStatuses = <int>[];
  final probeUrls = <String>[];
  final probeHeaders = <Map<String, String>>[];
  final timers = <(Duration, void Function())>[];
  final sessionStates = <AudioSessionState>[];
  final repo = FakeNovelsRepository();
  final handler = NarrationAudioHandler();
  DateTime clock = DateTime.utc(2026, 9, 30, 12);
  late ProviderContainer container;
  DownloadsStore? store;

  FakeNarrationPlayer get player => players.last;
  NarrationController get controller => container.read(narrationControllerProvider.notifier);
  NarrationState get state => container.read(narrationControllerProvider);

  void advance(int seconds) => clock = clock.add(Duration(seconds: seconds));

  static Future<NarrationHarness> create({DownloadsStore? store, List<Override> extra = const []}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final h = NarrationHarness._();
    h.store = store;
    h.container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authenticatedAuthOverride(),
        activeProfileOverride(),
        novelsRepositoryProvider.overrideWithValue(h.repo),
        audioHandlerProvider.overrideWithValue(h.handler),
        downloadsStoreProvider.overrideWithValue(store),
        narrationPlayerFactoryProvider.overrideWithValue(() {
          final p = FakeNarrationPlayer();
          h.players.add(p);
          return p;
        }),
        narrationProbeProvider.overrideWithValue((url, headers) async {
          h.probeUrls.add(url);
          h.probeHeaders.add(headers);
          final status = h.probeStatuses.isEmpty ? 206 : h.probeStatuses.removeAt(0);
          return (status: status, retryAfter: const Duration(seconds: 1));
        }),
        narrationSessionProvider.overrideWithValue((s) async => h.sessionStates.add(s)),
        narrationClockProvider.overrideWithValue(() => h.clock),
        narrationTimerProvider.overrideWithValue((d, cb) {
          h.timers.add((d, cb));
          return _NoopTimer();
        }),
        ...extra,
      ],
    );
    return h;
  }

  /// Start [target] and let the async load finish.
  Future<void> startAndSettle(NarrationTarget target, {int startMs = 0, bool play = true}) async {
    await controller.start(target, startMs: startMs, play: play);
    await settle();
  }

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Waits (in real time, for sqlite's isolate) until [condition] holds.
  Future<void> waitFor(bool Function() condition) async {
    for (var i = 0; i < 400 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  void dispose() => container.dispose();
}

class _NoopTimer implements Timer {
  @override
  void cancel() {}
  @override
  bool get isActive => true;
  @override
  int get tick => 0;
}
