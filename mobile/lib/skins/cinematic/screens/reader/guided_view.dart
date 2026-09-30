import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/features/reader/engine/camera.dart';
import 'package:manhwamaniacs/features/reader/engine/guided.dart';
import 'package:manhwamaniacs/features/reader/engine/page_turn.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_ui_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_names.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/guided_matte.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The folio under the matte: `PANEL 3 / 7 · PAGE 18`, `PAGE 18 · FINDING PANELS` or
/// `PAGE 18 · WHOLE PAGE`.
String guidedFolio({required int page, required int panel, required int panelCount, required bool finding}) {
  if (finding) return 'PAGE $page · FINDING PANELS';
  if (panelCount == 0) return 'PAGE $page · WHOLE PAGE';
  return 'PANEL $panel / $panelCount · PAGE $page';
}

/// The guided view (cinematic 9.4.3): one panel at a time, fitted by the engine camera, the rest
/// of the page dimmed by the guided matte. It publishes the same [ReaderEngineState] the other
/// layouts do, so the chrome above it needs no special case, and it attaches a host so the
/// engine's paging commands (keys, ruler, tap zones) move the camera.
class CineGuidedView extends ConsumerStatefulWidget {
  const CineGuidedView({
    super.key,
    required this.engine,
    required this.chapter,
    required this.rtl,
    required this.ground,
    required this.chromeBuilder,
    required this.initialPage,
    required this.autoAdvance,
    this.onSaveProgress,
    this.onNextChapter,
    this.onPreviousChapter,
    this.creditsBuilder,
    this.autoHideAfter = const Duration(milliseconds: 3000),
  });

  final ReaderEngine engine;
  final ReaderChapter chapter;
  final bool rtl;
  final Color ground;
  final Widget Function(BuildContext context, ReaderEngineState state) chromeBuilder;
  final int initialPage;
  final GuidedAutoAdvance autoAdvance;
  final Future<void> Function(ReaderChapter chapter, int page)? onSaveProgress;
  final VoidCallback? onNextChapter, onPreviousChapter;

  /// The credits page shown whole after the chapter's last panel.
  final WidgetBuilder? creditsBuilder;
  final Duration autoHideAfter;

  @override
  ConsumerState<CineGuidedView> createState() => _CineGuidedViewState();
}

class _Stop {
  const _Stop(this.panel, this.target);
  final int panel; // 0-based panel index (-1 for a whole page)
  final CameraTarget target;
}

class _CineGuidedViewState extends ConsumerState<CineGuidedView> with TickerProviderStateMixin implements ReaderEngineHost {
  late final AnimationController _anim = AnimationController(vsync: this);
  late final AnimationController _hold = AnimationController(vsync: this);
  late TapClassifier _taps;
  ReaderEngine get _engine => widget.engine;
  ReaderCamera get _cam => _engine.camera;
  ReaderChapter get _chapter => widget.chapter;
  int get _pageCount => _chapter.pages.length;

  int _page = 1;
  int _stopIx = 0;
  bool _credits = false;
  bool _glancing = false;
  bool _pinching = false;
  bool _autoRunning = false;
  bool _reduced = false, _accessible = false;
  bool _chromeVisible = true;
  int _glanceGen = 0;
  Timer? _hideTimer, _saveTimer, _singleTap;
  (String, int)? _lastSaved;
  int? _pendingSave;
  final Set<String> _completed = {};
  final Map<int, Size> _learned = {};
  CameraPose _from = CameraPose.identity, _to = CameraPose.identity;
  Curve _curve = Curves.linear;
  ({double scale, Offset focal, CameraPose pose})? _pinch;
  double _dragDx = 0;
  MotionHandle? _motion;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, math.max(1, _pageCount));
    _taps = TapClassifier(doubleTapWindow: const Duration(milliseconds: 300), doubleTapSlop: 24);
    _engine.attach(this);
    _engine.setGuidedActive(true);
    _cam
      ..active = true
      ..pageAspect = _aspectOf;
    _anim.addListener(_onAnim);
    _engine.cameraCommand.addListener(_onCameraCommand);
    _engine.ambient.panels.addListener(_onPanels);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enterPage(_page, last: false, cut: true);
      _publish();
      _scheduleHide();
    });
  }

  @override
  void dispose() {
    _flushSave();
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _singleTap?.cancel();
    _motion?.end(interrupted: true);
    _engine.cameraCommand.removeListener(_onCameraCommand);
    _engine.ambient.panels.removeListener(_onPanels);
    _engine.detach(this);
    _cam.active = false;
    // The engine may already be disposed with the reader; guard the notifier.
    try {
      _engine.setGuidedActive(false);
    } catch (_) {}
    _anim.dispose();
    _hold.dispose();
    super.dispose();
  }

  // ── Geometry ─────────────────────────────────────────────────────────────

  double _aspectOf(int page) {
    final s = _learned[page];
    if (s != null && s.height > 0) return s.width / s.height;
    if (page >= 1 && page <= _pageCount) return _chapter.pages[page - 1].aspectRatio ?? 0.7;
    return 0.7;
  }

  void _learn(int page, int w, int h) {
    if (_learned.containsKey(page) || h == 0) return;
    _learned[page] = Size(w.toDouble(), h.toDouble());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshStops(keepPose: page != _page);
    });
  }

  PanelsState? get _panelsState => _engine.ambient.panelsOf(_page);

  /// The stops of the current page: one per panel, a tall panel walked in 75 % steps.
  List<_Stop> _stops() {
    final st = _panelsState;
    if (st is! PanelsFound || _cam.viewport.isEmpty) return const [];
    final r = _cam.pageRectPx(_page);
    final out = <_Stop>[];
    for (var i = 0; i < st.fractions.length; i++) {
      final f = st.fractions[i];
      final px = Rect.fromLTWH(r.left + f.left * r.width, r.top + f.top * r.height, f.width * r.width, f.height * r.height);
      // A panel taller than the viewport at the scale it is fitted at is walked in steps.
      final fitScale = math.min((_cam.viewport.width - 48) / px.width, 3.0);
      final tall = px.height * fitScale > _cam.viewport.height - 48;
      final steps = tall ? tallPanelSteps(px, Size(_cam.viewport.width / fitScale, _cam.viewport.height / fitScale)) : [px];
      for (final s in steps) {
        out.add(_Stop(
          i,
          CameraTarget(_page, Rect.fromLTWH((s.left - r.left) / r.width, (s.top - r.top) / r.height, s.width / r.width, s.height / r.height)),
        ));
      }
    }
    return out;
  }

  bool get _finding => _panelsState is PanelsFinding || _panelsState == null;

  int get _panelCount => switch (_panelsState) { PanelsFound(:final fractions) => fractions.length, _ => 0 };

  // ── Entering pages and stops ─────────────────────────────────────────────

  void _enterPage(int page, {required bool last, required bool cut}) {
    _page = page.clamp(1, math.max(1, _pageCount));
    _credits = false;
    _stopIx = 0;
    _cam.showWholePage(_page);
    _engine.ambient
      ..pageCount = _pageCount
      ..onPage(_chapter.id, _page);
    if (_panelsState == null || _panelsState is PanelsFinding) {
      unawaited(_engine.ambient.ensurePanels(_chapter.id, _page));
    }
    final stops = _stops();
    if (stops.isNotEmpty) {
      _stopIx = last ? stops.length - 1 : 0;
      _engine.setCamera(stops[_stopIx].target);
    }
    _afterMove();
  }

  void _onPanels() {
    if (!mounted) return;
    _refreshStops(keepPose: false);
  }

  /// Panels landed or a page's size was learned: fit the current stop.
  void _refreshStops({required bool keepPose}) {
    if (_glancing || _pinching || keepPose) {
      setState(() {});
      return;
    }
    final stops = _stops();
    if (stops.isEmpty) {
      _cam.showWholePage(_page);
    } else {
      _stopIx = _stopIx.clamp(0, stops.length - 1);
      _engine.setCamera(stops[_stopIx].target);
    }
    _afterMove();
  }

  void _afterMove() {
    setState(() {});
    _publish();
    _scheduleSave();
    _maybeComplete();
    _restartHold();
  }

  void _maybeComplete() {
    if (_page >= _pageCount && _credits && _completed.add(_chapter.id)) {
      _engine.emitChapterCompleted((sourceId: _chapter.sourceId ?? '', seriesKey: _chapter.seriesId, chapterKey: _chapter.id));
    }
  }

  // ── Moving ───────────────────────────────────────────────────────────────

  /// Next panel: dolly within a page, cut to the next page's first panel, credits after the last.
  void _next({bool byUser = true}) {
    if (byUser) _pauseAuto();
    if (_credits) {
      widget.onNextChapter?.call();
      return;
    }
    final stops = _stops();
    if (stops.isNotEmpty && _stopIx + 1 < stops.length) {
      _stopIx++;
      _dolly(stops[_stopIx].target);
      _feedback(page: false);
    } else if (_page < _pageCount) {
      _feedback(page: true);
      _enterPage(_page + 1, last: false, cut: true);
    } else {
      _feedback(page: true);
      _credits = true;
      _afterMove();
    }
  }

  void _previous({bool byUser = true}) {
    if (byUser) _pauseAuto();
    if (_credits) {
      _credits = false;
      _enterPage(_page, last: true, cut: true);
      return;
    }
    final stops = _stops();
    if (stops.isNotEmpty && _stopIx > 0) {
      _stopIx--;
      _dolly(stops[_stopIx].target);
      _feedback(page: false);
    } else if (_page > 1) {
      _feedback(page: true);
      _enterPage(_page - 1, last: true, cut: true);
    } else {
      widget.onPreviousChapter?.call();
    }
  }

  void _feedback({required bool page}) {
    cineFeedback(context, HapticEvent.pageTurn, sound: page ? SoundEvent.pageTurn : null);
  }

  /// The camera dollies over `durRack` along `CineCurves.turn`; under reduced motion it cuts.
  void _dolly(CameraTarget t) {
    final c = context.cine;
    _engine.setCamera(t, duration: _reduced ? null : c.durRack, curve: CineCurves.turn);
    _afterMove();
  }

  void _onCameraCommand() {
    final cmd = _engine.cameraCommand.value;
    if (cmd == null || !mounted || _cam.viewport.isEmpty) return;
    final to = _cam.poseFor(cmd.rect);
    if (cmd.rect.page != _cam.page || (cmd.duration == null && cmd.spring == null)) {
      _anim.stop();
      _cam.setPose(to, target: cmd.rect, page: cmd.rect.page);
      return;
    }
    _from = _cam.pose;
    _to = to;
    _cam.target = cmd.rect;
    _motion?.end(interrupted: true);
    if (cmd.spring != null) {
      _anim.value = 0;
      _anim.animateWith(SpringSimulation(cmd.spring!, 0, 1, cmd.velocity?.dy ?? 0));
      _motion = CineMotion.track(MotionName.dolly, 400);
    } else {
      final d = cmd.duration!;
      _curve = cmd.curve ?? Curves.linear;
      _motion = CineMotion.track(MotionName.dolly, d.inMilliseconds);
      _anim.duration = d;
      unawaited(_anim.forward(from: 0).orCancel.then((_) => _motion?.end(), onError: (_) {}));
    }
  }

  void _onAnim() {
    final t = _curve.transform(_anim.value.clamp(0.0, 1.0));
    _cam.setPose(CameraPose.lerp(_from, _to, _anim.isAnimating || _anim.isCompleted ? t : 1));
  }

  /// A double tap: the whole page, zoomed out over `durColumn` along `turn`, held `durHoldGlance`,
  /// then back to the panel.
  Future<void> _glance() async {
    if (_glancing) return;
    final c = context.cine;
    final gen = ++_glanceGen;
    _pauseAuto();
    _glancing = true;
    final back = _cam.pose;
    Future<void> go(CameraPose to, Duration d) async {
      _from = _cam.pose;
      _to = to;
      _curve = CineCurves.turn;
      if (_reduced || d == Duration.zero) {
        _cam.setPose(to);
        return;
      }
      _anim.duration = d;
      try {
        await _anim.forward(from: 0).orCancel;
      } on TickerCanceled {
        // retargeted
      }
    }

    await go(CameraPose.identity, _reduced ? Duration.zero : c.durColumn);
    if (gen != _glanceGen || !mounted) return;
    await Future<void>.delayed(c.durHoldGlance);
    if (gen != _glanceGen || !mounted) return;
    await go(back, _reduced ? Duration.zero : c.durColumn);
    if (gen == _glanceGen) _glancing = false;
  }

  // ── Auto-advance ─────────────────────────────────────────────────────────

  bool get _autoAllowedByItself => widget.autoAdvance.on && !_reduced && !_accessible;

  void _pauseAuto() {
    if (_autoRunning && !_engine.autoScroll.userPaused) _engine.autoScroll.togglePause();
    _hold.stop();
    setState(() {});
  }

  void _restartHold() {
    _hold.stop();
    if (!_autoRunning || _engine.autoScroll.userPaused || _credits) return;
    final stops = _stops();
    final panel = stops.isEmpty ? -1 : stops[_stopIx.clamp(0, stops.length - 1)].panel;
    final words = panel < 0 ? null : _engine.wordsInPanel(_page, panel);
    final mode = widget.autoAdvance.mode == 'FIXED' ? GuidedHoldMode.fixed : GuidedHoldMode.paceByWords;
    final ms = panelHoldMs(words, mode, widget.autoAdvance.fixedMs);
    _hold.duration = Duration(milliseconds: ms);
    unawaited(_hold.forward(from: 0).orCancel.then((_) {
      if (mounted && _autoRunning && !_engine.autoScroll.userPaused) _next(byUser: false);
    }, onError: (_) {}));
  }

  // ── Save and publish ─────────────────────────────────────────────────────

  void _scheduleSave() {
    if (widget.onSaveProgress == null) return;
    _pendingSave = _page;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _flushSave);
  }

  void _flushSave() {
    final save = widget.onSaveProgress;
    final page = _pendingSave;
    if (save == null || page == null) return;
    _pendingSave = null;
    if (_lastSaved == (_chapter.id, page)) return;
    _lastSaved = (_chapter.id, page);
    unawaited(save(_chapter, page));
  }

  void _publish() {
    if (!mounted) return;
    final ui = ref.read(readerUiProvider);
    _engine.value = ReaderEngineState(
      chapterId: _chapter.id,
      chapterTitle: _chapter.title,
      chapterIndex: 0,
      page: _page,
      pageCount: _pageCount,
      progress: ReaderEngineState.quantiseProgress(_credits ? 1 : _page / math.max(1, _pageCount)),
      atStart: _page == 1 && _stopIx == 0,
      atEnd: _credits,
      hasPrevious: widget.onPreviousChapter != null,
      hasNext: widget.onNextChapter != null,
      loadedChapterIds: [_chapter.id],
      nextState: widget.onNextChapter != null ? ReaderNextState.ready : ReaderNextState.none,
      bookmarks: const [],
      zoom: 1,
      autoScrolling: _autoRunning,
      autoScrollSpeed: ui.autoScrollSpeed,
      chromeVisible: _chromeVisible,
      locked: ui.isLocked,
      guidedActive: true,
    );
  }

  void _showChrome() {
    _chromeVisible = true;
    _publish();
    _scheduleHide();
  }

  void _hideChrome() {
    _chromeVisible = false;
    _hideTimer?.cancel();
    _publish();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.autoHideAfter, () {
      if (mounted && !_accessible) _hideChrome();
    });
  }

  // ── Gestures ─────────────────────────────────────────────────────────────

  void _onTapUp(Offset pos, Size size) {
    final kind = _taps.classify(pos, DateTime.now());
    if (kind == TapKind.double) {
      _singleTap?.cancel();
      unawaited(_glance());
      return;
    }
    _singleTap?.cancel();
    _singleTap = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final f = pos.dx / size.width;
      final forwardSide = widget.rtl ? f < 0.3 : f > 0.7;
      final backSide = widget.rtl ? f > 0.7 : f < 0.3;
      if (forwardSide) {
        _next();
      } else if (backSide) {
        _previous();
      } else {
        _pauseAuto();
        _chromeVisible ? _hideChrome() : _showChrome();
      }
    });
  }

  void _scaleStart(ScaleStartDetails d) {
    _dragDx = 0;
    _pinch = null;
    if (d.pointerCount >= 2) {
      _pinching = true;
      _pinch = (scale: _cam.pose.scale, focal: d.localFocalPoint, pose: _cam.pose);
      _anim.stop();
    }
  }

  void _scaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2 || _pinching) {
      final p = _pinch ?? (scale: _cam.pose.scale, focal: d.localFocalPoint, pose: _cam.pose);
      _pinch = p;
      _pinching = true;
      final s = (p.pose.scale * d.scale).clamp(0.8, 4.0);
      final k = s / p.pose.scale;
      final focal = p.focal;
      // The content point under the focal stays under the fingers while the scale follows.
      final dx = d.localFocalPoint.dx - (focal.dx - p.pose.dx) * k;
      final dy = d.localFocalPoint.dy - (focal.dy - p.pose.dy) * k;
      _cam.setPose(CameraPose(s, dx, dy));
    } else {
      _dragDx += d.focalPointDelta.dx;
    }
  }

  void _scaleEnd(ScaleEndDetails d) {
    if (_pinching) {
      _pinching = false;
      _pinch = null;
      // A pinch overrides the camera until released; then it dollies back to the current panel.
      final stops = _stops();
      final t = stops.isEmpty ? null : stops[_stopIx.clamp(0, stops.length - 1)].target;
      final c = context.cine;
      if (t != null) {
        _engine.setCamera(t, duration: _reduced ? null : c.durRack, curve: CineCurves.turn);
      } else {
        _cam.showWholePage(_page);
      }
      return;
    }
    final vx = d.velocity.pixelsPerSecond.dx;
    if (_dragDx.abs() >= 72 || vx.abs() >= 600) {
      final left = _dragDx < 0 || (_dragDx == 0 && vx < 0);
      // A left swipe goes forward; right-to-left series mirror it.
      final forward = widget.rtl ? !left : left;
      forward ? _next() : _previous();
    }
    _dragDx = 0;
  }

  // ── ReaderEngineHost ─────────────────────────────────────────────────────

  @override
  bool get bookmarkPending => false;
  @override
  void reportServerProgress({required String chapterKey, required double? chapterNumber, required int lastPage, required bool advanced}) {}
  @override
  void seekToPage(int page) => jumpToPage(page);
  @override
  void pageBy({required bool forward}) => forward ? _next() : _previous();
  @override
  void nextChapter() => widget.onNextChapter?.call();
  @override
  void previousChapter() => widget.onPreviousChapter?.call();
  @override
  void toggleAutoScroll() {
    // Started by hand it moves even under reduced motion (by cuts) and with a screen reader.
    if (_autoRunning && !_engine.autoScroll.userPaused) {
      _autoRunning = false;
      _hold.stop();
    } else {
      _autoRunning = true;
      if (_engine.autoScroll.userPaused) _engine.autoScroll.togglePause();
      _restartHold();
    }
    _publish();
    setState(() {});
  }

  @override
  void setAutoScrollSpeed(double pxPerSecond) {}
  @override
  void setAutoScrollSpeedX(double speedX) {}
  @override
  void zoomIn() {}
  @override
  void zoomOut() {}
  @override
  void resetZoom() {}
  @override
  void toggleDoubleTapZoom() => unawaited(_glance());
  @override
  Future<bool> bookmark() async => false;
  @override
  void showChrome() => _showChrome();
  @override
  void hideChrome() => _hideChrome();
  @override
  void holdChrome() => _hideTimer?.cancel();
  @override
  void scheduleHideChrome() => _scheduleHide();
  @override
  void pinchZoom(Offset focal, double scale, double velocity, {required double min, required double max, double? snapStep, bool rubberBand = true, bool released = false}) {}
  @override
  void zoomAt(Offset point, double scale, {required Duration duration, required Curve curve, SpringDescription? spring}) {}
  @override
  void jumpToPage(int page, {bool glide = false}) {
    _pauseAuto();
    _enterPage(page, last: false, cut: true);
  }

  @override
  void scrollByViewport(double fraction, {required Duration duration, required Curve curve}) => fraction >= 0 ? _next() : _previous();
  @override
  void seekToChapter(int chapterIndex) {}
  @override
  void turnTo(int page, {PageTurn kind = PageTurn.cut, required Duration slideDuration, required Curve slideCurve, required Duration fadeDuration}) =>
      jumpToPage(page);
  @override
  int pageAtReadingLine() => _page;

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _reduced = CineMotion.reduced(context);
    _accessible = MediaQuery.accessibleNavigationOf(context);
    final c = context.cine;
    final autoOn = _autoAllowedByItself;
    if (autoOn && !_autoRunning && !_autoStarted) {
      _autoStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_autoRunning) toggleAutoScroll();
      });
    }
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        if (_cam.viewport != size) {
          _cam.viewport = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _refreshStops(keepPose: false);
          });
        }
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: widget.ground)),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _onTapUp(d.localPosition, size),
                onScaleStart: _scaleStart,
                onScaleUpdate: _scaleUpdate,
                onScaleEnd: _scaleEnd,
                child: _credits && widget.creditsBuilder != null
                    ? widget.creditsBuilder!(context)
                    : ListenableBuilder(listenable: _cam, builder: (context, _) => _stage(context, size, c)),
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder<ReaderEngineState>(
                valueListenable: _engine,
                builder: (context, state, _) => widget.chromeBuilder(context, state),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _autoStarted = false;

  Widget _stage(BuildContext context, Size size, CineTokens c) {
    final rect = _cam.pageRectPx(_page);
    final stops = _stops();
    final showPanel = stops.isNotEmpty && !_glancing && _cam.target != null;
    Rect? panelPx;
    if (showPanel) {
      final f = stops[_stopIx.clamp(0, stops.length - 1)].target.fraction;
      final a = _cam.pageToViewport(_page, f.left, f.top);
      final b = _cam.pageToViewport(_page, f.right, f.bottom);
      panelPx = Rect.fromPoints(a, b);
    }
    return Stack(
      children: [
        Positioned.fill(
          child: Transform(
            transform: _cam.pose.toMatrix(),
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: rect,
                  child: _PageImage(
                    key: ValueKey('guided-page-$_page'),
                    chapter: _chapter,
                    page: _page,
                    provider: _engine.ambient.resolver?.call(_chapter.id, _page),
                    onSize: (w, h) => _learn(_page, w, h),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(child: GuidedMatte(panel: panelPx, color: c.colorMatteGuided)),
        _folio(context, c),
      ],
    );
  }

  Widget _folio(BuildContext context, CineTokens c) {
    final stops = _stops();
    final panel = stops.isEmpty ? 0 : stops[_stopIx.clamp(0, stops.length - 1)].panel + 1;
    final text = guidedFolio(page: _page, panel: panel, panelCount: _panelCount, finding: _finding);
    final pad = MediaQuery.viewPaddingOf(context);
    final bottom = 16 + pad.bottom + (_chromeVisible ? 64 : 0);
    return Positioned(
      left: 16 + pad.left,
      bottom: bottom,
      right: 96,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Semantics(
            liveRegion: true,
            label: _panelCount == 0 ? 'Page $_page' : 'Panel $panel of $_panelCount, page $_page',
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorInk100)),
                  child: CineRoleText(text, c.typeFolio, color: c.colorInk100),
                ),
                if (_autoRunning && !_engine.autoScroll.userPaused)
                  AnimatedBuilder(
                    animation: _hold,
                    builder: (context, _) => Container(
                      key: const Key('guided-hold-rule'),
                      height: 2,
                      width: 120 * _hold.value,
                      color: c.colorSpot,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page image, reporting its decoded size so the camera knows the page's shape.
class _PageImage extends StatefulWidget {
  const _PageImage({super.key, required this.chapter, required this.page, required this.onSize, this.provider});
  final ReaderChapter chapter;
  final int page;
  final ImageProvider? provider;
  final void Function(int w, int h) onSize;

  @override
  State<_PageImage> createState() => _PageImageState();
}

class _PageImageState extends State<_PageImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  void _resolve() {
    final p = widget.chapter.pages[widget.page - 1];
    final ImageProvider provider = widget.provider ?? (p.localFile != null ? FileImage(p.localFile!) : NetworkImage(p.imageUrl));
    final next = provider.resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener!);
    _listener = ImageStreamListener((info, _) {
      widget.onSize(info.image.width, info.image.height);
      if (mounted) setState(() => _image = info.image);
    });
    _stream = next..addListener(_listener!);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _image == null
      ? const SizedBox.expand()
      : RawImage(image: _image, fit: BoxFit.fill, filterQuality: FilterQuality.medium);
}
