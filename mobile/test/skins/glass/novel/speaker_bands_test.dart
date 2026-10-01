import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/speaker_bands.dart';

NovelAttribution _attr(List<String> paragraphs, int speakers, {bool stale = false}) => NovelAttribution.fromJson({
      'attributed': true,
      'text_fingerprint': stale ? 'deadbeef' : chapterFingerprint(paragraphs),
      'spans': [
        for (var i = 0; i < speakers; i++) {'p': i, 's': 0, 'e': 4, 'head': '', 'speaker': 'S$i'},
      ],
      'cast': [
        for (var i = 0; i < speakers; i++) {'name': 'S$i', 'lines': speakers - i},
      ],
    });

void main() {
  test('slot n maps to spk n', () {
    const hues = [0xFF7CC4FF, 0xFFFFB27A, 0xFF9BE58A, 0xFFD7A4FF, 0xFFFF8FA3, 0xFF6FE3D4, 0xFFFFD86B, 0xFFA7B4FF, 0xFFF59BD6, 0xFFC8D98A];
    for (var n = 1; n <= 10; n++) {
      expect(speakerHue(n), Color(hues[n - 1]), reason: 'spk$n');
    }
    expect(speakerHue(11), speakerHue(1));
  });

  test('the 11th speaker repeats slot 1, dashed', () {
    final paragraphs = [for (var i = 0; i < 11; i++) 'Line $i of the chapter'];
    final runs = speakerRuns(_attr(paragraphs, 11), paragraphs);
    expect(runs[10]!.single.slot, 1);
    expect(runs[10]!.single.dotted, isTrue);
    expect(runs[0]!.single.dotted, isFalse);
  });

  test('a stale fingerprint gives no bands', () {
    final paragraphs = ['Line 0 of the chapter'];
    expect(speakerRuns(_attr(paragraphs, 1, stale: true), paragraphs), isEmpty);
  });

  test('the alphas and widths are the contract values', () {
    expect(kSpeakerBandAlpha, 0.14);
    expect(kSpeakerLineAlpha, 0.60);
    expect(kSpeakerLineWidth, 1.5);
    expect(kSpeakerLineDropEm, 0.18);
  });
}
