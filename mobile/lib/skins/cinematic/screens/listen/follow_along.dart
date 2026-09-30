import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The parts of [boxes] a highlighter sweep of [progress] (0-1) has reached: the boxes are the
/// line boxes of one sentence in reading order, and the sweep runs left to right, line after line.
List<Rect> sweepRects(List<Rect> boxes, double progress) {
  if (progress >= 1) return boxes;
  final total = boxes.fold<double>(0, (a, b) => a + b.width);
  var left = total * progress.clamp(0.0, 1.0);
  final out = <Rect>[];
  for (final b in boxes) {
    if (left <= 0) break;
    final w = left >= b.width ? b.width : left;
    out.add(Rect.fromLTWH(b.left, b.top, w, b.height));
    left -= w;
  }
  return out;
}

/// The decorations of paragraph [paragraph] while the voice reads sentence [segment] of [audio]:
/// the [speaker] tints with their background dropped under the band (their underline stays), the
/// `spot.wash` band swept [sweep] of the way across the sentence, and a 2 px underline in the
/// stock ink under the spoken [word] (which steps without animation).
List<NovelDecoration> listenDecorations({
  required int paragraph,
  required NovelAudio audio,
  required int segment,
  required List<NovelDecoration> speaker,
  required Color wash,
  required Color ink,
  SpokenWord? word,
  double sweep = 1,
}) {
  if (segment < 0 || segment >= audio.segments.length) return speaker;
  final s = audio.segments[segment];
  if (s.paragraph != paragraph) return speaker;
  return [
    for (final d in speaker)
      if (d.start < s.end && d.end > s.start && d.fill != null)
        NovelDecoration(start: d.start, end: d.end, underline: d.underline, dotted: d.dotted, speaker: d.speaker)
      else
        d,
    NovelDecoration(start: s.start, end: s.end, fill: wash, sweep: sweep),
    if (word != null && word.paragraph == paragraph) NovelDecoration(start: word.start, end: word.end, underline: ink),
  ];
}

/// The Listen decorations of the chapter on the page, shared by every paragraph (scroll or paged):
/// the `spot.wash` band over the sentence being read, swept in over `durClip` (200 ms) when a
/// sentence becomes active (at once under reduced motion), and the 2 px word underline that
/// steps. [decorate] lays them over a paragraph's speaker tints. Notifies only when something
/// visible changed: the sentence, the spoken word, or a sweep frame. Nothing is drawn when the
/// timings no longer match the text or another chapter is narrating.
class ListenDecorator extends ChangeNotifier {
  ListenDecorator({
    required this.narration,
    required this.chapterOf,
    required TickerProvider vsync,
    required this.reduced,
    required this.wash,
    required this.ink,
  }) : _sweep = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 200), value: 1) {
    narration.segment.addListener(_onSegment);
    narration.position.addListener(_onPosition);
    _sweep.addListener(notifyListeners);
    _segment = _mine();
  }

  final NarrationController narration;

  /// The chapter on screen (it changes when the next chapter swaps in place): another chapter's
  /// audio never lights it.
  final ({String sourceId, String seriesKey, String chapterKey}) Function() chapterOf;
  final bool Function() reduced;

  /// `spot.wash` and the stock ink, updated by the reader when the stock changes.
  Color wash, ink;
  final AnimationController _sweep;
  int _segment = -1;
  SpokenWord? _word;

  /// The active sentence index, or -1.
  int get segment => _segment;

  int _mine() {
    final s = narration.current;
    if (s.key != chapterOf() || !s.highlightSafe || !s.active) return -1;
    final i = narration.segment.value;
    final audio = s.target?.audio;
    return audio == null || i < 0 || i >= audio.segments.length ? -1 : i;
  }

  void _onSegment() => _refresh();

  void _onPosition() => _refresh();

  /// Recomputes the active sentence and the spoken word; notifies only when either changed (or
  /// a sentence just became active, which also restarts the sweep).
  void _refresh() {
    final now = _mine();
    var changed = false;
    if (now != _segment) {
      _segment = now;
      changed = true;
      if (now >= 0) {
        if (reduced()) {
          _sweep.value = 1;
        } else {
          unawaited(_sweep.forward(from: 0));
        }
      }
    }
    final t = narration.current.target;
    final w = now < 0 || t == null ? null : spokenWord(t.audio.segments[now], t.paragraphs, narration.position.value);
    if (w != _word) {
      _word = w;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// [speaker] with the band and the word laid over it, for paragraph [paragraph].
  List<NovelDecoration> decorate(int paragraph, List<NovelDecoration> speaker) {
    _segment = _mine();
    final t = narration.current.target;
    if (_segment < 0 || t == null) return speaker;
    return listenDecorations(
      paragraph: paragraph,
      audio: t.audio,
      segment: _segment,
      speaker: speaker,
      wash: wash,
      ink: ink,
      word: _word,
      sweep: CineCurves.easeSet.transform(_sweep.value),
    );
  }

  @override
  void dispose() {
    narration.segment.removeListener(_onSegment);
    narration.position.removeListener(_onPosition);
    _sweep.dispose();
    super.dispose();
  }
}

/// What follow-along needs from the surface it scrolls: the reader's scroll or paged body.
abstract interface class FollowSurface {
  bool get isPaged;

  /// The top of paragraph [index] in px from the viewport top; null when it is not built.
  double? paragraphTop(int index);
  double get viewportHeight;

  /// Moves the scroll offset by [delta] (positive = forward); [animate] runs the 400 ms `settle`.
  void scrollBy(double delta, {required bool animate});

  /// A far jump: puts [index] at the reading line.
  void jumpToParagraph(int index);

  /// Paged mode: the page holding [index], the page shown, and turning to a page.
  int? pageOfParagraph(int index);
  int get currentPage;
  void showPage(int page);
}

/// Following the voice on the page and in the transcript (cinematic 8.16.2): the spoken paragraph
/// is held at the reading line (38 %) by a 400 ms `settle` scroll that runs only when it leaves
/// the 20-70 % band, and jumps when it is more than two viewports away. A manual scroll decouples
/// it (and `Back to the voice` shows); it re-follows after [idle] (4000 ms) without scrolling. In
/// paged mode the reader turns to the active sentence's page.
class ListenFollower {
  ListenFollower({
    required this.surface,
    required this.narration,
    required this.reduced,
    this.idle = const Duration(milliseconds: 4000),
    Timer Function(Duration, void Function())? timer,
  }) : _timer = timer ?? Timer.new {
    narration.segment.addListener(_onSegment);
  }

  final FollowSurface surface;
  final NarrationController narration;
  final bool Function() reduced;
  final Duration idle;
  final Timer Function(Duration, void Function()) _timer;
  final ValueNotifier<bool> decoupled = ValueNotifier<bool>(false);
  Timer? _idle;

  void dispose() {
    narration.segment.removeListener(_onSegment);
    _idle?.cancel();
    decoupled.dispose();
  }

  bool get _live => narration.current.highlightSafe && narration.current.active;

  /// The user scrolled or turned the page by hand.
  void userMoved() {
    if (!_live) return;
    decoupled.value = true;
    _idle?.cancel();
    _idle = _timer(idle, refollow);
  }

  /// `Back to the voice`, or the idle timer.
  void refollow() {
    _idle?.cancel();
    decoupled.value = false;
    _onSegment(force: true);
  }

  void _onSegment({bool force = false}) {
    if (decoupled.value || !_live) return;
    final t = narration.current.target;
    final i = narration.segment.value;
    if (t == null || i < 0 || i >= t.audio.segments.length) return;
    final p = t.audio.segments[i].paragraph;
    if (surface.isPaged) {
      final page = surface.pageOfParagraph(p);
      if (page != null && page != surface.currentPage) surface.showPage(page);
      return;
    }
    final top = surface.paragraphTop(p);
    if (top == null) {
      surface.jumpToParagraph(p);
      return;
    }
    final d = followDecision(top, surface.viewportHeight);
    switch (d.kind) {
      case FollowKind.none:
        break;
      case FollowKind.scroll:
        surface.scrollBy(d.delta, animate: !reduced());
      case FollowKind.jump:
        surface.scrollBy(d.delta, animate: false);
    }
  }
}
