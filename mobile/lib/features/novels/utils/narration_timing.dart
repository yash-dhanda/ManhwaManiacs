/// The maths of following a narration sentence by sentence (cinematic 8.16): the spoken-word
/// estimate, the transcript's sentences, the WPM figure and when the page should scroll.
///
/// Pure and widget-free so the offsets are testable without a render tree.
library;

import 'dart:math' as math;

import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';

/// The word being spoken: a character range inside one paragraph.
typedef SpokenWord = ({int paragraph, int start, int end});

/// The word containing character offset `s + floor((t - start_ms) / (end_ms - start_ms) * (e - s))`
/// inside [segment], for a playhead at [positionMs].
///
/// The only place the player guesses, and it guesses no further than one word: the sentence itself
/// is measured. Null when [segment] does not fit [paragraphs] (a stale map) or the word estimate
/// lands on whitespace only.
SpokenWord? spokenWord(NovelAudioSegment segment, List<String> paragraphs, int positionMs) {
  if (segment.paragraph < 0 || segment.paragraph >= paragraphs.length) return null;
  final text = paragraphs[segment.paragraph];
  if (segment.start < 0 || segment.end > text.length || segment.end <= segment.start) return null;
  final span = segment.endMs - segment.startMs;
  final fraction = span <= 0 ? 0.0 : ((positionMs - segment.startMs) / span).clamp(0.0, 1.0);
  var offset = segment.start + (fraction * (segment.end - segment.start)).floor();
  offset = offset.clamp(segment.start, segment.end - 1);
  bool space(int i) => text.codeUnitAt(i) <= 0x20 || text.codeUnitAt(i) == 0xA0;
  // A whitespace hit belongs to the next word (or the previous at the end of the sentence).
  var probe = offset;
  while (probe < segment.end && space(probe)) {
    probe++;
  }
  if (probe >= segment.end) {
    probe = offset;
    while (probe >= segment.start && space(probe)) {
      probe--;
    }
    if (probe < segment.start) return null;
  }
  var start = probe;
  while (start > segment.start && !space(start - 1)) {
    start--;
  }
  var end = probe + 1;
  while (end < segment.end && !space(end)) {
    end++;
  }
  return (paragraph: segment.paragraph, start: start, end: end);
}

/// One sentence of the transcript.
class SentenceRun {
  const SentenceRun({
    required this.index,
    required this.paragraph,
    required this.start,
    required this.end,
    required this.text,
    this.speaker,
    this.voice,
    this.startMs = 0,
    this.endMs = 0,
  });

  /// Index into the audio's segments (what `seekToSegment` takes).
  final int index;
  final int paragraph, start, end;
  final String text;

  /// The character speaking a dialogue sentence; null for narration.
  final String? speaker;

  /// The `voice_id` that read it, when recorded.
  final String? voice;
  final int startMs, endMs;
}

/// The transcript's sentences: every segment that fits [paragraphs], with its text, speaker and
/// voice. A segment that does not fit is skipped (the caller withholds follow-along anyway).
List<SentenceRun> sentenceRuns(List<String> paragraphs, List<NovelAudioSegment> segments) {
  final out = <SentenceRun>[];
  for (final s in segments) {
    if (s.paragraph < 0 || s.paragraph >= paragraphs.length) continue;
    final text = paragraphs[s.paragraph];
    if (s.start < 0 || s.end > text.length || s.end <= s.start) continue;
    final sentence = text.substring(s.start, s.end).trim();
    if (sentence.isEmpty) continue;
    out.add(
      SentenceRun(
        index: s.index,
        paragraph: s.paragraph,
        start: s.start,
        end: s.end,
        text: sentence,
        speaker: s.isSpeech ? s.speaker : null,
        voice: s.voice,
        startMs: s.startMs,
        endMs: s.endMs,
      ),
    );
  }
  return out;
}

/// The `≈ 182 WPM` figure: [wordCount] words in [totalMs] of audio, at [speed]×.
int narrationWpm(int wordCount, int totalMs, double speed) {
  if (wordCount <= 0 || totalMs <= 0) return 0;
  return (wordCount / (totalMs / 60000) * speed).round();
}

/// Words in [paragraphs] (whitespace-separated), for [narrationWpm].
int wordCountOf(List<String> paragraphs) {
  var n = 0;
  for (final p in paragraphs) {
    n += p.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
  return n;
}

enum FollowKind { none, scroll, jump }

/// What follow-along does about the active sentence (cinematic 8.16): inside 20-70 % of the
/// viewport nothing; outside, scroll to put it at 38 %; more than two viewports away, jump.
///
/// [activeTop] is the sentence's top from the viewport top; [delta] is how far the scroll offset
/// must move (positive = scroll forward).
({FollowKind kind, double delta}) followDecision(double activeTop, double viewportHeight) {
  if (viewportHeight <= 0) return (kind: FollowKind.none, delta: 0);
  final fraction = activeTop / viewportHeight;
  if (fraction >= 0.20 && fraction <= 0.70) return (kind: FollowKind.none, delta: 0);
  final delta = activeTop - 0.38 * viewportHeight;
  return (kind: delta.abs() > 2 * viewportHeight ? FollowKind.jump : FollowKind.scroll, delta: delta);
}

/// The `-18:40` folio: time left, m:ss (h:mm:ss over an hour), never negative.
String remainingFolio(int totalMs, int positionMs) => '-${clockText(math.max(0, totalMs - positionMs))}';

/// m:ss, h:mm:ss over an hour. Truncates: rounding would read a second ahead of the voice.
String clockText(int ms) {
  final total = ms < 0 ? 0 : ms ~/ 1000;
  final s = (total % 60).toString().padLeft(2, '0');
  final m = (total ~/ 60) % 60;
  final h = total ~/ 3600;
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// The folio as a screen reader says it: "18 minutes 40 seconds left".
String remainingSpoken(int totalMs, int positionMs) {
  final total = math.max(0, totalMs - positionMs) ~/ 1000;
  final h = total ~/ 3600, m = (total ~/ 60) % 60, s = total % 60;
  String unit(int n, String w) => '$n $w${n == 1 ? '' : 's'}';
  final parts = [if (h > 0) unit(h, 'hour'), if (m > 0 || h > 0) unit(m, 'minute'), unit(s, 'second')];
  return '${parts.join(' ')} left';
}

/// "12 minutes 5 seconds of 30 minutes": the chapter ruler's semantic value.
String positionSpoken(int totalMs, int positionMs) {
  String say(int ms) {
    final t = ms ~/ 1000;
    final h = t ~/ 3600, m = (t ~/ 60) % 60, s = t % 60;
    String unit(int n, String w) => '$n $w${n == 1 ? '' : 's'}';
    final parts = [if (h > 0) unit(h, 'hour'), if (m > 0) unit(m, 'minute'), if (s > 0 || (h == 0 && m == 0)) unit(s, 'second')];
    return parts.join(' ');
  }

  return '${say(positionMs)} of ${say(totalMs)}';
}
