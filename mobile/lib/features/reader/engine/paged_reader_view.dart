import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/core/platform/native_bridge.dart';
import 'package:manhwamaniacs/core/utils/haptics.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/page_turn.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_zoom.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_options.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_provider.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_layout.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_page_image.dart';
import 'package:manhwamaniacs/features/reader/engine/spread.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_ui_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_anchor.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_display_mode.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_image_cache.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';


/// The paged stage's measures (cinematic 8.14.7): a 24 px inset in total (12 px each side), an
/// 8 px gutter between the pages of a spread with a 1 px centre line.
class PagedStageStyle {
  const PagedStageStyle({this.inset = 12, this.gutter = 8, this.centreLine = const Color(0x1FFFFFFF)});
  final double inset, gutter;
  final Color centreLine;
}

/// The paged twin of `ReaderEngineView` (glass 15.4 `setLayout(single | double)`): one chapter as
/// a `PageView` of screens (a page or a spread), with the page-turn hook, finger physics from the
/// skin, per-page zoom, the credits screen after the last page and the next chapter after that.
/// It publishes the same [ReaderEngineState] and takes the same commands, so a chrome cannot tell
/// the two apart. It holds no skin value: every colour, duration and physics is a parameter.
class PagedReaderView extends ConsumerStatefulWidget {
  const PagedReaderView({
    super.key,
    required this.controller,
    required this.chapter,
    required this.spec,
    required this.chromeBuilder,
    required this.autoHideAfter,
    this.style = const PagedStageStyle(),
    this.fit = ReaderPageFit.height,
    this.ground = Colors.black,
    this.turn = PageTurn.cut,
    this.slideDuration = const Duration(milliseconds: 280),
    this.slideCurve = Curves.easeOutCubic,
    this.fadeDuration = const Duration(milliseconds: 160),
    this.reducedMotion = false,
    this.reducedDuration = const Duration(milliseconds: 150),
    this.initialPage = 1,
    this.onEvent,
    this.bookmarkAnchors = const {},
    this.onSaveProgress,
    this.onAddBookmark,
    this.onPreviousChapter,
    this.onNextChapter,
    this.options = const ReaderEngineOptions(),
    this.creditsNextChapterId,
  });

  final ReaderEngine controller;
  final ReaderChapter chapter;
  final ReaderLayoutSpec spec;
  final Widget Function(BuildContext context, ReaderEngineState state) chromeBuilder;
  final Duration autoHideAfter;
  final PagedStageStyle style;
  final ReaderPageFit fit;
  final Color ground;
  final PageTurn turn;
  final Duration slideDuration, fadeDuration, reducedDuration;
  final Curve slideCurve;
  final bool reducedMotion;
  final int initialPage;
  final ValueChanged<ReaderEngineEvent>? onEvent;
  final Map<String, List<ReaderAnchor>> bookmarkAnchors;
  final Future<void> Function(ReaderChapter chapter, int page)? onSaveProgress;
  final Future<bool> Function(ReaderChapter chapter, ReaderAnchor anchor)? onAddBookmark;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final ReaderEngineOptions options;

  /// The chapter id the credits screen offers next; null falls back to the chapter's own.
  final String? creditsNextChapterId;

  @override
  ConsumerState<PagedReaderView> createState() => _PagedReaderViewState();
}

class _PagedReaderViewState extends ConsumerState<PagedReaderView> with TickerProviderStateMixin, WidgetsBindingObserver implements ReaderEngineHost {
  late PageController _pc;
  late List<PageView1> _views;
  final Map<int, Size> _learned = {};
  int _view = 0;
  Offset _pan = Offset.zero;
  Size _stage = Size.zero;
  Timer? _hideTimer, _saveTimer;
  (String, int)? _lastSaved;
  int? _pendingSave;
  final Set<String> _completed = {};
  final Map<String, List<ReaderAnchor>> _saved = {};
  bool _bookmarkPending = false;
  FurtherElsewhere? _further;
  AnimationController? _zoomAnim, _fade;
  int? _fadeTarget;
  bool _fadeJumped = false;
  bool _pinching = false;
  bool _sentinelFired = false;

  // Raw pointers: pinch, pan, taps, long press.
  final Map<int, Offset> _pointers = {};
  ({double distance, double zoom})? _pinchStart;
  Offset _pinchFocal = Offset.zero;
  ({Offset position, DateTime at})? _tapDown;
  late TapClassifier _classifier = _newClassifier();
  Timer? _longPress;
  Offset? _longPressStart;
  Offset? _dragStart;
  double _dragDx = 0;
  DateTime _dragStartAt = DateTime.now();

  // Native services.
  StreamSubscription<VolumeKeyDirection>? _volumeSub;
  bool _volumeOn = false, _wakelockOn = false;
  ReaderRefreshRate? _rate;
  ReaderWakelock? _wakelock;
  ReaderDisplayMode? _displayMode;
  NativeBridge? _bridge;

  ReaderChapter get _chapter => widget.chapter;
  ReaderLayoutSpec get _spec => widget.spec;
  bool get _double => _spec.layout == ReaderLayout.double;
  bool get _rtl => _spec.rtl;
  int get _pageCount => math.max(1, _chapter.pages.length);
  bool get _hasNext => widget.onNextChapter != null;
  int get _creditsIndex => _views.length;
  Haptics get _haptics => ref.read(hapticsProvider);
  double get _zoom => ref.read(readerUiProvider).zoomLevel.clamp(kPagedZoomMin, kPagedZoomMax);

  TapClassifier _newClassifier() => TapClassifier(doubleTapWindow: widget.options.doubleTapWindow, doubleTapSlop: widget.options.doubleTapSlop);

  bool _isWide(int page) {
    final p = page >= 1 && page <= _chapter.pages.length ? _chapter.pages[page - 1] : null;
    final s = _learned[page];
    if (s != null) return s.width > s.height;
    return p?.width != null && p?.height != null && p!.width! > p.height!;
  }

  List<PageView1> _computeViews() {
    final n = _chapter.pages.length;
    return _double ? buildSpreads(n, isWide: _isWide) : buildSingles(n);
  }

  int _viewIndexOfPage(int page) => findViewIndex(_views, page);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wakelock ??= ref.read(readerWakelockProvider);
    _displayMode ??= ref.read(readerDisplayModeProvider);
    _bridge ??= ref.read(nativeBridgeProvider);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
    if (widget.options.lifecycleVolumeKeys) WidgetsBinding.instance.addObserver(this);
    _views = _computeViews();
    _view = _viewIndexOfPage(widget.initialPage.clamp(1, _pageCount));
    _pc = PageController(initialPage: _view);
    _publish();
    unawaited(tuneReaderImageCache(ref.read(nativeBridgeProvider)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final d = ref.read(readerDefaultsProvider);
      unawaited(_syncWakelock(d.keepScreenAwake));
      _syncRate(d.refreshRate);
      unawaited(_syncVolume(d.volumeKeyNavigation));
      if (d.lockControls) ref.read(readerUiProvider.notifier).setLocked(true);
      // The resting zoom of a paged page is 1x; a series' strip zoom below or above it does not carry over.
      ref.read(readerUiProvider.notifier).setZoom(1);
      _scheduleHide();
      _prefetch();
      _publish();
    });
  }

  @override
  void didUpdateWidget(covariant PagedReaderView old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.detach(this);
      widget.controller.attach(this);
    }
    if (old.options.doubleTapWindow != widget.options.doubleTapWindow || old.options.doubleTapSlop != widget.options.doubleTapSlop) {
      _classifier = _newClassifier();
    }
    if (old.spec.layout != widget.spec.layout || old.chapter != widget.chapter) _relayout();
    _publish();
  }

  /// Recompute the views and stay on the page being read (a layout switch keeps the page).
  void _relayout() {
    final lead = _leadPage;
    final onCredits = _view >= _views.length;
    _views = _computeViews();
    _view = onCredits ? _views.length : _viewIndexOfPage(lead);
    final old = _pc;
    _pc = PageController(initialPage: _view);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.options.lifecycleVolumeKeys) return;
    unawaited(_syncVolume(state == AppLifecycleState.resumed && ref.read(readerDefaultsProvider).volumeKeyNavigation));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelLongPress();
    _zoomAnim?.dispose();
    _fade?.dispose();
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _flushSave();
    unawaited(_releaseWakelock());
    unawaited(_displayMode?.reset());
    unawaited(_syncVolume(false));
    unawaited(_volumeSub?.cancel());
    _pc.dispose();
    widget.controller.detach(this);
    super.dispose();
  }

  // ── Native services (the same rules as the strip) ─────────────────────────

  Future<void> _syncWakelock(bool on) async {
    if (on && !_wakelockOn) {
      await _wakelock?.enable();
      _wakelockOn = true;
    } else if (!on) {
      await _releaseWakelock();
    }
  }

  Future<void> _releaseWakelock() async {
    if (!_wakelockOn) return;
    await _wakelock?.disable();
    _wakelockOn = false;
  }

  void _syncRate(ReaderRefreshRate rate) {
    if (_rate == rate) return;
    _rate = rate;
    unawaited(_displayMode?.apply(rate));
  }

  Future<void> _syncVolume(bool on) async {
    if (on && widget.options.lifecycleVolumeKeys && (!mounted || Theme.of(context).platform != TargetPlatform.android)) return;
    if (on == _volumeOn) return;
    _volumeOn = on;
    final bridge = _bridge;
    if (bridge == null) return;
    if (on) {
      _volumeSub ??= bridge.volumeKeyEvents.listen(_onVolume);
      await bridge.setVolumeKeyNavEnabled(true);
    } else {
      await bridge.setVolumeKeyNavEnabled(false);
      await _volumeSub?.cancel();
      _volumeSub = null;
    }
  }

  void _onVolume(VolumeKeyDirection d) {
    if (!mounted) return;
    // K08: down turns forward, up back, by reading direction, with the chosen page turn.
    _haptics.selection();
    _step(forward: d == VolumeKeyDirection.down, kind: widget.turn);
  }

  // ── Position ──────────────────────────────────────────────────────────────

  int get _leadPage => _view >= _creditsIndex || _views.isEmpty ? _pageCount : viewLeadPage(_views[_view.clamp(0, _views.length - 1)]);
  int get _progressPage => _view >= _creditsIndex || _views.isEmpty ? _pageCount : viewProgressPage(_views[_view], _pageCount);

  void _onPageChanged(int index) {
    if (index == _view) return;
    final swiped = _fade == null || !(_fade!.isAnimating);
    _view = index;
    if (_zoom > 1) _resetZoom();
    if (widget.options.autoHide != null && ref.read(readerUiProvider).controlsVisible) _hideControls();
    if (index > _creditsIndex) {
      // Past the credits: the next chapter opens (by the skin's Dip).
      if (!_sentinelFired && _hasNext) {
        _sentinelFired = true;
        _haptics.selection();
        widget.onNextChapter!();
      }
    } else {
      _sentinelFired = false;
      _scheduleSave();
      _maybeComplete();
      _prefetch();
    }
    if (swiped && !_programmatic) widget.onEvent?.call(ReaderPageSwiped(page: _leadPage));
    _publish();
  }

  bool _programmatic = false;

  /// The last screen (or the credits) reached completes the chapter, once per open.
  void _maybeComplete() {
    if (_view >= _views.length - 1 && _completed.add(_chapter.id)) {
      widget.controller.emitChapterCompleted((sourceId: _chapter.sourceId ?? '', seriesKey: _chapter.seriesId, chapterKey: _chapter.id));
    }
  }

  void _scheduleSave() {
    if (widget.onSaveProgress == null) return;
    _pendingSave = _progressPage;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _flushSave);
  }

  void _flushSave() {
    final save = widget.onSaveProgress;
    final page = _pendingSave;
    if (save == null || page == null) return;
    _pendingSave = null;
    if (page <= 0 || _lastSaved == (_chapter.id, page)) return;
    _lastSaved = (_chapter.id, page);
    unawaited(save(_chapter, page));
  }

  void _prefetch() {
    if (!mounted) return;
    final from = _view.clamp(0, math.max(0, _views.length - 1)).toInt();
    final decodeWidth = readerDecodeWidth(_stage.width == 0 ? null : _stage.width, MediaQuery.devicePixelRatioOf(context));
    final headers = apiImageHttpHeaders(ref.read(authTokenStoreProvider).token, profileId: ref.read(activeProfileProvider)?.id);
    // The visible view and the three after it (cinematic 8.14.7: preload 3 pages ahead).
    for (var v = from; v < math.min(_views.length, from + 4); v++) {
      for (final n in _views[v]) {
        if (n < 1 || n > _chapter.pages.length) continue;
        final page = _chapter.pages[n - 1];
        if (page.localFile == null && page.imageUrl.isEmpty) continue;
        final provider = ResizeImage.resizeIfNeeded(
          decodeWidth,
          null,
          page.localFile != null ? FileImage(page.localFile!) as ImageProvider : CachedNetworkImageProvider(page.imageUrl, headers: headers),
        );
        precacheImage(provider, context, onError: (_, __) {});
      }
    }
  }

  // ── Chrome state ──────────────────────────────────────────────────────────

  List<ReaderAnchor> _bookmarks() {
    final given = widget.bookmarkAnchors[_chapter.id] ?? const [];
    final saved = _saved[_chapter.id] ?? const [];
    return List.unmodifiable([...given, ...saved]);
  }

  void _publish() {
    final ui = ref.read(readerUiProvider);
    final page = _leadPage;
    widget.controller.value = ReaderEngineState(
      chapterId: _chapter.id,
      chapterTitle: _chapter.title,
      chapterIndex: 0,
      page: page,
      pageCount: _chapter.pages.length,
      progress: ReaderEngineState.quantiseProgress(_view >= _creditsIndex ? 1 : (_progressPage) / _pageCount),
      atStart: _view == 0,
      atEnd: _view >= _creditsIndex,
      hasPrevious: widget.onPreviousChapter != null,
      hasNext: widget.onNextChapter != null,
      loadedChapterIds: [_chapter.id],
      nextState: _hasNext ? ReaderNextState.ready : ReaderNextState.none,
      bookmarks: _bookmarks(),
      zoom: _zoom,
      autoScrolling: false,
      autoScrollSpeed: ui.autoScrollSpeed,
      chromeVisible: ui.controlsVisible,
      locked: ui.isLocked,
      furtherElsewhere: _further,
    );
  }

  // ── Chrome visibility ─────────────────────────────────────────────────────

  void _showControls() {
    ref.read(readerUiProvider.notifier).setControlsVisible(true);
    _scheduleHide();
    _publish();
  }

  void _hideControls() {
    ref.read(readerUiProvider.notifier).setControlsVisible(false);
    _hideTimer?.cancel();
    _publish();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.autoHideAfter, () {
      if (mounted) {
        ref.read(readerUiProvider.notifier).setControlsVisible(false);
        _publish();
      }
    });
  }

  // ── Turning ───────────────────────────────────────────────────────────────

  /// The view a step of [forward] from the current one lands on, in view indices (credits included).
  int _targetView({required bool forward}) => (_view + (forward ? 1 : -1)).clamp(0, _creditsIndex + (_hasNext ? 1 : 0));

  void _step({required bool forward, required PageTurn kind}) {
    final t = _targetView(forward: forward);
    if (t == _view) return;
    _goToView(t, kind);
  }

  void _goToView(int target, PageTurn kind, {Duration? slide, Curve? curve, Duration? fade}) {
    if (!_pc.hasClients) return;
    _programmatic = true;
    if (widget.reducedMotion) {
      _fadeTo(target, widget.reducedDuration);
      return;
    }
    switch (kind) {
      case PageTurn.cut:
        _pc.jumpToPage(target);
        _programmatic = false;
      case PageTurn.slide:
        unawaited(_pc.animateToPage(target, duration: slide ?? widget.slideDuration, curve: curve ?? widget.slideCurve).whenComplete(() => _programmatic = false));
      case PageTurn.fade:
        _fadeTo(target, fade ?? widget.fadeDuration);
    }
  }

  /// A cross-fade through the ground: out over the first half, the jump, in over the second.
  void _fadeTo(int target, Duration total) {
    _fade?.dispose();
    final c = AnimationController(vsync: this, duration: total);
    _fade = c;
    _fadeTarget = target;
    _fadeJumped = false;
    c.addListener(() {
      if (!_fadeJumped && c.value >= 0.5 && _pc.hasClients) {
        _fadeJumped = true;
        _pc.jumpToPage(_fadeTarget!);
      }
      if (mounted) setState(() {});
    });
    c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _programmatic = false;
        if (mounted) setState(() {});
      }
    });
    unawaited(c.forward());
  }

  double get _fadeOpacity {
    final c = _fade;
    if (c == null || !c.isAnimating) return 1;
    final t = c.value;
    return t < 0.5 ? 1 - 2 * t : 2 * t - 1;
  }

  // ── Zoom ──────────────────────────────────────────────────────────────────

  void _setZoom(double scale, Offset focal, {bool clamp = true}) {
    final old = _zoom;
    final next = clamp ? scale.clamp(kPagedZoomMin, kPagedZoomMax).toDouble() : scale;
    if ((next - old).abs() < 1e-6) return;
    _pan = panForFocal(focal: focal, size: _stage, oldPan: _pan, oldScale: old, newScale: next.clamp(kPagedZoomMin, kPagedZoomMax + 1));
    ref.read(readerUiProvider.notifier).setZoom(next, clamp: false);
    if (mounted) setState(() {});
    _publish();
  }

  void _resetZoom() {
    _pan = Offset.zero;
    ref.read(readerUiProvider.notifier).setZoom(1);
  }

  void _animateZoom(double to, Offset focal, Duration d, Curve curve) {
    _zoomAnim?.dispose();
    final from = _zoom;
    final target = to.clamp(kPagedZoomMin, kPagedZoomMax).toDouble();
    if (d == Duration.zero || (target - from).abs() < 1e-6) {
      _zoomAnim = null;
      _setZoom(target, focal);
      return;
    }
    final c = AnimationController(vsync: this, duration: d);
    _zoomAnim = c;
    c.addListener(() {
      if (mounted) _setZoom(from + (target - from) * curve.transform(c.value), focal);
    });
    unawaited(c.forward());
  }

  @override
  void pinchZoom(
    Offset focal,
    double scale,
    double velocity, {
    required double min,
    required double max,
    double? snapStep,
    bool rubberBand = true,
    bool released = false,
  }) {
    _zoomAnim?.dispose();
    _zoomAnim = null;
    final lo = math.max(min, kPagedZoomMin), hi = math.min(max, kPagedZoomMax);
    if (!released) {
      _setZoom(scale.clamp(lo, hi).toDouble(), focal);
      return;
    }
    final step = snapStep ?? 0.1;
    final snapped = double.parse(((scale.clamp(lo, hi) / step).round() * step).toStringAsFixed(4));
    _animateZoom(snapped, focal, const Duration(milliseconds: 160), Curves.easeOut);
  }

  @override
  void zoomAt(Offset point, double scale, {required Duration duration, required Curve curve, SpringDescription? spring}) =>
      _animateZoom(scale, point, spring != null ? const Duration(milliseconds: 380) : duration, spring != null ? Curves.easeOutCubic : curve);

  @override
  void zoomIn() => _setZoom(_zoom + 0.1, _stage.center(Offset.zero));
  @override
  void zoomOut() => _setZoom(_zoom - 0.1, _stage.center(Offset.zero));
  @override
  void resetZoom() => _animateZoom(1, _stage.center(Offset.zero), Duration.zero, Curves.linear);
  @override
  void toggleDoubleTapZoom() => _animateZoom(pagedDoubleTapTarget(_zoom), _stage.center(Offset.zero), const Duration(milliseconds: 240), Curves.easeOutCubic);

  // ── Pointers ──────────────────────────────────────────────────────────────

  void _cancelLongPress() {
    _longPress?.cancel();
    _longPress = null;
    _longPressStart = null;
  }

  void _onDown(PointerDownEvent e) {
    if (_pointers.isEmpty) {
      _tapDown = (position: e.localPosition, at: DateTime.now());
      _dragStart = e.localPosition;
      _dragDx = 0;
      _dragStartAt = DateTime.now();
      final cb = widget.options.onPageLongPress;
      if (cb != null) {
        _cancelLongPress();
        _longPressStart = e.localPosition;
        final at = e.localPosition;
        _longPress = Timer(const Duration(milliseconds: 450), () {
          _longPress = null;
          if (mounted) cb(_chapter.id, _pageAt(at));
        });
      }
    } else {
      _tapDown = null;
      _cancelLongPress();
    }
    _pointers[e.pointer] = e.localPosition;
    if (widget.options.pinch && _pointers.length == 2) {
      final pts = _pointers.values.toList();
      _pinchStart = (distance: (pts[0] - pts[1]).distance, zoom: _zoom);
      _pinchFocal = (pts[0] + pts[1]) / 2;
      setState(() => _pinching = true);
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    final down = _tapDown;
    final slop = widget.options.tapSlop ?? 18;
    if (down != null && (e.localPosition - down.position).distance > slop) _tapDown = null;
    final ls = _longPressStart;
    if (ls != null && (e.localPosition - ls).distance > 8) _cancelLongPress();
    final start = _pinchStart;
    if (start != null && _pointers.length >= 2) {
      final pts = _pointers.values.take(2).toList();
      final dist = (pts[0] - pts[1]).distance;
      _pinchFocal = (pts[0] + pts[1]) / 2;
      if (start.distance > 0) {
        pinchZoom(_pinchFocal, start.zoom * dist / start.distance, 0, min: kPagedZoomMin, max: kPagedZoomMax);
      }
    } else if (_pointers.length == 1) {
      if (_zoom > 1) {
        _pan = clampPan(_pan + e.delta, _stage, _zoom);
        setState(() {});
      } else if (widget.reducedMotion && _dragStart != null) {
        _dragDx = e.localPosition.dx - _dragStart!.dx;
      }
    }
  }

  void _onUp(PointerUpEvent e) {
    final wasTap = _pointers.length == 1 ? _tapDown : null;
    _cancelLongPress();
    _pointers.remove(e.pointer);
    _endPinch();
    if (wasTap != null && DateTime.now().difference(wasTap.at) < const Duration(milliseconds: 350)) {
      _dispatchTap(e.localPosition);
    } else if (widget.reducedMotion && _pointers.isEmpty && _zoom <= 1 && _dragStart != null) {
      // Reduced motion: a swipe finishes with a fade rather than a slide.
      final ms = math.max(1, DateTime.now().difference(_dragStartAt).inMilliseconds);
      final step = turnDecision(_dragDx, _dragDx / ms * 1000, rtl: _rtl);
      if (step != 0 && !_edgeStart(_dragStart!)) {
        _step(forward: step > 0, kind: PageTurn.fade);
        widget.onEvent?.call(ReaderPageSwiped(page: _leadPage));
      }
    }
    if (_pointers.isEmpty) _dragStart = null;
    _tapDown = null;
  }

  void _onCancel(PointerCancelEvent e) {
    _cancelLongPress();
    _pointers.remove(e.pointer);
    _tapDown = null;
    _endPinch();
  }

  void _endPinch() {
    if (_pinchStart != null && _pointers.length < 2) {
      final z = _zoom;
      _pinchStart = null;
      pinchZoom(_pinchFocal, z, 0, min: kPagedZoomMin, max: kPagedZoomMax, released: true);
      if (mounted) setState(() => _pinching = false);
    }
  }

  bool _edgeStart(Offset p) {
    final gi = MediaQuery.systemGestureInsetsOf(context);
    return p.dx < math.max(24, gi.left) || p.dx > _stage.width - math.max(24, gi.right);
  }

  void _dispatchTap(Offset pos) {
    final handler = widget.options.tapHandler;
    if (handler == null) return;
    final kind = _classifier.classify(pos, DateTime.now());
    handler(ReaderTapInfo(position: pos, size: _stage, kind: kind));
  }

  /// The page under a touch at [at] (the half of the spread it is on).
  int _pageAt(Offset at) {
    if (_view >= _views.length || _views.isEmpty) return _leadPage;
    final order = spreadDisplayOrder(_views[_view], rtl: _rtl);
    if (order.length == 1) return order.first;
    return at.dx < _stage.width / 2 ? order.first : order.last;
  }

  // ── Bookmark ──────────────────────────────────────────────────────────────

  @override
  bool get bookmarkPending => _bookmarkPending;

  @override
  Future<bool> bookmark() async {
    final add = widget.onAddBookmark;
    if (add == null || _bookmarkPending) return false;
    setState(() => _bookmarkPending = true);
    try {
      final page = _leadPage;
      _flushSave();
      final anchor = (page: page, fraction: 0.0);
      final ok = await add(_chapter, anchor);
      if (!ok) return false;
      (_saved[_chapter.id] ??= []).add(anchor);
      if (!mounted) return true;
      _publish();
      _haptics.light();
      widget.onEvent?.call(ReaderBookmarkSaved(page: page, percent: (page * 100 / _pageCount).round()));
      return true;
    } finally {
      if (mounted) setState(() => _bookmarkPending = false);
    }
  }

  // ── Commands ──────────────────────────────────────────────────────────────

  @override
  void seekToPage(int page) => jumpToPage(page);

  @override
  void jumpToPage(int page, {bool glide = false}) {
    final t = _viewIndexOfPage(page.clamp(1, _pageCount));
    _goToView(t, glide ? PageTurn.slide : PageTurn.cut, slide: const Duration(milliseconds: 240));
  }

  @override
  void turnTo(int page, {PageTurn kind = PageTurn.cut, required Duration slideDuration, required Curve slideCurve, required Duration fadeDuration}) {
    final t = _viewIndexOfPage(page.clamp(1, _pageCount));
    if (t == _view) return;
    _goToView(t, kind, slide: slideDuration, curve: slideCurve, fade: fadeDuration);
  }

  @override
  void pageBy({required bool forward}) => _step(forward: forward, kind: widget.turn);

  @override
  void scrollByViewport(double fraction, {required Duration duration, required Curve curve}) =>
      _step(forward: fraction > 0, kind: widget.turn);

  @override
  void seekToChapter(int chapterIndex) {}

  @override
  int pageAtReadingLine() => _leadPage;

  @override
  void nextChapter() {
    final cb = widget.onNextChapter;
    if (cb == null) return;
    _haptics.light();
    cb();
  }

  @override
  void previousChapter() {
    final cb = widget.onPreviousChapter;
    if (cb == null) return;
    _haptics.light();
    cb();
  }

  @override
  void toggleAutoScroll() {}
  @override
  void setAutoScrollSpeed(double pxPerSecond) => ref.read(readerUiProvider.notifier).setAutoScrollSpeed(pxPerSecond);
  @override
  void setAutoScrollSpeedX(double speedX) {}
  @override
  void showChrome() => _showControls();
  @override
  void hideChrome() => _hideControls();
  @override
  void holdChrome() => _hideTimer?.cancel();
  @override
  void scheduleHideChrome() {
    if (mounted) _scheduleHide();
  }

  @override
  void reportServerProgress({required String chapterKey, required double? chapterNumber, required int lastPage, required bool advanced}) {
    final next = advanced ? null : FurtherElsewhere(chapterKey: chapterKey, chapterNumber: chapterNumber, lastPage: lastPage);
    if (next == _further) return;
    _further = next;
    _publish();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Size _boxFor(ReaderPage p, Size slot) {
    final learned = _learned[p.number];
    final ar = p.aspectRatio ?? (learned == null ? null : learned.width / learned.height) ?? (2 / 3);
    double w, h;
    switch (widget.fit) {
      case ReaderPageFit.width:
        w = slot.width;
        h = w / ar;
      case ReaderPageFit.height:
        h = slot.height;
        w = h * ar;
        if (w > slot.width) {
          w = slot.width;
          h = w / ar;
        }
      case ReaderPageFit.original:
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final px = learned ?? (p.width != null && p.height != null ? Size(p.width!.toDouble(), p.height!.toDouble()) : null);
        if (px == null) {
          h = slot.height;
          w = h * ar;
        } else {
          w = px.width / dpr;
          h = px.height / dpr;
        }
        // ponytail: Original is capped to the stage; a page larger than it is contained, not panned sideways.
        final k = math.min(1.0, math.min(slot.width / w, slot.height / h));
        w *= k;
        h *= k;
    }
    return Size(w, h);
  }

  Widget _page(ReaderPage p, Size slot, int viewIndex) {
    final box = _boxFor(p, slot);
    final options = widget.options;
    final heroTag = options.pageHeroTag?.call(_chapter.id, p.number);
    final epoch = options.pageEpoch?.call(_chapter.id, p.number) ?? 0;
    final imageCore = ReaderPageImage(
      key: epoch == 0 ? null : ValueKey('page-epoch-$epoch'),
      imageUrl: p.imageUrl,
      localFile: p.localFile,
      alt: '${_chapter.title} page ${p.number}',
      aspectRatio: p.aspectRatio ?? (_learned[p.number] == null ? 2 / 3 : _learned[p.number]!.width / _learned[p.number]!.height),
      fitMode: ReaderFitMode.screen,
      backgroundColor: widget.ground,
      brokenBuilder: (context, retry) => options.pageStateBuilder == null
          ? const SizedBox.shrink()
          : options.pageStateBuilder!(context, p.number, PageStatus.broken, null, retry),
      loadingBuilder: options.pageStateBuilder == null ? null : (context) => options.pageStateBuilder!(context, p.number, PageStatus.placeholder, null, () {}),
      cornerRadius: 0,
      layoutAxis: Axis.vertical,
      viewportWidth: box.width,
      viewportHeight: box.height,
      priority: (viewIndex - _view).abs() <= 1,
      declaredWidth: p.width,
      declaredHeight: p.height,
      onIntrinsicSize: _learned.containsKey(p.number) || p.width != null
          ? null
          : (w, h) {
              if (!mounted) return;
              setState(() => _learned[p.number] = Size(w.toDouble(), h.toDouble()));
              final was = _views.length;
              final next = _computeViews();
              if (next.length != was) {
                final lead = _leadPage;
                _views = next;
                _view = _viewIndexOfPage(lead);
                _pc.jumpToPage(_view);
              }
            },
    );
    final Widget image = heroTag == null ? imageCore : Hero(tag: heroTag, child: imageCore);
    final overlay = options.pageOverlayBuilder;
    Widget child = SizedBox(width: box.width, height: box.height, child: image);
    if (overlay != null) {
      child = SizedBox(
        width: box.width,
        height: box.height,
        child: Stack(children: [
          Positioned.fill(child: image),
          Positioned.fill(child: overlay(context, p.number, _chapter.id, box)),
        ]),
      );
    }
    if (options.pageSemantics != null) child = options.pageSemantics!(context, _chapter, p.number, child);
    // Fit width on a tall page overflows the stage: the page scrolls vertically inside its slot.
    if (box.height > slot.height + 0.5) {
      child = SizedBox(width: slot.width, height: slot.height, child: SingleChildScrollView(child: Center(child: child)));
    } else {
      child = Center(child: child);
    }
    return SizedBox(width: slot.width, height: slot.height, child: child);
  }

  Widget _screen(int index) {
    final style = widget.style;
    if (index > _creditsIndex) return ColoredBox(color: widget.ground);
    if (index == _creditsIndex) {
      final credits = widget.options.creditsBuilder;
      return ColoredBox(
        color: widget.ground,
        child: Center(
          child: SingleChildScrollView(
            child: credits == null
                ? const SizedBox.shrink()
                : credits(context, _chapter, widget.creditsNextChapterId ?? _chapter.nextChapterId, CreditsMode.full),
          ),
        ),
      );
    }
    final view = _views[index];
    final inset = style.inset;
    final avail = Size(math.max(0, _stage.width - inset * 2), math.max(0, _stage.height - inset * 2));
    final n = view.length;
    final slotW = (avail.width - style.gutter * (n - 1)) / n;
    final order = spreadDisplayOrder(view, rtl: _rtl);
    final pages = [for (final number in order) _chapter.pages[number - 1]];
    final children = <Widget>[];
    for (var i = 0; i < pages.length; i++) {
      if (i > 0) {
        children.add(SizedBox(
          width: style.gutter,
          height: avail.height,
          child: Center(child: SizedBox(width: 1, height: avail.height, child: ColoredBox(color: style.centreLine))),
        ));
      }
      children.add(_page(pages[i], Size(slotW, avail.height), index));
    }
    Widget row = Padding(
      padding: EdgeInsets.all(inset),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.max, children: children),
    );
    if (index == _view && _zoom > 1) {
      row = Transform.translate(offset: _pan, child: Transform.scale(scale: _zoom, child: row));
    }
    return ColoredBox(color: widget.ground, child: ClipRect(child: row));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    _stage = media;
    final ui = ref.watch(readerUiProvider.select((s) => (s.zoomLevel, s.isLocked)));
    ref.listen<ReaderUiState>(readerUiProvider, (_, __) => _publish());
    ref.listen<ReaderDefaults>(readerDefaultsProvider, (prev, next) {
      if (prev?.keepScreenAwake != next.keepScreenAwake) unawaited(_syncWakelock(next.keepScreenAwake));
      if (prev?.refreshRate != next.refreshRate) _syncRate(next.refreshRate);
      if (prev?.volumeKeyNavigation != next.volumeKeyNavigation) unawaited(_syncVolume(next.volumeKeyNavigation));
    });
    final locked = ui.$2;
    final zoomed = ui.$1 > 1.0;
    final ScrollPhysics physics = zoomed || _pinching || locked || widget.reducedMotion
        ? const NeverScrollableScrollPhysics()
        : (_spec.pagePhysics ?? const PageScrollPhysics());
    final count = _creditsIndex + 1 + (_hasNext ? 1 : 0);
    final gi = MediaQuery.systemGestureInsetsOf(context);
    final edge = math.max(24.0, math.max(gi.left, gi.right));
    Widget pages = PageView.builder(
      key: ValueKey('paged-${_spec.layout.name}'),
      controller: _pc,
      reverse: _rtl,
      physics: physics,
      itemCount: count,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, i) => RepaintBoundary(child: _screen(i)),
    );
    final fade = _fadeOpacity;
    if (fade < 1) pages = Opacity(opacity: fade.clamp(0.0, 1.0), child: pages);
    if (widget.options.pageLayerBuilder != null) pages = widget.options.pageLayerBuilder!(context, pages);
    Widget stack = Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: widget.ground)),
        Positioned.fill(child: pages),
        // Touches that start on the screen edge are ignored by the page view (the system's edge gestures own them).
        Positioned(left: 0, top: 0, bottom: 0, width: edge, child: const AbsorbPointer()),
        Positioned(right: 0, top: 0, bottom: 0, width: edge, child: const AbsorbPointer()),
      ],
    );
    stack = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: stack,
    );
    return ProviderScope(
      overrides: [readerEngineProvider.overrideWithValue(widget.controller)],
      child: Stack(
        children: [
          Positioned.fill(child: stack),
          Positioned.fill(
            child: ValueListenableBuilder<ReaderEngineState>(
              valueListenable: widget.controller,
              builder: (context, state, _) => widget.chromeBuilder(context, state),
            ),
          ),
        ],
      ),
    );
  }
}
