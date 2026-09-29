import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider_math.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The reader scrub rail (glass 8.14.2; `mobile/35` places it and sets `gestures.setExclusionRects`): a `hitMin`-wide
/// vertical hit strip; the visible 3 px track `rgba(255,255,255,0.50)` with a 1 px `rgba(0,0,0,0.60)` outline, the
/// `iris500` fill inside the outline and a 12 px `#FFFFFF` thumb with a 1.5 px `#000000` ring. On touch the track
/// widens to 6 px and a magnifier lens (`SkinGlass(tier: t4)` 120 x 164, radius 20) grows out of the thumb on
/// `springLens` and follows it on `springTrack`, showing [renderPreview] and the page number in `monoLarge`. The thumb
/// snaps page by page; `scrub.tick` per page, `scrub.boundary` at the first and last page and at segment boundaries.
class GlassScrubRail extends ConsumerStatefulWidget {
  const GlassScrubRail({
    super.key,
    required this.pageCount,
    required this.page,
    required this.onCommit,
    required this.renderPreview,
    this.segments = const [],
    this.bookmarks = const [],
    this.height = 320,
    this.forceScrubbing,
  });

  final int pageCount;

  /// The current page, 0-based.
  final int page;
  final ValueChanged<int> onCommit;
  final Widget Function(int page) renderPreview;

  /// Page counts per chapter for the read-all rail: the rail is drawn segmented with 2 px gaps and fires
  /// `scrub.boundary` at each boundary.
  final List<int> segments;
  final List<int> bookmarks;
  final double height;

  /// For captures: show the lens on this page.
  final int? forceScrubbing;

  @override
  ConsumerState<GlassScrubRail> createState() => _GlassScrubRailState();
}

class _GlassScrubRailState extends ConsumerState<GlassScrubRail> with TickerProviderStateMixin {
  late final AnimationController _thumb = AnimationController.unbounded(vsync: this, value: scrubFraction(widget.page, widget.pageCount));
  late final AnimationController _lens = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  bool _scrub = false;
  int _page = 0;
  double _startFrac = 0;
  double _dy = 0;
  double _grab = 0;
  GlassMotionEntry? _entry;

  Set<int> get _boundaries {
    final out = <int>{};
    var acc = 0;
    for (final s in widget.segments) {
      out.add(acc);
      acc += s;
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _page = widget.page;
    // Eager: a late controller first touched in dispose() would look up a deactivated ancestor.
    _thumb.value;
    _lens.value;
  }

  @override
  void didUpdateWidget(GlassScrubRail old) {
    super.didUpdateWidget(old);
    if (!_scrub && old.page != widget.page) _thumb.value = scrubFraction(widget.page, widget.pageCount);
  }

  @override
  void dispose() {
    _thumb.dispose();
    _lens.dispose();
    super.dispose();
  }

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  void _down(double y) {
    _thumb.stop();
    _startFrac = (y / widget.height).clamp(0.0, 1.0);
    _dy = 0;
    _grab = 0;
    setState(() => _scrub = true);
    _apply(_startFrac);
    if (_reduced) {
      _lens.animateTo(1, duration: const Duration(milliseconds: 150));
    } else {
      _entry = GlassMotion.recorder.begin(MotionName.scrubLens.label, 467);
      _lens.animateWith(SpringSimulation(springOf(gt.springLens), _lens.value, 1, 0)).whenComplete(() {
        if (_entry != null) GlassMotion.recorder.end(_entry!);
      });
    }
  }

  void _apply(double frac) {
    final p = scrubPage(frac, widget.pageCount);
    if (p != _page) {
      final b = _boundaries;
      final crossedSegment = b.any((s) => (s > math.min(_page, p) && s <= math.max(_page, p)));
      glassFire(ref, (p == 0 || p == widget.pageCount - 1 || crossedSegment) ? HapticEvent.scrubBoundary : HapticEvent.scrubTick);
      setState(() => _page = p);
    }
    final target = scrubFraction(p, widget.pageCount);
    if (_reduced) {
      _thumb.value = target;
    } else {
      _thumb.animateWith(SpringSimulation(springOf(gt.springTrack), _thumb.value, target, _thumb.velocity));
    }
  }

  void _move(double y) {
    if (!_scrub) return;
    _dy = y - _startFrac * widget.height;
    _apply((y / widget.height).clamp(0.0, 1.0));
  }

  void _up(double velocityPxPerS) {
    if (!_scrub) return;
    final frac = (_startFrac + _dy / widget.height + _grab).clamp(0.0, 1.0);
    final p = scrubProjectedPage(frac, velocityPxPerS / widget.height, widget.pageCount);
    setState(() {
      _scrub = false;
      _page = p;
    });
    _thumb.animateWith(SpringSimulation(springOf(gt.springSettle), _thumb.value, scrubFraction(p, widget.pageCount), 0));
    _lens.animateTo(0, duration: const Duration(milliseconds: 150));
    widget.onCommit(p);
  }

  void _step(int d) {
    final p = (widget.page + d).clamp(0, widget.pageCount - 1);
    if (p == widget.page) return;
    glassFire(ref, HapticEvent.scrubTick);
    widget.onCommit(p);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageCount <= 1) return const SizedBox.shrink();
    final hit = GlassFrame.hitMin(context);
    final forced = widget.forceScrubbing;
    final scrubbing = _scrub || forced != null;
    final shownPage = forced ?? (_scrub ? _page : widget.page);
    return Semantics(
      slider: true,
      excludeSemantics: true,
      label: 'Page scrubber',
      value: 'Page ${shownPage + 1} of ${widget.pageCount}',
      increasedValue: 'Page ${math.min(shownPage + 2, widget.pageCount)} of ${widget.pageCount}',
      decreasedValue: 'Page ${math.max(shownPage, 1)} of ${widget.pageCount}',
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: Focus(
        onKeyEvent: (n, e) {
          if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowDown || e.logicalKey == LogicalKeyboardKey.arrowRight) {
            _step(1);
          } else if (e.logicalKey == LogicalKeyboardKey.arrowUp || e.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _step(-1);
          } else if (e.logicalKey == LogicalKeyboardKey.pageDown) {
            _step(10);
          } else if (e.logicalKey == LogicalKeyboardKey.pageUp) {
            _step(-10);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: SizedBox(
          width: hit,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragDown: (d) => _down(d.localPosition.dy),
                  onVerticalDragUpdate: (d) => _move(d.localPosition.dy),
                  onVerticalDragEnd: (d) => _up(d.velocity.pixelsPerSecond.dy),
                  onVerticalDragCancel: () => _up(0),
                  child: AnimatedBuilder(
                    animation: _thumb,
                    builder: (context, _) => CustomPaint(
                      key: const ValueKey('glass-scrub-track'),
                      painter: _RailPainter(
                        fraction: _thumb.value.clamp(0.0, 1.0),
                        widen: scrubbing,
                        segments: widget.segments,
                        pageCount: widget.pageCount,
                        bookmarks: widget.bookmarks,
                      ),
                    ),
                  ),
                ),
              ),
              if (scrubbing)
                AnimatedBuilder(
                  animation: Listenable.merge([_thumb, _lens]),
                  builder: (context, _) {
                    final y = _thumb.value.clamp(0.0, 1.0) * widget.height;
                    final t = _lens.value.clamp(0.0, 1.3);
                    return Positioned(
                      right: hit + 4,
                      top: y - 82,
                      width: 120,
                      height: 164,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: _lens.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            key: const ValueKey('glass-scrub-lens'),
                            scale: _reduced ? 1 : (0.3 + 0.7 * t),
                            alignment: Alignment.centerRight,
                            child: SkinGlass(
                              tier: GlassTierId.t4,
                              shape: const GlassShape.superellipse(20),
                              layer: GlassLayerKind.hud,
                              debugLabel: 'GlassScrubLens',
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Expanded(child: ClipRSuperellipse(borderRadius: BorderRadius.circular(12), child: SizedBox.expand(child: widget.renderPreview(shownPage)))),
                                    const SizedBox(height: 4),
                                    GlassText('${shownPage + 1}', role: gt.typeMonoLarge, onGlass: true),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({required this.fraction, required this.widen, required this.segments, required this.pageCount, required this.bookmarks});
  final double fraction;
  final bool widen;
  final List<int> segments;
  final int pageCount;
  final List<int> bookmarks;

  @override
  void paint(Canvas canvas, Size size) {
    final w = widen ? 6.0 : 3.0;
    final x = size.width / 2;
    final top = 6.0, bottom = size.height - 6;
    final len = bottom - top;
    final ranges = <(double, double)>[];
    if (segments.length > 1) {
      final total = segments.fold<int>(0, (a, b) => a + b);
      var acc = 0;
      for (final s in segments) {
        final a = top + len * acc / total;
        acc += s;
        final b = top + len * acc / total;
        ranges.add((a + 1, b - 1));
      }
    } else {
      ranges.add((top, bottom));
    }
    final thumbY = top + len * fraction;
    for (final (a, b) in ranges) {
      final outline = RRect.fromLTRBR(x - w / 2 - 1, a - 1, x + w / 2 + 1, b + 1, Radius.circular(w));
      canvas.drawRRect(outline, Paint()..color = const Color(0x99000000));
      final track = RRect.fromLTRBR(x - w / 2, a, x + w / 2, b, Radius.circular(w / 2));
      canvas.drawRRect(track, Paint()..color = const Color(0x80FFFFFF));
      final fillB = math.min(b, thumbY);
      if (fillB > a) canvas.drawRRect(RRect.fromLTRBR(x - w / 2, a, x + w / 2, fillB, Radius.circular(w / 2)), Paint()..color = gt.colorIris500);
    }
    for (final bm in bookmarks) {
      final y = top + len * scrubFraction(bm, pageCount);
      canvas.drawCircle(Offset(x + w / 2 + 4, y), 2, Paint()..color = gt.colorIris400);
    }
    canvas.drawCircle(Offset(x, thumbY), 6, Paint()..color = const Color(0xFF000000));
    canvas.drawCircle(Offset(x, thumbY), 4.5, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(_RailPainter old) => old.fraction != fraction || old.widen != widen || old.segments != segments || old.bookmarks != bookmarks || old.pageCount != pageCount;
}
