import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/follow_along.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart' show speakerColor;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The transcript of the reading room (cinematic 8.16.3): the chapter as sentences, Newsreader
/// 20/30 on phones and 22/32 on tablets (the centre 6 of 8 columns). The active sentence is
/// `ink.100` on the highlighter band, which sweeps across it left to right in 200 ms as it
/// becomes active; the spoken word carries a 2 px underline that steps; every other sentence is
/// `ink.60`. Dialogue sentences carry the speaker's name above them in their tint.
///
/// The active sentence is held at 38 % of the panel by a 400 ms `settle` scroll that runs only
/// when it leaves the 20-70 % band (and jumps when two panels away). A manual scroll stops
/// following and shows `Back to the voice` pinned at the bottom; it re-follows after 4000 ms idle.
/// A tap on a sentence plays from it; each sentence is a semantics button. With stale timings the
/// sentences show unhighlighted.
class ListenTranscript extends ConsumerStatefulWidget {
  const ListenTranscript({super.key, required this.chapter, this.footer});

  final ({String sourceId, String seriesKey, String chapterKey}) chapter;

  /// The post-play card, at the end of the transcript.
  final Widget? footer;

  @override
  ConsumerState<ListenTranscript> createState() => _ListenTranscriptState();
}

class _ListenTranscriptState extends ConsumerState<ListenTranscript> with SingleTickerProviderStateMixin implements FollowSurface {
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  late final NarrationController _n = ref.read(narrationControllerProvider.notifier);
  late final ListenFollower _follower = ListenFollower(surface: this, narration: _n, reduced: () => CineMotion.reduced(context));
  bool _programmatic = false;
  List<SentenceRun> _runs = const [];
  Object? _runsFor;

  @override
  void dispose() {
    _follower.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── FollowSurface: the paragraph index here is a SENTENCE index (segment position) ─────────

  @override
  bool get isPaged => false;

  int _runOfParagraph(int paragraph) {
    for (var i = 0; i < _runs.length; i++) {
      if (_runs[i].paragraph == paragraph) return i;
    }
    return -1;
  }

  int _activeRun() {
    final seg = _n.segment.value;
    return _runs.indexWhere((r) => r.index == seg);
  }

  @override
  double? paragraphTop(int paragraph) {
    // Follow the ACTIVE sentence, not the first of its paragraph.
    final i = _activeRun() >= 0 ? _activeRun() : _runOfParagraph(paragraph);
    final ctx = _keys[i]?.currentContext;
    final box = ctx?.findRenderObject();
    final viewport = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || viewport is! RenderBox) return null;
    return box.localToGlobal(Offset.zero, ancestor: viewport).dy;
  }

  @override
  double get viewportHeight => (context.findRenderObject() as RenderBox?)?.size.height ?? 0;

  @override
  void scrollBy(double delta, {required bool animate}) {
    if (!_scroll.hasClients) return;
    final to = (_scroll.offset + delta).clamp(0.0, _scroll.position.maxScrollExtent);
    _programmatic = true;
    if (animate) {
      unawaited(_scroll.animateTo(to, duration: context.cine.durGlide, curve: CineCurves.settle).whenComplete(() => _programmatic = false));
    } else {
      _scroll.jumpTo(to);
      _programmatic = false;
    }
  }

  @override
  void jumpToParagraph(int paragraph) {
    if (!_scroll.hasClients || _runs.isEmpty) return;
    final i = _activeRun() >= 0 ? _activeRun() : _runOfParagraph(paragraph);
    if (i < 0) return;
    // An unbuilt sentence: aim by proportion, then let the next tick refine it.
    _programmatic = true;
    _scroll.jumpTo((_scroll.position.maxScrollExtent * (i / _runs.length)).clamp(0.0, _scroll.position.maxScrollExtent));
    _programmatic = false;
  }

  @override
  int? pageOfParagraph(int index) => null;
  @override
  int get currentPage => 0;
  @override
  void showPage(int page) {}

  bool _onScroll(ScrollNotification n) {
    if (_programmatic) return false;
    final byHand = (n is ScrollUpdateNotification && n.dragDetails != null) || (n is UserScrollNotification && n.direction != ScrollDirection.idle);
    if (byHand) _follower.userMoved();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final s = ref.watch(narrationControllerProvider);
    final target = s.target;
    final attr = ref.watch(novelAttributionProvider(widget.chapter)).valueOrNull ?? NovelAttribution.none;
    if (target == null) return const SizedBox.shrink();
    if (_runsFor != target) {
      _runsFor = target;
      _runs = sentenceRuns(target.paragraphs, target.audio.segments);
      _keys.clear();
    }
    final slots = speakerSlots(attr);
    final wide = MediaQuery.sizeOf(context).shortestSide >= 600;
    final size = wide ? 22.0 : 20.0, line = wide ? 32.0 : 30.0;
    final follows = s.highlightSafe;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: LayoutBuilder(
            builder: (context, box) {
              final inset = wide ? box.maxWidth / 8 : c.space4;
              return ListView.builder(
                key: const Key('transcript'),
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(inset, c.space4, inset, 96),
                itemCount: _runs.length + (widget.footer == null ? 0 : 1),
                itemBuilder: (context, i) {
                  if (i == _runs.length) return Padding(padding: EdgeInsets.only(top: c.space6), child: widget.footer);
                  final run = _runs[i];
                  return _SentenceView(
                    key: _keys.putIfAbsent(i, GlobalKey.new),
                    run: run,
                    size: size,
                    line: line,
                    follows: follows,
                    speakerTint: run.speaker == null ? null : speakerColor(c, slots[run.speaker!]?.slot ?? 1),
                    narration: _n,
                    onTap: () {
                      cineFeedback(context, HapticEvent.select);
                      unawaited(_n.seekToSegment(run.index));
                    },
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: c.space3,
          child: ValueListenableBuilder<bool>(
            valueListenable: _follower.decoupled,
            builder: (context, off, _) => off
                ? Center(
                    child: CineButton(
                      key: const Key('back-to-the-voice'),
                      label: 'Back to the voice ↓',
                      variant: CineButtonVariant.secondary,
                      size: CineButtonSize.sm,
                      onPressed: _follower.refollow,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// One sentence of the transcript: the speaker's name above dialogue, the text, the band sweeping
/// across it while it is the active sentence and the underline under the spoken word.
class _SentenceView extends StatefulWidget {
  const _SentenceView({super.key, required this.run, required this.size, required this.line, required this.follows, required this.narration, required this.onTap, this.speakerTint});

  final SentenceRun run;
  final double size, line;
  final bool follows;
  final Color? speakerTint;
  final NarrationController narration;
  final VoidCallback onTap;

  @override
  State<_SentenceView> createState() => _SentenceViewState();
}

class _SentenceViewState extends State<_SentenceView> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), value: 1);
  bool _active = false;
  bool _listeningPosition = false;

  NarrationController get _n => widget.narration;

  @override
  void initState() {
    super.initState();
    _n.segment.addListener(_onSegment);
    _active = _isActive();
  }

  @override
  void dispose() {
    _n.segment.removeListener(_onSegment);
    if (_listeningPosition) _n.position.removeListener(_onPosition);
    _sweep.dispose();
    super.dispose();
  }

  bool _isActive() => widget.follows && _n.segment.value == widget.run.index;

  void _onSegment() {
    final now = _isActive();
    if (now == _active) return;
    _active = now;
    if (now && !_listeningPosition) {
      _n.position.addListener(_onPosition);
      _listeningPosition = true;
    } else if (!now && _listeningPosition) {
      _n.position.removeListener(_onPosition);
      _listeningPosition = false;
    }
    if (now) {
      if (CineMotion.reduced(context)) {
        _sweep.value = 1;
      } else {
        _sweep.forward(from: 0);
      }
    }
    setState(() {});
  }

  void _onPosition() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final run = widget.run;
    final style = CineText.literal(context, CineFace.newsreader, widget.size, widget.line).copyWith(color: _active ? c.colorInk100 : c.colorInk60);
    final scaler = CineText.literalScaler(context, CineFace.newsreader);
    final text = Text(run.text, style: style, textScaler: scaler);
    Widget body = text;
    if (_active) {
      final target = _n.current.target!;
      final seg = target.audio.segments.firstWhere((s) => s.index == run.index, orElse: () => target.audio.segments.first);
      final word = spokenWord(seg, target.paragraphs, _n.position.value);
      // The word offsets are in the paragraph; the transcript text is the trimmed sentence.
      int? wStart, wEnd;
      if (word != null) {
        final lead = target.paragraphs[seg.paragraph].substring(seg.start, seg.end).length - target.paragraphs[seg.paragraph].substring(seg.start, seg.end).trimLeft().length;
        wStart = (word.start - seg.start - lead).clamp(0, run.text.length);
        wEnd = (word.end - seg.start - lead).clamp(0, run.text.length);
      }
      body = AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) => CustomPaint(
          key: const Key('transcript-band'),
          painter: _BandPainter(
            text: run.text,
            style: style,
            scaler: scaler,
            wash: c.colorSpotWash,
            underline: c.colorInk100,
            sweep: CineCurves.easeSet.transform(_sweep.value),
            wordStart: wStart,
            wordEnd: wEnd,
          ),
          child: text,
        ),
      );
    }
    return Semantics(
      button: true,
      label: run.speaker == null ? run.text : '${run.speaker}: ${run.text}',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: CinePressable(
        onTap: widget.onTap,
        hit: false,
        expand: true,
        builder: (context, st) => ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.line),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: c.space1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (run.speaker != null) Padding(padding: const EdgeInsets.only(bottom: 2), child: CineRoleText(run.speaker!.toUpperCase(), c.typeKicker, color: widget.speakerTint ?? c.colorInk60)),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the sweep band behind [text] over its line boxes, and the word underline.
class _BandPainter extends CustomPainter {
  _BandPainter({required this.text, required this.style, required this.scaler, required this.wash, required this.underline, required this.sweep, this.wordStart, this.wordEnd});

  final String text;
  final TextStyle style;
  final TextScaler scaler;
  final Color wash, underline;
  final double sweep;
  final int? wordStart, wordEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: scaler)..layout(maxWidth: size.width);
    final boxes = [for (final b in tp.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length))) b.toRect()];
    final fill = Paint()..color = wash;
    for (final r in sweepRects(_lines(boxes), sweep)) {
      canvas.drawRect(r, fill);
    }
    final a = wordStart, b = wordEnd;
    if (a != null && b != null && b > a) {
      final stroke = Paint()
        ..color = underline
        ..strokeWidth = 2;
      for (final box in tp.getBoxesForSelection(TextSelection(baseOffset: a, extentOffset: b))) {
        final y = box.bottom - 2;
        canvas.drawLine(Offset(box.left, y), Offset(box.right, y), stroke);
      }
    }
    tp.dispose();
  }

  /// One box per line (the selection boxes are per run; adjacent runs on a line merge).
  static List<Rect> _lines(List<Rect> boxes) {
    final out = <Rect>[];
    for (final b in boxes) {
      if (out.isNotEmpty && (out.last.top - b.top).abs() < 1) {
        out[out.length - 1] = out.last.expandToInclude(b);
      } else {
        out.add(b);
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_BandPainter o) => o.text != text || o.sweep != sweep || o.wordStart != wordStart || o.wordEnd != wordEnd || o.wash != wash || o.style != style;
}
