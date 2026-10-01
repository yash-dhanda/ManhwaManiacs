/// Highlight-as-read on the page (glass 8.16.7, J): while narrating with `highlightSafe` true the active sentence wears a band at 14 %
/// of its speaker's `spk` hue (narration: `iris500`), radius 6, padding 2 x 4 px, that SLIDES between sentences on `springSnappy` (never
/// a cross-fade), across line breaks and across paragraphs; the current word gets a 2 px underline in the tint, stepping with the word
/// estimate and never animated. A spring-driven value outside the named moves of glass 4.10 (like the sentence lozenge). Reduced motion:
/// the band jumps with a 120 ms cross-fade.
library;

import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/glass/listen/band_geometry.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show springOf;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/glass_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/speaker_bands.dart' show speakerHue;

/// A sentence (or word) as a paragraph and a character range.
typedef BandTarget = ({int paragraph, int start, int end});

const double kBandAlpha = 0.14;
const Duration kBandCrossFade = Duration(milliseconds: 120);

/// Drives the band for the chapter on screen. Owned by the reader (it lends its `TickerProvider`); painters listen to it through
/// `GlassTextPiece.repaint`, the reader through [onSentence] (follow and paged turns).
class GlassListenBand extends ChangeNotifier {
  GlassListenBand({required TickerProvider vsync, required bool Function() reduced, this.onSentence}) : _reduced = reduced {
    _c = AnimationController.unbounded(vsync: vsync, value: 1)..addListener(notifyListeners);
  }

  final bool Function() _reduced;

  /// Called after the active sentence changed (the reader follows it).
  final void Function(BandTarget? target)? onSentence;
  late final AnimationController _c;
  NarrationController? _narr;
  NovelChapterKey? _key;
  NovelAudio? _audio;
  List<String> _paragraphs = const [];
  Map<String, ({int slot, bool dotted})> _slots = const {};
  bool _enabled = false;
  int _segment = -1;
  BandTarget? prev, next;
  BandTarget? word;
  Color tint = gt.colorIris500;

  /// The band is up: narrating this chapter with timing the server vouches for.
  bool get enabled => _enabled;

  /// 0 (at [prev]) to 1 (at [next]).
  double get t => _c.value.clamp(0.0, 1.0);

  bool get reduced => _reduced();

  /// The active segment index, -1 for none.
  int get segment => _segment;

  /// Binds the narration and the chapter on screen; cheap, called from every build.
  void sync({required NarrationController narration, required NarrationState state, required NovelChapterKey chapter, required List<String> paragraphs, NovelAttribution? attribution}) {
    if (!identical(_narr, narration)) {
      _narr?.segment.removeListener(_onSegment);
      _narr?.position.removeListener(_onPosition);
      _narr = narration
        ..segment.addListener(_onSegment)
        ..position.addListener(_onPosition);
    }
    final mine = state.key == chapter && state.target != null;
    final on = mine && state.active && state.highlightSafe;
    _key = chapter;
    _audio = state.target?.audio;
    _paragraphs = paragraphs;
    _slots = attribution == null ? const {} : speakerSlots(attribution);
    if (on != _enabled) {
      _enabled = on;
      if (!on) {
        prev = next = word = null;
        _segment = -1;
        notifyListeners();
        onSentence?.call(null);
      } else {
        _onSegment();
      }
    }
  }

  void _onSegment() {
    if (!_enabled) return;
    final i = _narr?.segment.value ?? -1;
    if (i == _segment) return;
    _segment = i;
    final audio = _audio;
    if (audio == null || i < 0 || i >= audio.segments.length) {
      prev = next;
      next = null;
      word = null;
      _c.value = 1;
      notifyListeners();
      onSentence?.call(null);
      return;
    }
    final s = audio.segments[i];
    final target = (paragraph: s.paragraph, start: s.start, end: s.end);
    final speaker = s.isSpeech ? s.speaker : null;
    final slot = speaker == null ? null : _slots[speaker]?.slot;
    tint = slot == null ? gt.colorIris500 : speakerHue(slot);
    prev = next ?? target;
    next = target;
    _slide();
    _onPosition();
    onSentence?.call(target);
  }

  void _slide() {
    _c.stop();
    _c.value = 0;
    if (_reduced()) {
      unawaited(_c.animateTo(1, duration: kBandCrossFade));
    } else {
      unawaited(_c.animateWith(SpringSimulation(springOf(gt.springSnappy), 0, 1, 0)));
    }
  }

  void _onPosition() {
    if (!_enabled) return;
    final audio = _audio, narr = _narr;
    if (audio == null || narr == null || _segment < 0 || _segment >= audio.segments.length) return;
    final w = spokenWord(audio.segments[_segment], _paragraphs, narr.position.value);
    final target = w == null ? null : (paragraph: w.paragraph, start: w.start, end: w.end);
    if (target != word) {
      word = target;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _narr?.segment.removeListener(_onSegment);
    _narr?.position.removeListener(_onPosition);
    _c.dispose();
    super.dispose();
  }

  /// The chapter this band is bound to (tests).
  NovelChapterKey? get chapter => _key;
}

/// The band and the word underline of one paragraph (appended to `GlassParagraph`'s ordered decoration list).
class ListenBandDecoration extends GlassParagraphDecoration {
  const ListenBandDecoration(this.band, this.paragraph);
  final GlassListenBand band;
  final int paragraph;

  List<Rect> _rects(GlassParagraphGeometry g, BandTarget x) => bandRectsOf(g.boxes(x.start, x.end));

  @override
  void paintBehind(Canvas canvas, GlassParagraphGeometry g) {
    if (!band.enabled) return;
    final n = band.next, p = band.prev;
    final t = band.t;
    final fill = Paint();
    void draw(List<Rect> rects, double alpha) {
      fill.color = band.tint.withValues(alpha: kBandAlpha * alpha);
      for (final r in rects) {
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(kBandRadius)), fill);
      }
    }

    final here = n != null && n.paragraph == paragraph;
    final was = p != null && p.paragraph == paragraph;
    if (band.reduced) {
      // A jump with a 120 ms cross-fade.
      if (here) draw(_rects(g, n), t);
      if (was && !here && t < 1) draw(_rects(g, p), 1 - t);
      return;
    }
    if (here) {
      final next = _rects(g, n);
      if (next.isEmpty) return;
      if (was && p != n) {
        draw(morphBands(_rects(g, p), next, t), 1);
      } else if (!was && t < 1) {
        // Arriving from another paragraph: the band grows in from the left edge.
        draw([for (final r in next) Rect.fromLTRB(r.left, r.top, r.left + r.width * t, r.bottom)], 1);
      } else {
        draw(next, 1);
      }
    } else if (was && t < 1) {
      // Leaving for another paragraph: the band shrinks away to the right.
      draw([for (final r in _rects(g, p)) Rect.fromLTRB(r.right - r.width * (1 - t), r.top, r.right, r.bottom)], 1);
    }
  }

  @override
  void paintFront(Canvas canvas, GlassParagraphGeometry g) {
    final w = band.word;
    if (!band.enabled || w == null || w.paragraph != paragraph) return;
    final line = Paint()
      ..color = band.tint
      ..strokeWidth = 2;
    for (final b in g.boxes(w.start, w.end)) {
      final y = g.baselineOf(b) + 0.18 * g.fontSize + 1;
      canvas.drawLine(Offset(b.left, y), Offset(b.right, y), line);
    }
  }

  @override
  bool operator ==(Object other) => other is ListenBandDecoration && identical(other.band, band) && other.paragraph == paragraph;

  @override
  int get hashCode => Object.hash(identityHashCode(band), paragraph);
}
