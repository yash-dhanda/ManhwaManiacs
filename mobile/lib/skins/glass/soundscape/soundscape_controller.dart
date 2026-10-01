import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/core/platform/mm_platform.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/features/reader/providers/soundscape_defaults_provider.dart';
import 'package:manhwamaniacs/features/reader/services/soundscape_files.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart' show registerMatureStop, registerPlaybackStop;
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/procedural_store.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

/// glass 9.4.2 States.
enum SoundscapeState { off, starting, playingRecorded, playingBuiltin, paused, muted, ducked, unavailable }

/// What the sheet, the orbs and the Aa badge read.
class SoundscapeView {
  const SoundscapeView({
    this.state = SoundscapeState.off,
    this.scene,
    this.matchedScene,
    this.mix = const MixLevels(),
    this.volumeDb = -12,
    this.remember = false,
    this.builtin = false,
  });

  final SoundscapeState state;
  final SoundScene? scene;

  /// The scene Match the story picked for the open series, shown under its orb.
  final SoundScene? matchedScene;
  final MixLevels mix;
  final int volumeDb;

  /// "Remember for this series" is on (inside a reader).
  final bool remember;

  /// At least one layer plays its procedural fallback (the `cloud-slash` badge, after the first 2 s).
  final bool builtin;

  bool get on => state != SoundscapeState.off && state != SoundscapeState.unavailable;

  /// "Off", "Rain", "Rain · built-in", "Rain · muted": the Ambient row's value.
  String get summary {
    final s = scene;
    if (!on || s == null) return 'Off';
    return switch (state) {
      SoundscapeState.muted => '${s.label} · muted',
      SoundscapeState.paused => '${s.label} · paused',
      _ => builtin ? '${s.label} · built-in' : s.label,
    };
  }

  SoundscapeView copyWith({
    SoundscapeState? state,
    SoundScene? scene,
    bool clearScene = false,
    SoundScene? matchedScene,
    bool clearMatched = false,
    MixLevels? mix,
    int? volumeDb,
    bool? remember,
    bool? builtin,
  }) =>
      SoundscapeView(
        state: state ?? this.state,
        scene: clearScene ? null : (scene ?? this.scene),
        matchedScene: clearMatched ? null : (matchedScene ?? this.matchedScene),
        mix: mix ?? this.mix,
        volumeDb: volumeDb ?? this.volumeDb,
        remember: remember ?? this.remember,
        builtin: builtin ?? this.builtin,
      );
}

/// The open reader as the soundscape sees it.
class SoundscapeReaderContext {
  const SoundscapeReaderContext({required this.seriesRef, this.genres = const [], this.rememberedScene, this.rememberedMix, this.mature = false});
  final String seriesRef;
  final List<String> genres;
  final SoundScene? rememberedScene;
  final MixLevels? rememberedMix;
  final bool mature;
}

// ── Ports (replaced in tests) ────────────────────────────────────────────────────────────────────

final soundscapeAudioProvider = Provider<SoundscapeAudio>((ref) => const SoLoudSoundscapeAudio(), name: 'soundscapeAudio');
final proceduralStoreProvider = Provider<ProceduralStore>((ref) => ProceduralStore(), name: 'proceduralStore');
final glassSoundscapeFilesProvider = Provider<GlassSoundscapeFiles>(
  (ref) => GlassSoundscapeFiles(ref.watch(dioProvider), online: () => PlatformNetworkConnectivity().isOnline()),
  name: 'glassSoundscapeFiles',
);

/// Other audio is playing: iOS `secondaryAudioShouldBeSilencedHint`, Android `audio.isMusicActive`.
final musicActiveProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) return await AVAudioSession().secondaryAudioShouldBeSilencedHint;
      return await ref.read(mmPlatformProvider).isMusicActive();
    } catch (_) {
      return false;
    }
  },
  name: 'musicActive',
);

/// The audio-session owner (`skin_audio.dart`): this controller never calls `AudioSession.configure` itself.
abstract interface class SoundscapeSession {
  Future<void> request(AudioSessionState s);
  AudioSessionState get state;
  Stream<bool> get interruptions;
}

class SkinAudioSession implements SoundscapeSession {
  const SkinAudioSession();
  @override
  Future<void> request(AudioSessionState s) => SkinAudio.instance.request(s);
  @override
  AudioSessionState get state => SkinAudio.instance.state;
  @override
  Stream<bool> get interruptions async* {
    try {
      final s = await AudioSession.instance;
      yield* s.interruptionEventStream.map((e) => e.begin);
    } catch (_) {}
  }
}

final soundscapeSessionProvider = Provider<SoundscapeSession>((ref) => const SkinAudioSession(), name: 'soundscapeSession');

// ── The controller ───────────────────────────────────────────────────────────────────────────────

/// One soundscape for the app: the commands `start`, `stop`, `setMix`, `setVolume`, `unmute`, and the reader's `enterReader` / `leaveReader`.
/// It owns the mixer, fades in 3 s and out 1.5 s, ducks under narration, follows the sleep timer, pauses in the background and leaves no
/// voice playing when the container is disposed (a skin switch, a profile switch, a sign-out).
class SoundscapeController extends Notifier<SoundscapeView> with WidgetsBindingObserver {
  late SoundscapeMixer _mixer;
  SoundscapeReaderContext? _reader;
  StreamSubscription<bool>? _interruptions;
  Timer? _settle, _sessionIdle;
  final ValueNotifier<List<double>> levels = ValueNotifier(List.filled(8, 0));
  Timer? _levelTimer;
  int _levelClients = 0;
  bool _narrationPlaying = false, _backgrounded = false, _interrupted = false;
  bool _starting = false, _settled = false;
  int _run = 0;
  ValueListenable<SleepState>? _sleep;
  VoidCallback? _unregisterMature;

  @override
  SoundscapeView build() {
    _mixer = SoundscapeMixer(ref.read(soundscapeAudioProvider));
    WidgetsBinding.instance.addObserver(this);
    ref.listen<bool>(narrationControllerProvider.select((s) => s.isPlaying), (_, playing) => _onNarration(playing), fireImmediately: false);
    _interruptions = ref.read(soundscapeSessionProvider).interruptions.listen(_onInterruption);
    _bindSleep();
    // Sign-out, a profile switch (and the 18+ gate for a mature series) stop it at once (glass 8.0.8, 8.0.9).
    final unregister = registerPlaybackStop('soundscape', stopNow);
    ref.onDispose(() {
      unregister();
      _unregisterMature?.call();
      WidgetsBinding.instance.removeObserver(this);
      _interruptions?.cancel();
      _settle?.cancel();
      _sessionIdle?.cancel();
      _levelTimer?.cancel();
      _sleep?.removeListener(_onSleep);
      levels.dispose();
      unawaited(_mixer.dispose());
    });
    final d = ref.read(soundscapeDefaultsProvider);
    return SoundscapeView(mix: MixLevels(bed: d.bed, detail: d.detail, tone: d.tone), volumeDb: d.volumeDb);
  }

  void _bindSleep() {
    try {
      _sleep = ref.read(narrationControllerProvider.notifier).sleepState..addListener(_onSleep);
    } catch (_) {
      // No narration controller in this container: no sleep timer to follow.
    }
  }

  SoundscapeSession get _session => ref.read(soundscapeSessionProvider);
  SoundscapeMixer get mixer => _mixer;

  // ── Commands ────────────────────────────────────────────────────────────────────────────────

  Future<void> start(SoundScene scene) async {
    if (_starting) return;
    _starting = true;
    final run = ++_run;
    try {
      final audio = ref.read(soundscapeAudioProvider);
      if (!audio.isReady) return _fail();
      _settle?.cancel();
      _settled = false;
      _sessionIdle?.cancel();
      final mix = (_reader?.rememberedScene == scene ? _reader?.rememberedMix : null) ?? state.mix;
      state = state.copyWith(state: SoundscapeState.starting, scene: scene, mix: mix, builtin: false);
      if (!_narrationPlaying) await _session.request(AudioSessionState.soundscape);
      final assets = await ref.read(proceduralStoreProvider).assets(scene);
      if (run != _run) return;
      final music = await ref.read(musicActiveProvider)();
      await _mixer.start(scene, assets, mix: state.mix, masterDb: state.volumeDb.toDouble(), muted: music);
      if (run != _run) return;
      if (_narrationPlaying) _applyNarration();
      if (music) _toastMusic();
      _publish();
      unawaited(_fetchRecorded(scene, run));
      _settle = Timer(const Duration(seconds: 2), _settleState);
    } catch (e) {
      debugPrint('soundscape start failed: $e');
      await _fail();
    } finally {
      _starting = false;
    }
  }

  Future<void> _fail() async {
    await _mixer.stop(immediate: true);
    state = state.copyWith(state: SoundscapeState.off, clearScene: true, builtin: false);
    ref.read(glassToastProvider.notifier).show(const GlassToastSpec("Couldn't start the soundscape", kind: GlassToastKind.error));
    _idleSession();
  }

  Future<void> stop() async {
    _run++;
    _settle?.cancel();
    final was = state.on;
    state = state.copyWith(state: SoundscapeState.off, clearScene: true, builtin: false);
    if (was) await _mixer.stop();
    _idleSession(after: const Duration(milliseconds: 1500));
  }

  /// Now, with no fade: the 18+ purge, sign-out and a profile switch.
  void stopNow() {
    _run++;
    _settle?.cancel();
    state = state.copyWith(state: SoundscapeState.off, clearScene: true, builtin: false);
    unawaited(_mixer.stop(immediate: true));
    _idleSession();
  }

  void setMix(SoundLayer layer, double v) {
    final mix = state.mix.with_(layer, v);
    state = state.copyWith(mix: mix);
    _mixer.setMix(layer, v);
  }

  void setVolume(int db) {
    final v = db.clamp(-30, 0);
    state = state.copyWith(volumeDb: v);
    _mixer.setMasterDb(v.toDouble());
  }

  /// The toast's "Tap to mix the soundscape in": unmutes over 1 s.
  void unmute() {
    _mixer.setMuted(false);
    _publish();
  }

  void setRemember(bool on) => state = state.copyWith(remember: on);

  /// Starts what a freshly opened reader should hear: the remembered scene, then Match the story, then the default scene.
  /// Returns the scene it started (null when none is due). Coming back to a paused scene resumes it.
  Future<SoundScene?> enterReader(SoundscapeReaderContext ctx) async {
    _reader = ctx;
    _unregisterMature?.call();
    _unregisterMature = ctx.mature ? registerMatureStop('soundscape', stopNow) : null;
    final matched = matchScene(ctx.genres);
    final d = ref.read(soundscapeDefaultsProvider);
    state = state.copyWith(matchedScene: matched, remember: ctx.rememberedScene != null);
    if (_mixer.playing && state.state == SoundscapeState.paused) {
      _mixer.resume();
      _publish();
      return state.scene;
    }
    if (state.on) return state.scene;
    final remembered = ctx.rememberedScene;
    SoundScene? due = remembered;
    if (due == null && d.scene != 'off') due = chooseScene(matchStory: d.matchStory, genres: ctx.genres, fallback: SoundScene.byName(d.scene));
    if (due == null) return null;
    ref.read(proceduralStoreProvider).assets(due).ignore(); // prewarm: the reader's first frame never waits for it
    await start(due);
    return due;
  }

  /// Leaving the reader: fade out over 1.5 s and pause (it resumes on return in this app session).
  void leaveReader() {
    _reader = null;
    if (state.on && !_narrationPlaying) {
      _mixer.pause();
      state = state.copyWith(state: SoundscapeState.paused);
    }
  }

  // ── State ───────────────────────────────────────────────────────────────────────────────────

  void _settleState() {
    _settled = true;
    _publish();
  }

  /// Composes the visible state from the mixer's flags.
  void _publish() {
    final s = state.scene;
    if (s == null || !_mixer.playing) return;
    final recorded = _mixer.recordedLayers, builtin = _mixer.builtinLayers;
    final allRecorded = builtin.every(recorded.contains) && recorded.isNotEmpty;
    final settled = _settled;
    SoundscapeState next;
    if (_mixer.paused) {
      next = SoundscapeState.paused;
    } else if (_mixer.muted) {
      next = SoundscapeState.muted;
    } else if (_mixer.ducked) {
      next = SoundscapeState.ducked;
    } else if (!settled) {
      next = SoundscapeState.starting;
    } else {
      next = allRecorded ? SoundscapeState.playingRecorded : SoundscapeState.playingBuiltin;
    }
    state = state.copyWith(state: next, builtin: settled && !allRecorded);
  }

  Future<void> _fetchRecorded(SoundScene scene, int run) async {
    final files = ref.read(glassSoundscapeFilesProvider);
    await Future.wait([
      for (final layer in SoundLayer.values)
        () async {
          final f = await files.ensure(scene.name, layer.name);
          if (f == null || run != _run || !_mixer.playing) return;
          if (await _mixer.attachRecorded(layer, f.path)) _publish();
        }(),
    ]);
  }

  void _toastMusic() {
    ref.read(glassToastProvider.notifier).show(GlassToastSpec(
          'Your music is playing. Tap to mix the soundscape in.',
          actionLabel: 'Mix in',
          onAction: unmute,
        ),);
  }

  // ── Narration, sleep, lifecycle, interruptions ──────────────────────────────────────────────

  void _onNarration(bool playing) {
    _narrationPlaying = playing;
    if (!state.on) return;
    if (playing) {
      _applyNarration();
    } else {
      if (ref.read(soundscapeDefaultsProvider).lowerUnderNarration) {
        _mixer.duck(false);
      } else {
        _mixer.resume();
      }
      // skin_audio puts the session back to idle when narration ends: take it back for the scene.
      Future<void>(() => _session.request(AudioSessionState.soundscape));
      _publish();
    }
  }

  void _applyNarration() {
    if (ref.read(soundscapeDefaultsProvider).lowerUnderNarration) {
      _mixer.duck(true);
    } else {
      _mixer.pause();
    }
    _publish();
  }

  void _onSleep() {
    final fading = _sleep?.value.fading ?? false;
    if (fading && state.on) {
      // Follow the sleep timer's 8 s fade and stop with it.
      _run++;
      state = state.copyWith(state: SoundscapeState.off, clearScene: true, builtin: false);
      unawaited(_mixer.stop(fade: const Duration(seconds: 8)));
      _idleSession(after: const Duration(seconds: 9));
    }
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    final s = lifecycle;
    if (!state.on && state.state != SoundscapeState.paused) return;
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      _backgrounded = true;
      // With narration playing the scene keeps going, ducked (glass 6 "In the background").
      if (!_narrationPlaying) {
        _mixer.pause();
        state = state.copyWith(state: SoundscapeState.paused);
      }
    } else if (s == AppLifecycleState.resumed && _backgrounded) {
      _backgrounded = false;
      if (_reader != null && !_interrupted && _mixer.playing) {
        _mixer.resume();
        _publish();
      }
    }
  }

  void _onInterruption(bool begin) {
    if (!state.on) return;
    if (begin) {
      _interrupted = true;
      _mixer.pause();
      state = state.copyWith(state: SoundscapeState.paused);
      _idleSession();
    } else if (_interrupted) {
      _interrupted = false;
      // Nothing resumes on its own: a toast offers it.
      ref.read(glassToastProvider.notifier).show(GlassToastSpec('Soundscape paused', actionLabel: 'Resume', onAction: () {
        unawaited(_session.request(AudioSessionState.soundscape));
        _mixer.resume();
        _publish();
      },),);
    }
  }

  void _idleSession({Duration after = Duration.zero}) {
    _sessionIdle?.cancel();
    void idle() {
      if (!state.on && !_narrationPlaying && _session.state == AudioSessionState.soundscape) unawaited(_session.request(AudioSessionState.idle));
    }

    after == Duration.zero ? idle() : _sessionIdle = Timer(after, idle);
  }

  // ── The level bars ──────────────────────────────────────────────────────────────────────────

  /// The sheet asks for the bars at 30 fps while it is open; nobody asking, no timer.
  void watchLevels(bool on) {
    _levelClients = (_levelClients + (on ? 1 : -1)).clamp(0, 99);
    if (_levelClients > 0 && _levelTimer == null) {
      _levelTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
        if (state.on) levels.value = _mixer.levels();
      });
    } else if (_levelClients == 0) {
      _levelTimer?.cancel();
      _levelTimer = null;
    }
  }
}

final soundscapeControllerProvider = NotifierProvider<SoundscapeController, SoundscapeView>(SoundscapeController.new, name: 'glassSoundscape');
