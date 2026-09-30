import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';

NovelAttribution attr(List<String> paragraphs, {List<NovelSpeakerSpan> spans = const [], List<String> cast = const [], String? fp, bool attributed = true}) =>
    NovelAttribution(
      attributed: attributed,
      narrator: null,
      narratorVoiceId: null,
      cast: [for (final n in cast) NovelCastMember(name: n, gender: 'unknown', voiceId: null)],
      textFingerprint: fp ?? chapterFingerprint(paragraphs),
      spans: spans,
    );

void main() {
  const paragraphs = ['"Hello," said Alice.', '"Oh dear!" cried the Rabbit.'];
  test('fingerprint matches the server rule (sha256 of utf8 + NUL)', () {
    expect(chapterFingerprint(['ab']), isNot(chapterFingerprint(['a', 'b'])));
    expect(chapterFingerprint(const []), 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
  });

  test('cast order assigns slots, narration untinted', () {
    final a = attr(paragraphs, cast: ['Alice', 'Rabbit'], spans: const [
      NovelSpeakerSpan(paragraph: 0, start: 0, end: 8, head: '"Hello,"', speaker: 'Alice'),
      NovelSpeakerSpan(paragraph: 1, start: 0, end: 10, head: '"Oh dear!"', speaker: 'Rabbit'),
      NovelSpeakerSpan(paragraph: 1, start: 11, end: 12, head: '', speaker: null),
    ],);
    final runs = speakerRuns(a, paragraphs);
    expect(runs[0]!.single.slot, 1);
    expect(runs[1]!.single.slot, 2);
    expect(runs[1]!.length, 1);
    expect(runs[0]!.single.dotted, isFalse);
  });

  test('the 11th speaker reuses slot 1 with a dotted underline', () {
    final names = [for (var i = 0; i < 11; i++) 'S$i'];
    final a = attr(paragraphs, cast: names);
    final s = speakerSlots(a);
    expect(s['S0'], (slot: 1, dotted: false));
    expect(s['S9'], (slot: 10, dotted: false));
    expect(s['S10'], (slot: 1, dotted: true));
  });

  test('a stale fingerprint or unattributed chapter returns no tints', () {
    const spans = [NovelSpeakerSpan(paragraph: 0, start: 0, end: 8, head: '"Hello,"', speaker: 'Alice')];
    expect(speakerRuns(attr(paragraphs, cast: ['Alice'], spans: spans, fp: 'nope'), paragraphs), isEmpty);
    expect(speakerRuns(attr(paragraphs, cast: ['Alice'], spans: spans, attributed: false), paragraphs), isEmpty);
  });

  test('a failed head proof drops the paragraph; code point offsets map to UTF-16', () {
    final p = ['😀 "Hi," she said.'];
    final good = attr(p, cast: ['She'], spans: const [NovelSpeakerSpan(paragraph: 0, start: 2, end: 7, head: '"Hi,"', speaker: 'She')]);
    final run = speakerRuns(good, p)[0]!.single;
    expect(p[0].substring(run.start, run.end), '"Hi,"');
    final bad = attr(p, cast: ['She'], spans: const [NovelSpeakerSpan(paragraph: 0, start: 2, end: 7, head: 'XX', speaker: 'She')]);
    expect(speakerRuns(bad, p), isEmpty);
  });
}
