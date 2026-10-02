import 'dart:async';

import 'package:manhwamaniacs/features/novels/services/narration_player.dart';

/// A [NarrationPlayer] with no platform channel: it records every call and lets a test push
/// position and state events.
class FakeNarrationPlayer implements NarrationPlayer {
  final _position = StreamController<Duration>.broadcast();
  final _buffered = StreamController<Duration>.broadcast();
  final _state = StreamController<({bool playing, NarrationProcessing processing})>.broadcast();

  final List<String> calls = [];
  final List<Duration> seeks = [];
  final List<double> speeds = [];
  final List<double> volumes = [];
  String? url;
  Map<String, String>? headers;
  String? file;
  bool disposed = false;
  bool failLoad = false;

  Duration _pos = Duration.zero;
  bool _playing = false;
  NarrationProcessing _processing = NarrationProcessing.idle;

  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Stream<Duration> get bufferedStream => _buffered.stream;
  @override
  Stream<({bool playing, NarrationProcessing processing})> get stateStream => _state.stream;
  @override
  Duration get position => _pos;
  @override
  bool get playing => _playing;
  @override
  NarrationProcessing get processing => _processing;
  @override
  Duration? get duration => null;

  @override
  Future<void> setUrl(String url, Map<String, String> headers) async {
    calls.add('setUrl');
    if (failLoad) throw StateError('load failed');
    this.url = url;
    this.headers = headers;
    _processing = NarrationProcessing.ready;
  }

  @override
  Future<void> setFilePath(String path) async {
    calls.add('setFilePath');
    if (failLoad) throw StateError('load failed');
    file = path;
    _processing = NarrationProcessing.ready;
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _playing = true;
    _state.add((playing: true, processing: _processing));
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _playing = false;
    _state.add((playing: false, processing: _processing));
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek');
    seeks.add(position);
    _pos = position;
    _position.add(position);
    // Like just_audio: a seek takes a finished player out of `completed`.
    if (_processing == NarrationProcessing.completed) setProcessing(NarrationProcessing.ready);
  }

  @override
  Future<void> setSpeed(double speed) async {
    calls.add('setSpeed');
    speeds.add(speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    disposed = true;
  }

  // ── Test drivers ─────────────────────────────────────────────────────────

  void tick(int ms) {
    _pos = Duration(milliseconds: ms);
    _position.add(_pos);
  }

  void buffer(int ms) => _buffered.add(Duration(milliseconds: ms));

  void finish() {
    _processing = NarrationProcessing.completed;
    _playing = false;
    _state.add((playing: false, processing: NarrationProcessing.completed));
  }

  void setProcessing(NarrationProcessing p) {
    _processing = p;
    _state.add((playing: _playing, processing: p));
  }
}
