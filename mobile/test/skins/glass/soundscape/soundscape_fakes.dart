import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/features/reader/services/soundscape_files.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/generator.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/procedural_store.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_controller.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

/// Records every call the mixer makes. The FFI engine cannot run in `flutter test`.
class FakeSoundscapeAudio implements SoundscapeAudio {
  final List<String> calls = [];
  bool ready = true;
  bool throwOnPlay = false;
  int _next = 0;
  final Map<int, double> volumes = {};
  final Set<int> stopped = {}, paused = {}, disposed = {};
  final Map<int, String> names = {};
  final List<({int handle, double to, Duration over})> fades = [];
  final List<({int source, double volume, double pan, bool looping})> plays = [];

  @override
  bool get isReady => ready;

  @override
  Future<dynamic> loadMem(String name, Uint8List bytes) async {
    final id = _next++;
    names[id] = name;
    calls.add('loadMem $name');
    return id;
  }

  @override
  Future<dynamic> loadFile(String path) async {
    final id = _next++;
    names[id] = path;
    calls.add('loadFile $path');
    return id;
  }

  @override
  dynamic play(dynamic source, {double volume = 1, double pan = 0, bool looping = false}) {
    if (throwOnPlay) throw StateError('play failed');
    final h = _next++;
    volumes[h] = volume;
    plays.add((source: source as int, volume: volume, pan: pan, looping: looping));
    names[h] = names[source] ?? '';
    calls.add('play ${names[source]} looping=$looping');
    return h;
  }

  @override
  void setVolume(dynamic handle, double v) => volumes[handle as int] = v;

  @override
  void fadeVolume(dynamic handle, double to, Duration duration) {
    fades.add((handle: handle as int, to: to, over: duration));
    volumes[handle] = to;
    calls.add('fade ${names[handle]} -> ${to.toStringAsFixed(3)} over ${duration.inMilliseconds}');
  }

  @override
  void setPause(dynamic handle, bool p) {
    p ? paused.add(handle as int) : paused.remove(handle as int);
    calls.add('pause ${names[handle]} $p');
  }

  @override
  Future<void> stop(dynamic handle) async {
    stopped.add(handle as int);
    calls.add('stop ${names[handle]}');
  }

  @override
  Future<void> disposeSource(dynamic source) async {
    disposed.add(source as int);
  }

  @override
  Duration getPosition(dynamic handle) => Duration.zero;

  @override
  Future<Float32List?> envelopeOfFile(String path, int samples) async => null;

  /// Voices (loop plays) currently live.
  Iterable<int> get live => plays.where((p) => p.looping).map((p) => volumes.keys.firstWhere((h) => names[h] == names[p.source] && !stopped.contains(h), orElse: () => -1)).where((h) => h >= 0);

  List<int> loopHandles(String name) => [for (final e in names.entries) if (e.value == name && volumes.containsKey(e.key)) e.key];
}

class FakeStore extends ProceduralStore {
  FakeStore() : super(root: () async => Directory.systemTemp);

  @override
  Future<SceneAssets> assets(SoundScene s) async => SceneAssets(
        loops: {for (final e in kRecipes[s]!.entries) if (e.value == LayerKind.loop) e.key: Uint8List(8)},
        banks: {for (final e in kRecipes[s]!.entries) if (e.value == LayerKind.events) e.key: [Uint8List(8), Uint8List(8)]},
        envelopes: {for (final e in kRecipes[s]!.entries) if (e.value == LayerKind.loop) e.key: Float32List(kEnvelopeLength)},
      );
}

class FakeFiles extends GlassSoundscapeFiles {
  FakeFiles() : super(Dio());
  final Set<String> have = {};
  final List<String> asked = [];
  Completer<void>? hold;

  @override
  Future<File?> ensure(String scene, String layer) async {
    asked.add('$scene-$layer');
    if (hold != null) await hold!.future;
    return have.contains('$scene-$layer') ? File('/fake/$scene-$layer.ogg') : null;
  }
}

class FakeSession implements SoundscapeSession {
  final List<AudioSessionState> requests = [];
  // ignore: close_sinks
  final StreamController<bool> interruption = StreamController<bool>.broadcast();
  AudioSessionState _s = AudioSessionState.idle;

  @override
  Future<void> request(AudioSessionState s) async {
    requests.add(s);
    _s = s;
  }

  @override
  AudioSessionState get state => _s;

  @override
  Stream<bool> get interruptions => interruption.stream;
}

class FakeNarration extends NarrationController {
  final ValueNotifier<SleepState> sleep = ValueNotifier(const SleepState());

  @override
  NarrationState build() => const NarrationState();

  @override
  ValueListenable<SleepState> get sleepState => sleep;

  void setPlaying(bool on) => state = NarrationState(status: on ? NarrationStatus.playing : NarrationStatus.idle);
}

class SoundscapeRig {
  SoundscapeRig._(this.container, this.audio, this.files, this.session, this.music);
  final ProviderContainer container;
  final FakeSoundscapeAudio audio;
  final FakeFiles files;
  final FakeSession session;
  final bool Function() music;

  SoundscapeController get controller => container.read(soundscapeControllerProvider.notifier);
  SoundscapeView get view => container.read(soundscapeControllerProvider);
  FakeNarration get narration => container.read(narrationControllerProvider.notifier) as FakeNarration;

  static Future<SoundscapeRig> create({bool musicOn = false, Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final audio = FakeSoundscapeAudio(), files = FakeFiles(), session = FakeSession();
    var music = musicOn;
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(sp),
      authenticatedAuthOverride(),
      activeProfileOverride(),
      soundscapeAudioProvider.overrideWithValue(audio),
      proceduralStoreProvider.overrideWithValue(FakeStore()),
      glassSoundscapeFilesProvider.overrideWithValue(files),
      soundscapeSessionProvider.overrideWithValue(session),
      musicActiveProvider.overrideWithValue(() async => music),
      narrationControllerProvider.overrideWith(FakeNarration.new),
    ],);
    final rig = SoundscapeRig._(c, audio, files, session, () => music);
    c.listen(soundscapeControllerProvider, (_, __) {});
    c.listen(narrationControllerProvider, (_, __) {});
    rig.setMusic = (v) => music = v;
    return rig;
  }

  late void Function(bool) setMusic;
}
