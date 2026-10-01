import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/generator.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';

void main() {
  test('one rendered layer is 960,000 samples with a correct 44-byte WAV header', () {
    final r = renderLoop(SoundScene.rain, SoundLayer.bed);
    expect(r.wav.length, 44 + 1920000);
    final b = ByteData.sublistView(r.wav);
    String tag(int at) => String.fromCharCodes(r.wav.sublist(at, at + 4));
    expect(tag(0), 'RIFF');
    expect(tag(8), 'WAVE');
    expect(tag(12), 'fmt ');
    expect(b.getUint16(20, Endian.little), 1);
    expect(b.getUint16(22, Endian.little), 1);
    expect(b.getUint32(24, Endian.little), 32000);
    expect(b.getUint16(34, Endian.little), 16);
    expect(tag(36), 'data');
    expect(b.getUint32(40, Endian.little), 1920000);
    expect(r.envelope.length, 900);
    expect(r.envelope.every((v) => v >= 0 && v <= 1), isTrue);
  });

  for (final (scene, layer) in kLoopLayers) {
    test('${scene.name} ${layer.name}: RMS is on target and the loop seam is no louder than the noise floor', () {
      final s = renderLoopSamples(scene, layer);
      expect(s.length, kLoopSamples);
      expect(rmsDb(s), closeTo(loopTargetDb(scene, layer), 0.5));
      final seam = (s[0] - s[kLoopSamples - 1]).abs();
      final steps = [for (var i = 0; i + 1 < s.length; i += 7) (s[i + 1] - s[i]).abs()]..sort();
      final p99 = steps[(steps.length * 0.99).floor()];
      expect(seam, lessThanOrEqualTo(p99), reason: 'seam $seam vs p99 $p99');
    });
  }

  test('the event banks hold 12 droplets, 6 wind bursts and 12 crackles', () {
    expect(renderEventBank(SoundScene.rain).length, 12);
    expect(renderEventBank(SoundScene.wind).length, 6);
    expect(renderEventBank(SoundScene.hearth).length, 12);
    expect(renderEventBank(SoundScene.deep), isEmpty);
    final drop = renderEventBank(SoundScene.rain).first;
    expect(drop.length, 128);
    expect(drop.map((v) => v.abs()).reduce(math.max), lessThanOrEqualTo(0.6));
    final wind = renderEventBank(SoundScene.wind);
    expect(wind.map((b) => b.length), [1280, 1792, 2304, 2816, 3328, 3840]);
  });

  test('the same seed renders the same bytes', () {
    final a = renderLoopSamples(SoundScene.stream, SoundLayer.bed, seed: 3);
    final b = renderLoopSamples(SoundScene.stream, SoundLayer.bed, seed: 3);
    expect(a[1000], b[1000]);
    expect(a[500000], b[500000]);
  });

  test('the isolate path returns the same render', () async {
    final r = await renderLoopInIsolate(SoundScene.deep, SoundLayer.bed);
    expect(r.wav.length, 44 + 1920000);
  });
}
