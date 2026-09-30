import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';

NovelAudioSegment seg(int i, int a, int b, int p, int s, int e, {bool speech = false, String? speaker, String? voice}) =>
    NovelAudioSegment(index: i, startMs: a, endMs: b, paragraph: p, start: s, end: e, isSpeech: speech, speaker: speaker, voice: voice);

void main() {
  const paras = ['The quick brown fox jumps. Then it sleeps.'];
  // "The quick brown fox jumps." = 0..26
  final first = seg(0, 0, 1000, 0, 0, 26);

  test('spoken word tracks the playhead through the sentence', () {
    expect(spokenWord(first, paras, 0), (paragraph: 0, start: 0, end: 3));
    // 0.3 * 26 = 7 -> "quick"
    expect(spokenWord(first, paras, 300), (paragraph: 0, start: 4, end: 9));
    // 0.99 * 26 = 25 -> "jumps." is clipped to the sentence
    expect(spokenWord(first, paras, 990), (paragraph: 0, start: 20, end: 26));
  });

  test('positions outside the sentence clamp to its first or last word', () {
    expect(spokenWord(first, paras, -50)!.start, 0);
    expect(spokenWord(first, paras, 5000)!.end, 26);
  });

  test('whitespace hits move to the neighbouring word', () {
    // offset 3 is the space after "The": the next word wins
    final w = spokenWord(first, paras, 120)!; // 0.12*26 = 3
    expect((w.start, w.end), (4, 9));
  });

  test('a segment that does not fit the text answers null', () {
    expect(spokenWord(seg(0, 0, 10, 0, 0, 999), paras, 5), isNull);
    expect(spokenWord(seg(0, 0, 10, 4, 0, 3), paras, 5), isNull);
  });

  test('sentenceRuns carries speaker only for speech and skips misfits', () {
    final runs = sentenceRuns(paras, [
      first,
      seg(1, 1000, 2000, 0, 27, 41, speech: true, speaker: 'Iris', voice: 'v1'),
      seg(2, 2000, 3000, 9, 0, 3),
    ]);
    expect(runs.length, 2);
    expect(runs[0].speaker, isNull);
    expect(runs[0].text, 'The quick brown fox jumps.');
    expect(runs[1].speaker, 'Iris');
    expect(runs[1].voice, 'v1');
  });

  test('narrationWpm scales with speed', () {
    expect(narrationWpm(182, 60000, 1), 182);
    expect(narrationWpm(182, 60000, 2), 364);
    expect(narrationWpm(0, 60000, 1), 0);
  });

  group('followDecision', () {
    test('inside 20-70 percent does nothing', () {
      expect(followDecision(200, 1000).kind, FollowKind.none);
      expect(followDecision(700, 1000).kind, FollowKind.none);
    });
    test('outside scrolls to 38 percent', () {
      final d = followDecision(900, 1000);
      expect(d.kind, FollowKind.scroll);
      expect(d.delta, closeTo(520, 1e-9));
      expect(followDecision(50, 1000).delta, closeTo(-330, 1e-9));
    });
    test('more than two viewports away jumps', () {
      expect(followDecision(2600, 1000).kind, FollowKind.jump);
      expect(followDecision(-2100, 1000).kind, FollowKind.jump);
    });
  });

  test('folios', () {
    expect(remainingFolio(60000, 0), '-1:00');
    expect(remainingFolio(3720000, 0), '-1:02:00');
    expect(remainingFolio(1000, 5000), '-0:00');
    expect(remainingSpoken(1120000, 0), '18 minutes 40 seconds left');
    expect(positionSpoken(1800000, 725000), '12 minutes 5 seconds of 30 minutes');
  });
}
