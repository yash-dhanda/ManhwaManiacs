import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeConfigurator implements SessionConfigurator {
  final configs = <AudioSessionConfiguration>[];
  final active = <bool>[];
  @override
  Future<void> configure(AudioSessionConfiguration c) async => configs.add(c);
  @override
  Future<void> setActive(bool a) async => active.add(a);
}

class FakeEngine implements CueEngine {
  int inits = 0;
  final events = <String>[]; // 'init' | 'configured?' markers
  final played = <(String, double)>[];
  final rates = <double>[];
  final Future<void> Function()? onInit;
  FakeEngine({this.onInit});
  @override
  Future<void> init() async {
    inits++;
    events.add('init');
    await onInit?.call();
  }

  @override
  Future<dynamic> loadAsset(String path) async => path;
  @override
  Future<dynamic> play(dynamic source, {required double volume}) async {
    played.add((source as String, volume));
    return 1;
  }

  @override
  void setRelativePlaySpeed(dynamic handle, double rate) => rates.add(rate);
}

Future<(SkinAudio, FakeConfigurator, FakeEngine)> make(SkinId skin,
    {int profile = 1, Map<String, Object> seed = const {}}) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final c = FakeConfigurator();
  final e = FakeEngine();
  final a = SkinAudio.forTest(c, e)
    ..bind(skin: skin, userId: 7, profileId: profile, prefs: prefs);
  return (a, c, e);
}

void main() {
  test('start configures idle (ambient, mix with others)', () async {
    final (a, c, _) = await make(SkinId.cinematic);
    await a.start();
    expect(c.configs.single.avAudioSessionCategory, AVAudioSessionCategory.ambient);
    expect(c.configs.single.avAudioSessionCategoryOptions, AVAudioSessionCategoryOptions.mixWithOthers);
  });

  test('sounds off: engine never initialised', () async {
    final (a, _, e) = await make(SkinId.cinematic);
    await a.start();
    await a.play(SoundEvent.tapPrimary);
    expect(e.inits, 0);
    expect(a.readSoundPrefs(SkinId.cinematic).on, isFalse);
    expect(a.readSoundPrefs(SkinId.cinematic).level, 60);
    expect(a.readSoundPrefs(SkinId.glass).level, -6);
  });

  test('enabling inits once and re-applies the session right after', () async {
    final (a, c, e) = await make(SkinId.cinematic);
    await a.start();
    expect(c.configs.length, 1);
    await a.writeSoundPrefs(SkinId.cinematic, const SoundPrefs(on: true, level: 60));
    await a.writeSoundPrefs(SkinId.cinematic, const SoundPrefs(on: true, level: 40));
    expect(e.inits, 1);
    expect(c.configs.length, 2);
    expect(c.configs.last.avAudioSessionCategory, AVAudioSessionCategory.ambient);
  });

  test('cinematic tap.primary plays set at 0.6', () async {
    final (a, _, e) = await make(SkinId.cinematic);
    await a.writeSoundPrefs(SkinId.cinematic, const SoundPrefs(on: true, level: 60));
    await a.play(SoundEvent.tapPrimary);
    expect(e.played.single.$1, 'assets/sounds/cinematic/set.wav');
    expect(e.played.single.$2, closeTo(0.6, 1e-9));
  });

  test('glass nav.push depth 3 plays push-3 at -6 dB, with rate', () async {
    final (a, _, e) = await make(SkinId.glass);
    await a.writeSoundPrefs(SkinId.glass, const SoundPrefs(on: true, level: -6));
    await a.play(SoundEvent.navPush, depth: 3, rate: 1.2);
    expect(e.played.single.$1, 'assets/sounds/glass/push-3.wav');
    expect(e.played.single.$2, closeTo(0.501, 0.001));
    expect(e.rates, [1.2]);
  });

  test('suppressed in narration, soundscape and with a cinematic soundscape', () async {
    final (a, _, e) = await make(SkinId.cinematic);
    await a.writeSoundPrefs(SkinId.cinematic, const SoundPrefs(on: true, level: 60));
    await a.request(AudioSessionState.narration);
    await a.play(SoundEvent.tapPrimary);
    await a.request(AudioSessionState.soundscape);
    await a.play(SoundEvent.tapPrimary);
    await a.request(AudioSessionState.idle);
    a.setSoundscapeActive(true);
    await a.play(SoundEvent.tapPrimary);
    expect(e.played, isEmpty);
    a.setSoundscapeActive(false);
    await a.play(SoundEvent.tapPrimary);
    expect(e.played.length, 1);
  });

  test('preferences: cinematic per profile, glass per device', () async {
    final (a, _, _) = await make(SkinId.cinematic, profile: 1);
    await a.writeSoundPrefs(SkinId.cinematic, const SoundPrefs(on: true, level: 30));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), contains('mm.sounds.u7p1'));
    a.bind(skin: SkinId.cinematic, userId: 7, profileId: 2, prefs: prefs);
    expect(a.readSoundPrefs(SkinId.cinematic).on, isFalse);
    a.bind(skin: SkinId.cinematic, userId: 7, profileId: 1, prefs: prefs);
    expect(a.readSoundPrefs(SkinId.cinematic).level, 30);
    await a.writeSoundPrefs(SkinId.glass, const SoundPrefs(on: true, level: -12));
    expect(prefs.getKeys(), contains('mm.sounds.glass'));
    a.bind(skin: SkinId.glass, userId: 8, profileId: 9, prefs: prefs);
    expect(a.readSoundPrefs(SkinId.glass).level, -12);
  });

  test('voice sample returns to the previous state', () async {
    final (a, c, _) = await make(SkinId.cinematic);
    await a.request(AudioSessionState.narration);
    await a.beginVoiceSample();
    expect(a.state, AudioSessionState.voiceSample);
    expect(c.active, [true]);
    await a.endVoiceSample();
    expect(a.state, AudioSessionState.narration);
    expect(c.active, [true, false]);
  });
}
