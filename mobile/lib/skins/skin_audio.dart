import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/novel_audio_session.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart' as cin;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart' as gls;
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The iPhone audio-session category read back right after SoLoud init and after a Hear sample
/// (mobile/24 device pass): both must be `ambient` (cinematic 6, State A).
class AudioSessionProbe {
  const AudioSessionProbe({this.afterInit, this.afterHear, this.initAt, this.hearAt});
  final String? afterInit;
  final String? afterHear;
  final DateTime? initAt;
  final DateTime? hearAt;
}

/// Written by [SkinAudio]; shown in Settings, Diagnostics on the iPhone.
final ValueNotifier<AudioSessionProbe> audioSessionProbe = ValueNotifier(const AudioSessionProbe());

final audioSessionProbeProvider = Provider<ValueNotifier<AudioSessionProbe>>((ref) => audioSessionProbe);

Future<void> _probeCategory({required bool afterInit}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
  try {
    final c = (await AVAudioSession().category).name;
    final now = DateTime.now();
    final p = audioSessionProbe.value;
    audioSessionProbe.value = afterInit
        ? AudioSessionProbe(afterInit: c, afterHear: p.afterHear, initAt: now, hearAt: p.hearAt)
        : AudioSessionProbe(afterInit: p.afterInit, afterHear: c, initAt: p.initAt, hearAt: now);
    debugPrint('audio session ${afterInit ? 'after init' : 'after hear'}: $c');
  } catch (e) {
    debugPrint('audio session probe failed: $e');
  }
}

/// The process-wide audio session states (cinematic §6, glass §6).
enum AudioSessionState { idle, narration, voiceSample, soundscape }

AudioSessionConfiguration configurationFor(AudioSessionState s) => switch (s) {
      AudioSessionState.idle => const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        ),
      AudioSessionState.narration => novelAudioSessionConfiguration,
      AudioSessionState.voiceSample => const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        ),
      AudioSessionState.soundscape => const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        ),
    };

abstract interface class SessionConfigurator {
  Future<void> configure(AudioSessionConfiguration config);
  Future<void> setActive(bool active);
}

class PlatformSessionConfigurator implements SessionConfigurator {
  const PlatformSessionConfigurator();

  @override
  Future<void> configure(AudioSessionConfiguration config) async =>
      (await AudioSession.instance).configure(config);

  @override
  Future<void> setActive(bool active) async =>
      (await AudioSession.instance).setActive(active);
}

abstract interface class CueEngine {
  Future<void> init();
  Future<dynamic> loadAsset(String path);
  Future<dynamic> play(dynamic source, {required double volume});
  void setRelativePlaySpeed(dynamic handle, double rate);
}

class SoLoudCueEngine implements CueEngine {
  const SoLoudCueEngine();

  @override
  Future<void> init() => SoLoud.instance.init();

  @override
  Future<dynamic> loadAsset(String path) => SoLoud.instance.loadAsset(path);

  @override
  Future<dynamic> play(dynamic source, {required double volume}) async =>
      SoLoud.instance.play(source as AudioSource, volume: volume);

  @override
  void setRelativePlaySpeed(dynamic handle, double rate) =>
      SoLoud.instance.setRelativePlaySpeed(handle as SoundHandle, rate);
}

/// [level] is 0-100 % for Cinematic, dB (-24..0) for Glass.
class SoundPrefs {
  const SoundPrefs({required this.on, required this.level});
  final bool on;
  final double level;

  static const cinematicDefault = SoundPrefs(on: false, level: 60);
  static const glassDefault = SoundPrefs(on: false, level: -6);
}

class SkinAudio {
  SkinAudio._(this._configurator, this._engine, this._isResumed);

  static final SkinAudio instance = SkinAudio._(
    const PlatformSessionConfigurator(),
    const SoLoudCueEngine(),
    () {
      final s = WidgetsBinding.instance.lifecycleState;
      return s == null || s == AppLifecycleState.resumed;
    },
  );

  @visibleForTesting
  SkinAudio.forTest(
    SessionConfigurator configurator,
    CueEngine engine, {
    bool Function()? isResumed,
  }) : this._(configurator, engine, isResumed ?? () => true);

  final SessionConfigurator _configurator;
  final CueEngine _engine;
  final bool Function() _isResumed;

  AudioSessionState _state = AudioSessionState.idle;
  AudioSessionState _beforeVoiceSample = AudioSessionState.idle;
  bool _soundscape = false;
  bool _engineReady = false;
  Future<void>? _readying;

  SkinId _skin = kDefaultSkin;
  int? _userId;
  int? _profileId;
  SharedPreferences? _prefs;
  SkinId? _cuesFor;
  final Map<String, dynamic> _sources = {};

  AudioSessionState get state => _state;

  bool get cuesSuppressed =>
      _state == AudioSessionState.narration ||
      _state == AudioSessionState.soundscape ||
      _soundscape ||
      !_isResumed();

  /// Called once from main(), unawaited: configure State A.
  Future<void> start() => _apply(AudioSessionState.idle);

  Future<void> _apply(AudioSessionState s) async {
    _state = s;
    try {
      await _configurator.configure(configurationFor(s));
    } catch (e, st) {
      appLogger.w('Audio session configuration failed', e, st);
    }
  }

  Future<void> request(AudioSessionState s) => _apply(s);

  Future<void> beginVoiceSample() async {
    if (_state != AudioSessionState.voiceSample) _beforeVoiceSample = _state;
    await _apply(AudioSessionState.voiceSample);
    try {
      await _configurator.setActive(true);
    } catch (_) {}
  }

  Future<void> endVoiceSample() async {
    try {
      await _configurator.setActive(false);
    } catch (_) {}
    await _apply(_beforeVoiceSample);
    await _probeCategory(afterInit: false);
  }

  /// Cinematic's soundscape plays in State A, so it only suppresses cues.
  void setSoundscapeActive(bool active) => _soundscape = active;

  /// Sets the running skin and its preference scope; never reconfigures the
  /// session (a skin restart must not reset it).
  void bind({
    required SkinId skin,
    required int? userId,
    required int? profileId,
    required SharedPreferences prefs,
  }) {
    _skin = skin;
    _userId = userId;
    _profileId = profileId;
    _prefs = prefs;
    if (readSoundPrefs(skin).on) unawaited(_ensureReady());
  }

  String _key(SkinId skin) => skin == SkinId.glass
      ? 'mm.sounds.glass'
      : 'mm.sounds.u${_userId ?? 0}p${_profileId ?? 0}';

  SoundPrefs readSoundPrefs(SkinId skin) {
    final d = skin == SkinId.glass ? SoundPrefs.glassDefault : SoundPrefs.cinematicDefault;
    final raw = _prefs?.getString(_key(skin));
    if (raw == null) return d;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final l = (skin == SkinId.glass ? m['volumeDb'] : m['volume']) as num?;
      return SoundPrefs(on: m['on'] == true, level: l?.toDouble() ?? d.level);
    } catch (_) {
      return d;
    }
  }

  Future<void> writeSoundPrefs(SkinId skin, SoundPrefs p) async {
    final body = skin == SkinId.glass
        ? {'on': p.on, 'volumeDb': p.level}
        : {'on': p.on, 'volume': p.level};
    await _prefs?.setString(_key(skin), jsonEncode(body));
    if (p.on) await _ensureReady();
  }

  /// Linear gain for the engine.
  double gainFor(SkinId skin, SoundPrefs p) => skin == SkinId.glass
      ? math.pow(10, p.level.clamp(-24, 0) / 20).toDouble()
      : p.level.clamp(0, 100) / 100;

  Map<String, String> _cues(SkinId s) => switch (s) {
        SkinId.cinematic => cin.cinematicSoundCues,
        SkinId.glass => gls.glassSoundCues,
      };

  Map<SoundEvent, List<String>> _events(SkinId s) => switch (s) {
        SkinId.cinematic => cin.cinematicSoundEvents,
        SkinId.glass => gls.glassSoundEvents,
      };

  Future<void> _ensureReady() => _readying ??= _ready().whenComplete(() => _readying = null);

  Future<void> _ready() async {
    if (!_engineReady) {
      await _engine.init();
      _engineReady = true;
      // SoLoud's init sets no category; put State A (or the current state) back.
      await _apply(_state);
      await _probeCategory(afterInit: true);
    }
    if (_cuesFor != _skin) {
      _sources.clear();
      _cuesFor = _skin;
      for (final e in _cues(_skin).entries) {
        try {
          _sources[e.key] = await _engine.loadAsset(e.value);
        } catch (err, st) {
          appLogger.w('Cue ${e.value} failed to load', err, st);
        }
      }
    }
  }

  final Map<SkinId, Map<String, dynamic>> _previewCache = {};

  /// Feedback lab: play [event] from [skin]'s cue set at its default gain,
  /// regardless of the saved preference, suppression or the running skin.
  Future<void> preview(SkinId skin, SoundEvent event, {int depth = 1, double? level}) async {
    final names = _events(skin)[event];
    if (names == null || names.isEmpty) return;
    if (!_engineReady) {
      await _engine.init();
      _engineReady = true;
      await _apply(_state);
    }
    final cache = _previewCache.putIfAbsent(skin, () => {});
    final name = names[event == SoundEvent.navPush ? (depth - 1).clamp(0, names.length - 1) : 0];
    final path = _cues(skin)[name];
    if (path == null) return;
    final src = cache[name] ??= await _engine.loadAsset(path);
    final d = skin == SkinId.glass ? SoundPrefs.glassDefault : SoundPrefs.cinematicDefault;
    await _engine.play(src, volume: gainFor(skin, level == null ? d : SoundPrefs(on: true, level: level)));
  }

  Future<void> play(SoundEvent event, {int depth = 1, double rate = 1.0}) async {
    final prefs = readSoundPrefs(_skin);
    if (!prefs.on || cuesSuppressed || _cuesFor != _skin) return;
    final names = _events(_skin)[event];
    if (names == null || names.isEmpty) return;
    final idx = event == SoundEvent.navPush ? (depth - 1).clamp(0, names.length - 1) : 0;
    final src = _sources[names[idx]];
    if (src == null) return;
    final h = await _engine.play(src, volume: gainFor(_skin, prefs));
    if (rate != 1.0) _engine.setRelativePlaySpeed(h, rate);
  }
}

final skinAudioProvider = Provider<SkinAudio>((ref) {
  // Narration owns State B for exactly the span it is active (playing, or paused inside the
  // reader). When it ends without an explicit stop (a failure, a finished chapter with nothing
  // after it), State A comes back here, so cues are audible again and other apps can mix.
  ref.listen<bool>(narrationActiveProvider, (was, active) {
    if ((was ?? false) && !active && SkinAudio.instance.state == AudioSessionState.narration) {
      unawaited(SkinAudio.instance.request(AudioSessionState.idle));
    }
  });
  return SkinAudio.instance
    ..bind(
      skin: ref.watch(skinIdProvider),
      userId: ref.watch(authControllerProvider.select((a) => a is AuthAuthenticated ? a.user.id : null)),
      profileId: ref.watch(activeProfileProvider.select((p) => p?.id)),
      prefs: ref.watch(sharedPrefsProvider),
    );
});
