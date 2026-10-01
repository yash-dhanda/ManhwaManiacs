import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/services/narration_level.dart';

NovelAudioSegment seg(int a, int b, {bool speech = true}) =>
    NovelAudioSegment(index: 0, startMs: a, endMs: b, paragraph: 0, start: 0, end: 1, isSpeech: speech);

void main() {
  test('sample count is ceil(total_ms / 1000 x 30)', () {
    expect(NarrationLevel.sampleCount(1000), 30);
    expect(NarrationLevel.sampleCount(1001), 31);
    expect(NarrationLevel.sampleCount(0), 0);
  });

  test('levelAt reads the envelope at 30 per second and 0 outside it', () {
    final l = NarrationLevel.fromSamples(Float32List.fromList([0.1, -0.5, 0.25]));
    expect(l.envelope, [closeTo(0.2, 1e-6), 1.0, closeTo(0.5, 1e-6)]);
    expect(l.levelAt(Duration.zero), closeTo(0.2, 1e-6));
    expect(l.levelAt(const Duration(milliseconds: 34)), 1.0);
    expect(l.levelAt(const Duration(milliseconds: 70)), closeTo(0.5, 1e-6));
    expect(l.levelAt(const Duration(seconds: 5)), 0);
    expect(l.levelAt(const Duration(milliseconds: -5)), 0);
  });

  test('segment fallback is 1 inside speech segments and 0 in the gaps', () {
    final l = NarrationLevel.fromSegments([seg(0, 500), seg(500, 900, speech: false), seg(900, 1000)], 1000);
    expect(l.envelope.length, 30);
    expect(l.levelAt(const Duration(milliseconds: 100)), 1);
    expect(l.levelAt(const Duration(milliseconds: 600)), 0);
    expect(l.levelAt(const Duration(milliseconds: 950)), 1);
  });

  test('silence stays zero instead of dividing by a zero peak', () {
    expect(NarrationLevel.fromSamples(Float32List(4)).envelope, [0, 0, 0, 0]);
  });
}
