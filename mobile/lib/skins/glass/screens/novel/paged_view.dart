import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/lift_turn.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/page_turn.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The turning page's moving-edge shadow (G4): blur 8, black at 0.45 x progress.
const double kSlideShadowBlur = 8, kSlideShadowAlpha = 0.45;

/// The Fade turn (G6): 160 ms.
const Duration kFadeTurn = Duration(milliseconds: 160);

/// Paged reading (G2, G4-G6): a `PageView.builder` of [count] pages (the text pages plus the end-matter page) turned by Slide
/// ([GlassPagePhysics], the edge shadow), Lift (a drag layer over a frozen `PageView`, the [LiftingPage] copy) or Fade (a 160 ms
/// cross-fade). Reduce Motion is always Fade.
class NovelPagedView extends StatefulWidget {
  const NovelPagedView({
    super.key,
    required this.count,
    required this.builder,
    required this.turn,
    required this.reduced,
    required this.paper,
    required this.onPage,
    this.initialPage = 0,
  });

  final int count;
  /// Builds page [index]; [ghost] copies (the lifting and fading ones) carry no keys.
  final Widget Function(BuildContext context, int index, bool ghost) builder;
  final GlassPageTurn turn;
  final bool reduced;
  final Color paper;
  final ValueChanged<int> onPage;
  final int initialPage;

  @override
  State<NovelPagedView> createState() => NovelPagedViewState();
}

class NovelPagedViewState extends State<NovelPagedView> with TickerProviderStateMixin {
  late final PageController _pages = PageController(initialPage: widget.initialPage);
  late final AnimationController _lift;
  late final AnimationController _fade;
  int _page = 0;
  int? _liftPage; // the page drawn as the turning copy
  bool _liftForward = true;
  int _liftFrom = 0, _liftTo = 0;
  double _dragPx = 0;
  int? _fadeFrom;

  GlassPageTurn get _turn => widget.reduced ? GlassPageTurn.fade : widget.turn;

  /// The page on screen.
  int get page => _page;

  @override
  void initState() {
    super.initState();
    _lift = AnimationController(vsync: this);
    _fade = AnimationController(vsync: this, duration: kFadeTurn, value: 1);
    _page = widget.initialPage;
  }

  @override
  void dispose() {
    _pages.dispose();
    _lift.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _landed(int p) {
    if (p == _page) return;
    _page = p;
    widget.onPage(p);
  }

  /// Turns by [delta] pages with the chosen turn (taps and keys: Slide with the spring from rest).
  Future<void> turnBy(int delta) async {
    final to = (_page + delta).clamp(0, widget.count - 1);
    if (to == _page) return;
    switch (_turn) {
      case GlassPageTurn.slide:
        final entry = GlassMotion.recorder.begin(MotionName.pageSlide.label, 615);
        await _pages.animateToPage(to, duration: const Duration(milliseconds: 615), curve: SpringCurve(glassTokens.springPage, settleMs: 615));
        GlassMotion.recorder.end(entry);
      case GlassPageTurn.lift:
        _startLift(forward: delta > 0);
        await _settleLift(commit: true);
      case GlassPageTurn.fade:
        await _fadeTo(to);
    }
  }

  /// Jumps without a turn (restore, Home / End, a re-pagination).
  void jumpTo(int page) {
    final to = page.clamp(0, widget.count - 1);
    if (_pages.hasClients) _pages.jumpToPage(to);
    _landed(to);
  }

  Future<void> _fadeTo(int to) async {
    setState(() => _fadeFrom = _page);
    _pages.jumpToPage(to);
    _landed(to);
    final entry = GlassMotion.recorder.begin(MotionName.pageSlide.label, kFadeTurn.inMilliseconds);
    await _fade.forward(from: 0);
    GlassMotion.recorder.end(entry);
    if (mounted) setState(() => _fadeFrom = null);
  }

  // -- Lift -----------------------------------------------------------------

  void _startLift({required bool forward}) {
    final from = _page;
    final target = forward ? from + 1 : from - 1;
    if (target < 0 || target >= widget.count) return;
    _liftForward = forward;
    _liftFrom = from;
    _liftTo = target;
    // Forward: page n lifts off page n + 1 (already live beneath). Backward: page n - 1 rotates in from -100 degrees over page n.
    _liftPage = forward ? from : target;
    _lift.value = forward ? 0 : 1;
    if (forward) _pages.jumpToPage(target);
    setState(() {});
  }

  Future<void> _settleLift({required bool commit, double velocity = 0}) async {
    if (_liftPage == null) return;
    final width = context.size?.width ?? 1;
    final forward = _liftForward;
    // Forward: commit lifts to 1; backward: commit lays the page down (0).
    final target = commit ? (forward ? 1.0 : 0.0) : (forward ? 0.0 : 1.0);
    final e = GlassMotion.recorder.begin(MotionName.pageLift.label, 615);
    await _lift.animateWith(SpringSimulation(springOf(glassTokens.springPage), _lift.value, target, velocity / width)).orCancel.catchError((Object _) {});
    GlassMotion.recorder.end(e);
    if (!mounted) return;
    if (commit) {
      if (!forward) _pages.jumpToPage(_liftTo);
      _landed(_liftTo);
    } else if (forward) {
      _pages.jumpToPage(_liftFrom);
    }
    setState(() => _liftPage = null);
  }

  void _liftDragStart(DragStartDetails d) => _dragPx = 0;

  void _liftDragUpdate(DragUpdateDetails d) {
    final width = context.size?.width ?? 1;
    _dragPx += d.delta.dx;
    if (_liftPage == null) {
      if (_dragPx.abs() < 4) return;
      _startLift(forward: _dragPx < 0);
      if (_liftPage == null) return;
    }
    final progress = (_dragPx.abs() / width).clamp(0.0, 1.0);
    _lift.value = _liftForward ? progress : 1 - progress;
  }

  void _liftDragEnd(DragEndDetails d) {
    if (_liftPage == null) return;
    final width = context.size?.width ?? 1;
    final v = d.velocity.pixelsPerSecond.dx;
    final commit = liftCommits(_dragPx.abs(), _liftForward ? -v : v, width);
    unawaited(_settleLift(commit: commit, velocity: _liftForward ? -v : v));
  }

  // -- Fade drag ------------------------------------------------------------

  void _fadeDragEnd(DragEndDetails d) {
    final width = context.size?.width ?? 1;
    final v = d.velocity.pixelsPerSecond.dx;
    if (liftCommits(_dragPx.abs(), v.abs(), width) || v.abs() > 600) {
      unawaited(turnBy(_dragPx < 0 || v < -600 ? 1 : -1));
    }
  }

  Widget _edgeShadow(int i, Widget child) => AnimatedBuilder(
        animation: _pages,
        child: child,
        builder: (context, child) {
          final p = _pages.hasClients && _pages.position.haveDimensions ? (_pages.page ?? _page.toDouble()) : _page.toDouble();
          final progress = (p - i).clamp(0.0, 1.0);
          return DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              boxShadow: progress <= 0 || progress >= 1 ? const [] : [BoxShadow(blurRadius: kSlideShadowBlur, color: Color.fromRGBO(0, 0, 0, kSlideShadowAlpha * progress), offset: const Offset(4, 0))],
            ),
            child: ColoredBox(color: widget.paper, child: child),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final turn = _turn;
    final view = PageView.builder(
      controller: _pages,
      physics: turn == GlassPageTurn.slide ? const GlassPagePhysics() : const NeverScrollableScrollPhysics(),
      itemCount: widget.count,
      onPageChanged: (p) {
        if (_liftPage == null && _fadeFrom == null) _landed(p);
      },
      itemBuilder: (context, i) => turn == GlassPageTurn.slide ? _edgeShadow(i, widget.builder(context, i, false)) : widget.builder(context, i, false),
    );
    if (turn == GlassPageTurn.slide) return view;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _liftDragStart,
      onHorizontalDragUpdate: turn == GlassPageTurn.lift ? _liftDragUpdate : (d) => _dragPx += d.delta.dx,
      onHorizontalDragEnd: turn == GlassPageTurn.lift ? _liftDragEnd : _fadeDragEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (turn == GlassPageTurn.lift)
            AnimatedBuilder(
              animation: _lift,
              child: view,
              builder: (context, child) => _liftPage == null
                  ? child!
                  : ColorFiltered(colorFilter: liftDim(kLiftDimFrom + (1 - kLiftDimFrom) * _lift.value.clamp(0.0, 1.0)), child: child),
            )
          else
            view,
          if (_liftPage != null)
            AnimatedBuilder(
              animation: _lift,
              builder: (context, _) => LiftingPage(progress: _lift.value, paper: widget.paper, child: widget.builder(context, _liftPage!, true)),
            ),
          if (_fadeFrom != null)
            IgnorePointer(
              child: ExcludeSemantics(
                child: SelectionContainer.disabled(
                  child: FadeTransition(opacity: ReverseAnimation(_fade), child: ColoredBox(color: widget.paper, child: widget.builder(context, _fadeFrom!, true))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
