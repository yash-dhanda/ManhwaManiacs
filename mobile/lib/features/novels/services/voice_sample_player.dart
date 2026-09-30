import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/voice_pulse.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

/// What `SoLoud` does for a voice sample, behind a seam so the player is testable without the
/// native engine.
abstract interface class SampleEngine {
  Future<void> init();

  /// Loads [bytes] under [name] and starts them; answers a handle.
  Future<Object> play(String name, Uint8List bytes);

  /// Latest 256 wave samples, -1..1, of what is playing.
  List<double> waveform();

  /// Seconds played and the length in seconds, or null when unknown.
  ({double position, double length})? progress(Object handle);

  bool isPlaying(Object handle);
  Future<void> stop(Object handle);
}

class _Playing {
  _Playing(this.handle, this.source);
  final SoundHandle handle;
  final AudioSource source;
}

class SoLoudSampleEngine implements SampleEngine {
  SoLoudSampleEngine();

  AudioData? _data;

  @override
  Future<void> init() async {
    if (!SoLoud.instance.isInitialized) await SoLoud.instance.init();
    SoLoud.instance.setVisualizationEnabled(true);
  }

  @override
  Future<Object> play(String name, Uint8List bytes) async {
    final source = await SoLoud.instance.loadMem(name, bytes);
    final handle = SoLoud.instance.play(source);
    _data ??= AudioData(GetSamplesKind.wave);
    return _Playing(handle, source);
  }

  @override
  List<double> waveform() {
    final data = _data;
    if (data == null) return const [];
    try {
      data.updateSamples();
      final wave = data.getAudioData();
      return [for (var i = 0; i < 256 && i < wave.length; i++) wave[i]];
    } catch (_) {
      return const [];
    }
  }

  @override
  ({double position, double length})? progress(Object handle) {
    final p = handle as _Playing;
    try {
      return (
        position: SoLoud.instance.getPosition(p.handle).inMilliseconds / 1000,
        length: SoLoud.instance.getLength(p.source).inMilliseconds / 1000,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool isPlaying(Object handle) {
    try {
      return SoLoud.instance.getIsValidVoiceHandle((handle as _Playing).handle);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop(Object handle) async {
    final p = handle as _Playing;
    try {
      await SoLoud.instance.stop(p.handle);
      // The source is disposed after it stops.
      await SoLoud.instance.disposeSource(p.source);
    } catch (e, st) {
      appLogger.w('Voice sample stop failed', e, st);
    }
  }
}

/// The states a row's `Hear` button goes through.
enum SampleStatus { idle, fetching, playing }

class SampleState {
  const SampleState({this.voiceId, this.status = SampleStatus.idle, this.progress = 0, this.failed = false});

  final String? voiceId;
  final SampleStatus status;

  /// 0-1 along the clip, for the row's 2 px rule.
  final double progress;

  /// The last fetch or playback failed.
  final bool failed;

  bool isPlaying(String id) => voiceId == id && status == SampleStatus.playing;
  bool isFetching(String id) => voiceId == id && status == SampleStatus.fetching;
}

/// Plays a voice's sample clip (cinematic 8.16.5): the bytes come through the authenticated client
/// (`GET /novels/voices/sample?format=ogg`, Ogg on iOS too: SoLoud decodes it itself), play through
/// `SoLoud.instance.loadMem`, and an RMS of the wave drives the row's pulse. One sample at a time;
/// it pauses narration and resumes it after; the audio session enters the Voice-sample state and
/// returns to the previous one; the last 8 clips stay in memory.
class VoiceSamplePlayer extends Notifier<SampleState> {
  static const int cacheSize = 8;

  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  Object? _handle;
  Ticker? _ticker;
  Duration _last = Duration.zero;
  Future<void> Function()? _resume;
  int _token = 0;
  final VoicePulse _pulse = VoicePulse();
  late SampleEngine _engine;
  late ({Future<void> Function() begin, Future<void> Function() end}) _session;

  /// The smoothed loudness 0-1: listen to it, never `setState` per frame from a provider.
  final ValueNotifier<double> pulse = ValueNotifier<double>(0);

  @override
  SampleState build() {
    // Held here: `ref` cannot be read while the container is being torn down.
    _engine = ref.read(sampleEngineProvider);
    _session = ref.read(voiceSampleSessionProvider);
    ref.onDispose(() {
      unawaited(stop());
      _ticker?.dispose();
      pulse.dispose();
    });
    return const SampleState();
  }

  /// The bytes held for [voiceId] this session (null when not among the last 8).
  Uint8List? cached(String voiceId) => _cache[voiceId];

  Future<void> toggle(String voiceId) => state.voiceId == voiceId && state.status != SampleStatus.idle ? stop() : play(voiceId);

  Future<void> play(String voiceId) async {
    await stop();
    final token = ++_token;
    state = SampleState(voiceId: voiceId, status: SampleStatus.fetching);
    Uint8List? bytes = _cache.remove(voiceId);
    if (bytes == null) {
      final r = await ref.read(novelsRepositoryProvider).voiceSample(voiceId);
      if (token != _token) return;
      if (r.isErr || r.value.isEmpty) {
        state = SampleState(voiceId: voiceId, failed: true);
        return;
      }
      bytes = Uint8List.fromList(r.value);
    }
    _cache[voiceId] = bytes;
    while (_cache.length > cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    final engine = _engine;
    try {
      _resume = await ref.read(narrationControllerProvider.notifier).pauseForSample();
      await _session.begin();
      await engine.init();
      if (token != _token) {
        await _finish();
        return;
      }
      _handle = await engine.play('voice-sample-$voiceId.ogg', bytes);
    } catch (e, st) {
      appLogger.w('Voice sample failed to play', e, st);
      await _finish();
      if (token == _token) state = SampleState(voiceId: voiceId, failed: true);
      return;
    }
    state = SampleState(voiceId: voiceId, status: SampleStatus.playing);
    _last = Duration.zero;
    _pulse.reset();
    _ticker ??= Ticker(_onTick);
    if (!_ticker!.isActive) unawaited(_ticker!.start());
  }

  void _onTick(Duration elapsed) {
    final handle = _handle;
    if (handle == null) return;
    final engine = _engine;
    if (!engine.isPlaying(handle)) {
      unawaited(stop());
      return;
    }
    final dt = elapsed - _last;
    _last = elapsed;
    pulse.value = _pulse.step(rms(engine.waveform()), dt);
    final p = engine.progress(handle);
    if (p != null && p.length > 0) {
      final next = (p.position / p.length).clamp(0.0, 1.0);
      if ((next - state.progress).abs() > 0.004) {
        state = SampleState(voiceId: state.voiceId, status: SampleStatus.playing, progress: next);
      }
    }
  }

  /// Stops the sample, disposes its source, resumes narration and restores the audio session.
  Future<void> stop() async {
    _token++;
    _ticker?.stop();
    final handle = _handle;
    _handle = null;
    if (handle != null) await _engine.stop(handle);
    await _finish();
    pulse.value = 0;
    if (state.status != SampleStatus.idle) state = SampleState(voiceId: state.voiceId);
  }

  Future<void> _finish() async {
    final resume = _resume;
    _resume = null;
    if (resume == null) return;
    await _session.end();
    await resume();
  }
}

/// The audio-session half of a sample: `.playback` + `.duckOthers` (Android transient may duck)
/// while it plays, the previous state after. Replaceable in tests.
final voiceSampleSessionProvider = Provider<({Future<void> Function() begin, Future<void> Function() end})>(
  (ref) => (begin: SkinAudio.instance.beginVoiceSample, end: SkinAudio.instance.endVoiceSample),
  name: 'voiceSampleSession',
);

final sampleEngineProvider = Provider<SampleEngine>((ref) => SoLoudSampleEngine(), name: 'sampleEngine');

final voiceSamplePlayerProvider = NotifierProvider<VoiceSamplePlayer, SampleState>(VoiceSamplePlayer.new, name: 'voiceSamplePlayer');
