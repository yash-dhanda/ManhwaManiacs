import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Where the platform player is, in the terms the narration controller cares about.
enum NarrationProcessing { idle, loading, buffering, ready, completed }

/// The one `just_audio` player of the app, behind a seam so the controller is testable with a
/// fake and the `audio_service` handler wraps the SAME instance's state.
abstract class NarrationPlayer {
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedStream;

  /// Emits `(playing, processing)` on every change.
  Stream<({bool playing, NarrationProcessing processing})> get stateStream;

  Duration get position;
  bool get playing;
  NarrationProcessing get processing;
  Duration? get duration;

  Future<void> setUrl(String url, Map<String, String> headers);
  Future<void> setFilePath(String path);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Pitch stays 1.0; only the speed moves.
  Future<void> setSpeed(double speed);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioNarrationPlayer implements NarrationPlayer {
  JustAudioNarrationPlayer([AudioPlayer? player]) : _p = player ?? AudioPlayer();

  final AudioPlayer _p;

  static NarrationProcessing _map(ProcessingState s) => switch (s) {
        ProcessingState.idle => NarrationProcessing.idle,
        ProcessingState.loading => NarrationProcessing.loading,
        ProcessingState.buffering => NarrationProcessing.buffering,
        ProcessingState.ready => NarrationProcessing.ready,
        ProcessingState.completed => NarrationProcessing.completed,
      };

  @override
  Stream<Duration> get positionStream => _p.positionStream;

  @override
  Stream<Duration> get bufferedStream => _p.bufferedPositionStream;

  @override
  Stream<({bool playing, NarrationProcessing processing})> get stateStream =>
      _p.playerStateStream.map((s) => (playing: s.playing, processing: _map(s.processingState)));

  @override
  Duration get position => _p.position;

  @override
  bool get playing => _p.playing;

  @override
  NarrationProcessing get processing => _map(_p.processingState);

  @override
  Duration? get duration => _p.duration;

  @override
  Future<void> setUrl(String url, Map<String, String> headers) async {
    await _p.setUrl(url, headers: headers);
  }

  @override
  Future<void> setFilePath(String path) async {
    await _p.setFilePath(path);
  }

  @override
  Future<void> play() => _p.play();

  @override
  Future<void> pause() => _p.pause();

  @override
  Future<void> seek(Duration position) => _p.seek(position);

  @override
  Future<void> setSpeed(double speed) async {
    await _p.setSpeed(speed);
    await _p.setPitch(1.0);
  }

  @override
  Future<void> setVolume(double volume) => _p.setVolume(volume);

  @override
  Future<void> stop() => _p.stop();

  @override
  Future<void> dispose() => _p.dispose();
}

/// A fresh platform player per chapter session: replaced in tests with a fake.
final narrationPlayerFactoryProvider = Provider<NarrationPlayer Function()>(
  (ref) => JustAudioNarrationPlayer.new,
  name: 'narrationPlayerFactory',
);
