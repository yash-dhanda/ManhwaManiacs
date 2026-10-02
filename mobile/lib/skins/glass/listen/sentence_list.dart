/// The lyrics-style sentence list (glass 8.16.2, E10): the chapter's sentences in `title3` Literata, the active one at full ink inside
/// a lozenge whose rects morph between sentences on `springSnappy` (stretching across line breaks with `band_geometry.dart`), the others
/// in `label2` (never dimmed by opacity: they stay tappable). Follow keeps the active sentence at 38 % of the panel and scrolls on
/// `springSettle` only when it leaves 20-70 %; a manual scroll decouples and shows "Back to the voice", which re-couples on its own after
/// 4000 ms idle. A tap plays from that sentence.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/listen/band_geometry.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show SpringCurve, springOf;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/speaker_bands.dart' show speakerHue;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The lozenge: the content twin of `glassThin` (fill `rgba(19,19,23,0.62)`, 0.5 px rim, inner light), radius 12.
const double kLozengeRadius = 12;
const Color kLozengeFill = Color(0x9E131317);

class GlassSentenceList extends ConsumerStatefulWidget {
  const GlassSentenceList({super.key, this.onGlass = false});

  /// In the desktop T5 window: inactive sentences `onGlass` at `wght` 420 and the active one at 700.
  final bool onGlass;

  @override
  ConsumerState<GlassSentenceList> createState() => _GlassSentenceListState();
}

class _GlassSentenceListState extends ConsumerState<GlassSentenceList> with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _content = GlobalKey();
  final Map<int, GlobalKey> _keys = {};
  late final AnimationController _morph = AnimationController.unbounded(vsync: this, value: 1);
  /// The jump's cross-fade (glass 4.10 Follow scroll, 120 ms): [_ghost] is the list as it was, fading out over the list already at
  /// its new place.
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  final GlobalKey _boundary = GlobalKey();
  ui.Image? _ghost;
  List<Rect> _from = const [], _to = const [];
  int _active = -2;
  bool _decoupled = false;
  Timer? _recouple;
  List<SentenceRun> _runs = const [];
  Object? _runsFor;
  late final NarrationController _narr = ref.read(narrationControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _narr.segment.addListener(_onSegment);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onSegment(first: true));
  }

  @override
  void dispose() {
    _narr.segment.removeListener(_onSegment);
    _recouple?.cancel();
    _scroll.dispose();
    _morph.dispose();
    _fade.dispose();
    _ghost?.dispose();
    super.dispose();
  }

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  GlobalKey _keyOf(int i) => _keys.putIfAbsent(i, GlobalKey.new);

  void _onSegment({bool first = false}) {
    if (!mounted) return;
    final s = ref.read(narrationControllerProvider);
    final i = s.highlightSafe ? _narr.segment.value : -1;
    if (i == _active && !first) return;
    final prevRects = _currentRects();
    _active = i;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = _rectsOf(i);
      setState(() {
        _from = prevRects.isEmpty ? next : prevRects;
        _to = next;
      });
      if (_reduced || _from.isEmpty) {
        _morph.value = 1;
      } else {
        _morph.value = 0;
        _morph.animateWith(SpringSimulation(springOf(gt.springSnappy), 0, 1, 0));
      }
      if (!_decoupled) _follow();
    });
  }

  List<Rect> _currentRects() => _to.isEmpty ? const [] : morphBands(_from, _to, _morph.value.clamp(0.0, 1.0));

  /// The active sentence's line rects in the scroll content's coordinates, padded for the lozenge.
  List<Rect> _rectsOf(int segmentIndex) {
    final run = _runs.where((r) => r.index == segmentIndex).firstOrNull;
    final box = _content.currentContext?.findRenderObject();
    if (run == null || box is! RenderBox || !box.hasSize) return const [];
    final p = _paragraphUnder(_keyOf(run.index));
    if (p == null || !p.hasSize) return const [];
    final m = p.getTransformTo(box);
    final boxes = p.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: run.text.length));
    return [for (final r in bandRects(boxes, padX: 8, padY: 4)) MatrixUtils.transformRect(m, r)];
  }

  RenderParagraph? _paragraphUnder(GlobalKey key) {
    RenderParagraph? found;
    void visit(RenderObject r) {
      if (found != null) return;
      if (r is RenderParagraph) {
        found = r;
        return;
      }
      r.visitChildren(visit);
    }

    final ro = key.currentContext?.findRenderObject();
    if (ro != null) visit(ro);
    return found;
  }

  void _follow() {
    if (!_scroll.hasClients || _to.isEmpty) return;
    final pos = _scroll.position;
    final viewport = pos.viewportDimension;
    final top = _to.first.top - pos.pixels;
    final d = followDecision(top, viewport);
    if (d.kind == FollowKind.none) return;
    final target = (pos.pixels + d.delta).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if (_reduced) {
      _scroll.jumpTo(target);
    } else if (d.kind == FollowKind.jump) {
      _crossFadeTo(target);
    } else {
      unawaited(_scroll.animateTo(target, duration: Duration(milliseconds: gt.springSettle.ms), curve: SpringCurve(gt.springSettle)));
    }
  }

  void _crossFadeTo(double target) {
    ui.Image? before;
    final ro = _boundary.currentContext?.findRenderObject();
    if (ro is RenderRepaintBoundary && ro.hasSize) {
      try {
        before = ro.toImageSync(pixelRatio: MediaQuery.devicePixelRatioOf(context));
      } catch (_) {}
    }
    _scroll.jumpTo(target);
    if (before == null) return;
    _ghost?.dispose();
    setState(() => _ghost = before);
    _fade.value = 1;
    unawaited(_fade.animateTo(0).whenComplete(() {
      if (!mounted || _ghost != before) return;
      setState(() => _ghost = null);
      before!.dispose();
    }),);
  }

  void _decouple() {
    _recouple?.cancel();
    _recouple = Timer(const Duration(milliseconds: 4000), _backToTheVoice);
    if (!_decoupled) setState(() => _decoupled = true);
  }

  void _backToTheVoice() {
    _recouple?.cancel();
    if (!mounted) return;
    setState(() => _decoupled = false);
    _follow();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(narrationControllerProvider);
    final t = s.target;
    if (t == null) return const SizedBox.shrink();
    if (_runsFor != t) {
      _runsFor = t;
      _runs = sentenceRuns(t.paragraphs, t.audio.segments);
      _keys.clear();
    }
    final attribution = ref.watch(novelAttributionProvider(t.key)).valueOrNull;
    final slots = attribution == null ? const <String, ({int slot, bool dotted})>{} : speakerSlots(attribution);
    final onGlass = widget.onGlass;
    final base = roleStyle(context, gt.typeTitle3, onGlass: onGlass, maxScale: 1.5).copyWith(fontFamily: 'LiterataMM');
    TextStyle style(bool active) => base.copyWith(
          color: active ? (onGlass ? gt.colorOnGlass : gt.colorLabel1) : (onGlass ? gt.colorOnGlass.withValues(alpha: 0.78) : gt.colorLabel2),
          fontVariations: [FontVariation('wght', active ? (onGlass ? 700 : 600) : (onGlass ? 420 : 400))],
        );
    final active = s.highlightSafe ? _narr.segment.value : -1;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollStartNotification && n.dragDetails != null) _decouple();
            if (n is ScrollUpdateNotification && n.dragDetails != null) _decouple();
            return false;
          },
          child: RepaintBoundary(
            key: _boundary,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              child: Stack(
                key: _content,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _morph,
                        builder: (context, _) => CustomPaint(painter: _LozengePainter(morphBands(_from, _to, _morph.value.clamp(0.0, 1.0)))),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final r in _runs)
                        _Sentence(
                          key: ValueKey('sentence-${r.index}'),
                          textKey: _keyOf(r.index),
                          run: r,
                          active: r.index == active,
                          style: style(r.index == active),
                          tint: r.speaker == null || slots[r.speaker] == null ? null : speakerHue(slots[r.speaker]!.slot),
                          onTap: () {
                            glassFire(ref, HapticEvent.select);
                            unawaited(_narr.seekToSegment(r.index));
                            if (_decoupled) _backToTheVoice();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_ghost != null)
          Positioned.fill(
            child: IgnorePointer(child: FadeTransition(opacity: _fade, child: RawImage(key: const ValueKey('follow-ghost'), image: _ghost, fit: BoxFit.fill))),
          ),
        if (_decoupled)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: GlassPressable(
                material: GlassMaterial.content,
                sink: 0.96,
                onTap: _backToTheVoice,
                semanticsLabel: 'Back to the voice',
                builder: (context, info) => DecoratedBox(
                  decoration: ShapeDecoration(color: gt.colorFill2, shape: const GlassShape.capsule().border(const Size(160, 40))),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: GlassText('Back to the voice', role: gt.typeSubhead, wght: 600, onGlass: true, maxLines: 1)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Sentence extends StatelessWidget {
  const _Sentence({super.key, required this.textKey, required this.run, required this.active, required this.style, required this.tint, required this.onTap});
  final GlobalKey textKey;
  final SentenceRun run;
  final bool active;
  final TextStyle style;
  final Color? tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: active,
        label: run.speaker == null ? run.text : '${run.speaker}: ${run.text}',
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(color: tint?.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
                child: Text(run.text, key: textKey, style: style, textScaler: TextScaler.noScaling),
              ),
            ),
          ),
        ),
      );
}

class _LozengePainter extends CustomPainter {
  _LozengePainter(this.rects);
  final List<Rect> rects;

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in rects) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(kLozengeRadius));
      canvas.drawRRect(rr, Paint()..color = kLozengeFill);
      canvas.drawRRect(rr.deflate(0.25), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = const Color(0x1AFFFFFF),);
      // Inner light: a faint white wash from the top edge.
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.5), Paint()..color = const Color(0x0DFFFFFF));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LozengePainter o) => o.rects != rects;
}
