import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/services/soundscape_files.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/house_sound.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

class _Files extends SoundscapeFiles {
  _Files(this.dir) : super(Dio());
  final Directory dir;
  final requested = <String>[];
  @override
  Future<File> soundscapeFile(String id) async {
    requested.add(id);
    return File('${dir.path}/$id.ogg')..writeAsBytesSync([1]);
  }
}

class _Player implements LoopPlayer {
  _Player({this.looping = false});

  /// just_audio on a looping file: `play()` completes only when playback stops.
  final bool looping;
  final volumes = <double>[];
  final log = <String>[];
  @override
  Future<void> load(File f) async => log.add('load ${f.uri.pathSegments.last}');
  @override
  Future<void> play() {
    log.add('play');
    return looping ? Completer<void>().future : Future<void>.value();
  }
  @override
  Future<void> pause() async => log.add('pause');
  @override
  Future<void> setVolume(double v) async => volumes.add(v);
  @override
  Future<void> dispose() async => log.add('dispose');
}

class _Cfg implements SessionConfigurator {
  final actives = <bool>[];
  @override
  Future<void> configure(config) async {}
  @override
  Future<void> setActive(bool a) async => actives.add(a);
}

class _NoCues implements CueEngine {
  @override
  Future<void> init() async {}
  @override
  Future<dynamic> loadAsset(String p) async => 1;
  @override
  Future<dynamic> play(dynamic s, {required double volume}) async => 1;
  @override
  void setRelativePlaySpeed(dynamic h, double r) {}
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('hs'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('fades in over 2 s, out over 600 ms, ducks to 30 %, silences cues while playing', () {
    fakeAsync((async) {
      final player = _Player();
      final audio = SkinAudio.forTest(_Cfg(), _NoCues());
      final h = HouseSound(files: _Files(tmp), playerFactory: () => player, audio: audio);
      h.setVolume(1.0);
      h.setLoop('rain-on-glass');
      async.elapse(const Duration(milliseconds: 100));
      expect(h.playing, isTrue);
      expect(player.log, contains('play'));
      expect(audio.cuesSuppressed, isTrue);
      async.elapse(const Duration(milliseconds: 950));
      expect(player.volumes.last, closeTo(0.5, 0.05));
      async.elapse(const Duration(milliseconds: 1200));
      expect(player.volumes.last, closeTo(1.0, 0.001));
      h.duck(true);
      async.elapse(const Duration(milliseconds: 400));
      expect(player.volumes.last, closeTo(0.30, 0.001));
      h.duck(false);
      async.elapse(const Duration(milliseconds: 400));
      expect(player.volumes.last, closeTo(1.0, 0.001));
      h.fadeOutForExit();
      async.elapse(const Duration(milliseconds: 300));
      expect(player.volumes.last, closeTo(0.5, 0.06));
      async.elapse(const Duration(milliseconds: 400));
      expect(player.volumes.last, closeTo(0.0, 0.001));
      expect(player.log.last, 'pause');
      h.resume();
      async.elapse(const Duration(milliseconds: 2100));
      expect(player.volumes.last, closeTo(1.0, 0.001));
      h.setLoop(null);
      async.elapse(const Duration(seconds: 1));
      expect(h.loopId, isNull);
      expect(audio.cuesSuppressed, isFalse);
    });
  });

  test('Hear enters the voice-sample state, plays 5 s and resumes the running loop', () {
    fakeAsync((async) {
      final players = <_Player>[];
      final cfg = _Cfg();
      final audio = SkinAudio.forTest(cfg, _NoCues());
      final h = HouseSound(files: _Files(tmp), playerFactory: () => _Player()..let(players.add), audio: audio);
      h.setLoop('cafe');
      async.elapse(const Duration(seconds: 3));
      h.hear('temple-bells');
      async.elapse(const Duration(milliseconds: 800));
      expect(audio.state, AudioSessionState.voiceSample);
      expect(h.previewing, isTrue);
      async.elapse(const Duration(seconds: 6));
      expect(h.previewing, isFalse);
      expect(audio.state, isNot(AudioSessionState.voiceSample));
      async.elapse(const Duration(seconds: 3));
      expect(h.playing, isTrue);
      expect(players.length, 2);
      expect(players[1].log, containsAll(['load temple-bells.ogg', 'play', 'dispose']));
      // The house-sound player never activates the session itself.
      expect(cfg.actives.where((a) => a).length, 1);
    });
  });

  test('Hear ends and frees the button even though a looping play() never completes; a second Hear plays', () {
    fakeAsync((async) {
      final players = <_Player>[];
      final h = HouseSound(files: _Files(tmp), playerFactory: () => _Player(looping: true)..let(players.add), audio: SkinAudio.forTest(_Cfg(), _NoCues()));
      h.hear('rain');
      async.elapse(const Duration(seconds: 6));
      expect(h.previewing, isFalse, reason: 'the Hear button is enabled again');
      h.hear('cafe');
      async.elapse(const Duration(milliseconds: 500));
      expect(h.previewing, isTrue);
      async.elapse(const Duration(seconds: 6));
      expect(h.previewing, isFalse);
      expect(players.map((p) => p.log.contains('dispose')), [true, true]);
      h.setLoop('cafe');
      async.elapse(const Duration(seconds: 3));
      expect(h.playing, isTrue, reason: 'setLoop does not hang on play() either');
    });
  });
}

extension on _Player {
  void let(void Function(_Player) f) => f(this);
}
