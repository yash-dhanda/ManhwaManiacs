import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ruler_math.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The ruler scrubber (cinematic 8.14.4): a 2 px track, the played part in `ink.100`, page ticks,
/// bookmarks standing above it and a thumb with a folio flag. Dragging seeks live; releasing
/// settles the thumb on its page with the `scrub` spring.
class ReaderRuler extends StatefulWidget {
  const ReaderRuler({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onSeek,
    this.bookmarkPages = const [],
    this.rtl = false,
  });

  final int page, pageCount;
  final List<int> bookmarkPages;
  final bool rtl;

  /// Called live while dragging and on a tap.
  final ValueChanged<int> onSeek;

  @override
  State<ReaderRuler> createState() => _ReaderRulerState();
}

class _ReaderRulerState extends State<ReaderRuler> with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController.unbounded(vsync: this);
  double? _dragX;
  int? _dragPage;
  double _width = 1;

  bool get _enabled => widget.pageCount > 1;
  bool get _dragging => _dragPage != null;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _seek(double x) {
    final page = rulerPage(x, widget.pageCount, _width, rtl: widget.rtl);
    setState(() {
      _dragX = x.clamp(0.0, _width);
      if (page != _dragPage && _dragPage != null) cineFeedback(context, HapticEvent.scrubTick);
      _dragPage = page;
    });
    widget.onSeek(page);
  }

  void _release() {
    final page = _dragPage;
    final from = _dragX;
    if (page == null || from == null) return;
    final to = rulerX(page, widget.pageCount, _width, rtl: widget.rtl);
    setState(() {
      _dragPage = null;
      _dragX = null;
    });
    if (CineMotion.reduced(context)) return;
    // The thumb settles from where the finger let go to its page.
    _settle
      ..value = from
      ..animateWith(SpringSimulation(CineSprings.scrub.description, from, to, 0));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    return Semantics(
      slider: true,
      label: 'Page position',
      value: 'Page ${widget.page} of ${widget.pageCount}',
      increasedValue: 'Page ${(widget.page + 1).clamp(1, widget.pageCount)}',
      decreasedValue: 'Page ${(widget.page - 1).clamp(1, widget.pageCount)}',
      onIncrease: _enabled ? () => widget.onSeek((widget.page + 1).clamp(1, widget.pageCount)) : null,
      onDecrease: _enabled ? () => widget.onSeek((widget.page - 1).clamp(1, widget.pageCount)) : null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          _width = box.maxWidth.isFinite ? box.maxWidth : 1;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (d) => _seek(d.localPosition.dx) : null,
            onTapUp: _enabled ? (_) => _release() : null,
            onTapCancel: _enabled ? _release : null,
            onHorizontalDragStart: _enabled ? (d) => _seek(d.localPosition.dx) : null,
            onHorizontalDragUpdate: _enabled ? (d) => _seek(d.localPosition.dx) : null,
            onHorizontalDragEnd: _enabled ? (_) => _release() : null,
            onHorizontalDragCancel: _enabled ? _release : null,
            child: SizedBox(
              height: hit,
              child: AnimatedBuilder(
                animation: _settle,
                builder: (context, _) {
                  final rest = rulerX(widget.page, widget.pageCount, _width, rtl: widget.rtl);
                  final x = _dragX ?? (_settle.isAnimating ? _settle.value : rest);
                  return CustomPaint(
                    size: Size(_width, hit),
                    painter: _RulerPainter(
                      x: x,
                      dragging: _dragging,
                      ticks: rulerTickXs(widget.pageCount, _width, rtl: widget.rtl),
                      bookmarks: rulerBookmarkXs(widget.bookmarkPages, widget.pageCount, _width, rtl: widget.rtl),
                      rtl: widget.rtl,
                      enabled: _enabled,
                      track: c.colorRule2,
                      played: c.colorInk100,
                      tick: c.colorInk30,
                      spot: c.colorSpot,
                    ),
                    child: _dragging
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Transform.translate(
                              offset: Offset((x - 22).clamp(0.0, (_width - 44).clamp(0.0, double.infinity)), -34),
                              child: _Flag(page: _dragPage!),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The `p. 18` flag above the thumb: a `#000000` box with a 1 px `ink.100` border.
class _Flag extends StatelessWidget {
  const _Flag({required this.page});
  final int page;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorInk100)),
      child: CineRoleText('p. $page', c.typeFolio, color: c.colorInk100),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.x,
    required this.dragging,
    required this.ticks,
    required this.bookmarks,
    required this.rtl,
    required this.enabled,
    required this.track,
    required this.played,
    required this.tick,
    required this.spot,
  });

  final double x;
  final bool dragging, rtl, enabled;
  final List<double> ticks, bookmarks;
  final Color track, played, tick, spot;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawRect(Rect.fromLTWH(0, y - 1, size.width, 2), Paint()..color = enabled ? track : track.withValues(alpha: 0.5));
    if (!enabled) return;
    final from = rtl ? x : 0.0, to = rtl ? size.width : x;
    canvas.drawRect(Rect.fromLTRB(from, y - 1, to, y + 1), Paint()..color = played);
    final tickPaint = Paint()..color = tick;
    for (final tx in ticks) {
      canvas.drawRect(Rect.fromLTWH((tx - 0.5).clamp(0.0, size.width - 1), y + 3, 1, 4), tickPaint);
    }
    final mark = Paint()..color = spot;
    for (final bx in bookmarks) {
      canvas.drawRect(Rect.fromLTWH((bx - 1).clamp(0.0, size.width - 2), y - 9, 2, 8), mark);
    }
    final w = dragging ? 3.0 : 2.0, h = dragging ? 24.0 : 16.0;
    canvas.drawRect(Rect.fromLTWH((x - w / 2).clamp(0.0, size.width - w), y - h / 2, w, h), Paint()..color = played);
  }

  @override
  bool shouldRepaint(_RulerPainter o) =>
      o.x != x ||
      o.dragging != dragging ||
      o.enabled != enabled ||
      o.rtl != rtl ||
      o.ticks.length != ticks.length ||
      o.bookmarks.length != bookmarks.length ||
      o.track != track;
}
