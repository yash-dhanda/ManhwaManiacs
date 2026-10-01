import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show ScaleGestureRecognizer, ScaleStartDetails, ScaleUpdateDetails, ScaleEndDetails, TapGestureRecognizer, TapUpDetails, kDoubleTapSlop;
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' show singleKeyShortcutsProvider;
import 'package:manhwamaniacs/features/reader/engine/camera.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/tap_classifier.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/ambient/ambient_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_pill.dart' show slop10;
import 'package:manhwamaniacs/skins/glass/ambient/guided.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// One place the camera stops: a panel (or a walked slice of a tall one) of a page.
class _Stop {
  const _Stop(this.panel, this.pose, this.lens);
  final int panel; // -1 for a whole page
  final CameraPose pose;

  /// The framed panel's rect in the viewport at [pose].
  final Rect lens;
}

/// Guided view (glass 9.4.3): the camera frames one panel at a time, the rest of the page is dimmed to `#000000` at 85 %, and one T2
/// glass lens sits over the framed panel. It lives in the reader's overlay layer, so the lens and the counter pill are the only glass.
/// A pinch out, or the overview button, shows every panel numbered. It reads the engine's ambient panel results and never moves the
/// strip itself: [onClose] tells the reader where to land.
class GlassGuidedView extends ConsumerStatefulWidget {
  const GlassGuidedView({
    super.key,
    required this.engine,
    required this.chapter,
    required this.rtl,
    required this.initialPage,
    required this.onClose,
    this.onNextChapter,
    this.onPreviousChapter,
    this.lb = 1.0,
    this.tint,
    this.bottomInset = 16,
  });

  final ReaderEngine engine;
  final ReaderChapter chapter;
  final bool rtl;
  final int initialPage;

  /// The view closed on [page]; [panelTop] is the framed panel's top as a fraction of the page (null for a whole page).
  final void Function(int page, double? panelTop) onClose;
  final VoidCallback? onNextChapter, onPreviousChapter;

  /// The lens's `Lb`: the maximum of the sample's bands it overlaps.
  final double lb;
  final Color? tint;

  /// From the screen's bottom edge to the counter pill (`max(inset.bottom, system gesture inset) + 16`).
  final double bottomInset;

  @override
  ConsumerState<GlassGuidedView> createState() => GlassGuidedViewState();
}

class GlassGuidedViewState extends ConsumerState<GlassGuidedView> with TickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this);
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), value: 1);
  final TapClassifier _taps = TapClassifier(doubleTapSlop: kDoubleTapSlop);
  final FocusNode _focus = FocusNode(debugLabel: 'guided view');
  final Map<int, Size> _learned = {};

  int _page = 1;
  int _stop = 0;
  bool _overview = false, _glancing = false;
  int _glanceGen = 0;
  CameraPose _from = CameraPose.identity, _to = CameraPose.identity, _pose = CameraPose.identity;
  Rect? _lensFrom, _lensTo;
  Size _viewport = Size.zero;

  // One finger.
  Offset _drag = Offset.zero;
  bool? _horizontal;
  double _over = 0;
  bool _armed = false;
  double _pinchScale = 1;
  bool _pinching = false, _pinchLimit = false;

  ReaderEngine get _engine => widget.engine;
  ReaderChapter get _chapter => widget.chapter;
  int get _pages => _chapter.pages.length;
  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, math.max(1, _pages));
    _anim.addListener(_onAnim);
    _engine.setGuidedActive(true);
    _engine.ambient.panels.addListener(_onPanels);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enter(_page, last: false, cut: true, announce: false);
    });
  }

  @override
  void dispose() {
    _engine.ambient.panels.removeListener(_onPanels);
    try {
      _engine.setGuidedActive(false);
    } catch (_) {}
    _anim.dispose();
    _fade.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Geometry ────────────────────────────────────────────────────────────

  double _aspectOf(int page) {
    if (page >= 1 && page <= _pages) {
      final p = _chapter.pages[page - 1];
      if (p.width != null && p.height != null && p.height! > 0) return p.width! / p.height!;
    }
    final s = _learned[page];
    if (s != null && s.height > 0) return s.width / s.height;
    return page >= 1 && page <= _pages ? (_chapter.pages[page - 1].aspectRatio ?? 0.7) : 0.7;
  }

  /// The page laid out at pose identity: contained in the viewport and centred.
  Rect _pageRect(int page) {
    final ar = _aspectOf(page);
    final vr = _viewport.width / (_viewport.height == 0 ? 1 : _viewport.height);
    final w = ar >= vr ? _viewport.width : _viewport.height * ar;
    final h = ar >= vr ? _viewport.width / ar : _viewport.height;
    return Rect.fromLTWH((_viewport.width - w) / 2, (_viewport.height - h) / 2, w, h);
  }

  PanelsState? _panelsOf(int page) => _engine.ambient.panelsOf(page);
  bool get _finding => _panelsOf(_page) == null || _panelsOf(_page) is PanelsFinding;
  List<Rect> get _panels => switch (_panelsOf(_page)) { PanelsFound(:final fractions) => fractions, _ => const [] };
  bool get _whole => _panelsOf(_page) is PanelsNone;

  /// Every stop of [page]: one per panel, a tall panel walked in 80 % steps; a whole page is one stop.
  List<_Stop> _stops(int page) {
    if (_viewport.isEmpty) return const [];
    final st = _panelsOf(page);
    final r = _pageRect(page);
    if (st is! PanelsFound) return [_Stop(-1, CameraPose.identity, r)];
    final out = <_Stop>[];
    for (var i = 0; i < st.fractions.length; i++) {
      final f = st.fractions[i];
      final px = Rect.fromLTWH(r.left + f.left * r.width, r.top + f.top * r.height, f.width * r.width, f.height * r.height);
      // Fitted by width (the webtoon panel); one that is then taller than the viewport minus its padding is walked.
      final wScale = math.min((_viewport.width - 48) / px.width, 3.0);
      if (px.height * wScale <= _viewport.height - 48) {
        final base = frameRect(px, _viewport);
        out.add(_Stop(i, base, _apply(base, px)));
        continue;
      }
      final base = CameraPose(wScale, 0, 0);
      final framedH = px.height * wScale;
      for (final off in walkSteps(framedH, _viewport.height)) {
        final top = px.top + off / base.scale;
        final slice = Rect.fromLTWH(px.left, top, px.width, _viewport.height / base.scale);
        final pose = CameraPose(base.scale, _viewport.width / 2 - slice.center.dx * base.scale, _viewport.height / 2 - slice.center.dy * base.scale);
        out.add(_Stop(i, pose, Rect.fromLTWH(24, 24, _viewport.width - 48, _viewport.height - 48).intersect(_apply(pose, px))));
      }
    }
    return out;
  }

  Rect _apply(CameraPose p, Rect r) => Rect.fromLTWH(r.left * p.scale + p.dx, r.top * p.scale + p.dy, r.width * p.scale, r.height * p.scale);

  /// Every page has a result (found or none): the total is known.
  int? get _total {
    var n = 0;
    for (var p = 1; p <= _pages; p++) {
      final s = _panelsOf(p);
      if (s == null || s is PanelsFinding) return null;
      if (s is PanelsFound) n += s.fractions.length;
    }
    return n;
  }

  int get _panelsBefore {
    var n = 0;
    for (var p = 1; p < _page; p++) {
      final s = _panelsOf(p);
      if (s is PanelsFound) n += s.fractions.length;
    }
    return n;
  }

  /// The stop index to the panel number (a walked tall panel has several stops).
  int get _panelNo {
    final stops = _stops(_page);
    if (stops.isEmpty) return 0;
    return math.max(0, stops[_stop.clamp(0, stops.length - 1)].panel);
  }

  // ── Moving ──────────────────────────────────────────────────────────────

  void _enter(int page, {required bool last, required bool cut, bool announce = true, double velocity = 0}) {
    _page = page.clamp(1, math.max(1, _pages));
    _engine.ambient
      ..pageCount = _pages
      ..onPage(_chapter.id, _page);
    if (_panelsOf(_page) == null) unawaited(_engine.ambient.ensurePanels(_chapter.id, _page));
    final stops = _stops(_page);
    _stop = stops.isEmpty ? 0 : (last ? stops.length - 1 : 0);
    _go(stops.isEmpty ? CameraPose.identity : stops[_stop].pose, stops.isEmpty ? null : stops[_stop].lens, cut: cut, velocity: velocity);
    if (announce) _announce();
  }

  void _onPanels() {
    if (!mounted || _glancing || _pinching || _overview || _viewport.isEmpty) return;
    final stops = _stops(_page);
    if (stops.isEmpty) return;
    _stop = _stop.clamp(0, stops.length - 1);
    _go(stops[_stop].pose, stops[_stop].lens, cut: true);
    setState(() {});
  }

  void _go(CameraPose to, Rect? lens, {bool cut = false, double velocity = 0, bool glide = true}) {
    _anim.stop();
    _lensFrom = lens == null ? null : (_liveLens ?? lens);
    _lensTo = lens;
    if (cut || _reduced || !glide) {
      _lensFrom = lens;
      _from = _to = _pose = to;
      if (_reduced && !cut) {
        _fade.forward(from: 0);
      }
      setState(() {});
      return;
    }
    _from = _pose;
    _to = to;
    final travel = math.max(1.0, math.max((to.dx - _from.dx).abs(), (to.dy - _from.dy).abs()));
    final entry = GlassMotion.recorder.begin(MotionName.panelCamera.label, 392);
    _anim.value = 0;
    unawaited(_anim.animateWith(SpringSimulation(springOf(gt.springCamera), 0, 1, velocity / travel)).whenComplete(() => GlassMotion.recorder.end(entry)));
  }

  void _onAnim() {
    final t = _anim.value;
    setState(() => _pose = CameraPose.lerp(_from, _to, t));
  }

  void _step(int dir, {double velocity = 0}) {
    if (_overview) return;
    final stops = _stops(_page);
    glassFire(ref, HapticEvent.panelStep);
    if (dir > 0) {
      if (_stop + 1 < stops.length) {
        _stop++;
        _go(stops[_stop].pose, stops[_stop].lens, velocity: velocity);
        _announce();
        return;
      }
      if (_page < _pages) {
        _enter(_page + 1, last: false, cut: false, velocity: velocity);
        return;
      }
      _chapterEdge(next: true);
    } else {
      if (_stop > 0) {
        _stop--;
        _go(stops[_stop].pose, stops[_stop].lens, velocity: velocity);
        _announce();
        return;
      }
      if (_page > 1) {
        _enter(_page - 1, last: true, cut: false, velocity: velocity);
        return;
      }
      _chapterEdge(next: false);
    }
  }

  /// Past the last panel a further next commits the next chapter on its first panel (before the first, the previous one).
  void _chapterEdge({required bool next}) {
    glassFire(ref, HapticEvent.chapterNext);
    final go = next ? widget.onNextChapter : widget.onPreviousChapter;
    go?.call();
  }

  void _announce() {
    final text = announcement(page: _page, panel: _panelNo, panelsBefore: _panelsBefore, total: _total);
    // ignore: avoid_redundant_argument_values
    unawaited(SemanticsService.sendAnnouncement(View.of(context), text, TextDirection.ltr, assertiveness: Assertiveness.polite));
  }

  void _toPanel(int panel) {
    final stops = _stops(_page);
    final i = stops.indexWhere((s) => s.panel == panel);
    if (i < 0) return;
    _overview = false;
    _stop = i;
    _go(stops[i].pose, stops[i].lens);
    _announce();
  }

  void _openOverview() {
    if (_overview) return;
    setState(() => _overview = true);
    _go(CameraPose.identity, null);
  }

  void _closeOverview() {
    if (!_overview) return;
    setState(() => _overview = false);
    final stops = _stops(_page);
    if (stops.isNotEmpty) _go(stops[_stop.clamp(0, stops.length - 1)].pose, stops[_stop.clamp(0, stops.length - 1)].lens);
  }

  /// A double tap in the centre band: the whole page for 1.5 s, then back to the panel.
  Future<void> _glance() async {
    if (_glancing || _overview) return;
    final gen = ++_glanceGen;
    _glancing = true;
    final back = _stops(_page);
    _go(CameraPose.identity, null);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted || gen != _glanceGen) return;
    _glancing = false;
    if (back.isNotEmpty) {
      final s = back[_stop.clamp(0, back.length - 1)];
      _go(s.pose, s.lens);
    }
  }

  void _close() {
    double? top;
    final st = _panelsOf(_page);
    if (st is PanelsFound && st.fractions.isNotEmpty) top = st.fractions[_panelNo.clamp(0, st.fractions.length - 1)].top;
    widget.onClose(_page, top);
  }

  // ── Gestures ────────────────────────────────────────────────────────────

  void _onTapUp(TapUpDetails d) {
    final size = _viewport;
    final step = bandStep(d.localPosition.dx, size.width, rtl: widget.rtl);
    final kind = _taps.classify(d.localPosition, DateTime.now());
    // Side taps act at once and never open a double-tap window.
    if (step != 0) {
      _taps.reset();
      _step(step);
      return;
    }
    if (kind == TapKind.double) unawaited(_glance());
  }

  void _scaleStart(ScaleStartDetails d) {
    _drag = Offset.zero;
    _horizontal = null;
    _over = 0;
    _armed = false;
    _pinchScale = 1;
    _pinching = d.pointerCount >= 2;
    _pinchLimit = false;
    _anim.stop();
  }

  void _scaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2 || _pinching) {
      _pinching = true;
      _pinchScale = d.scale;
      if (!_overview && d.scale > 1) {
        // Pinching in above 1x rubber-bands at +-0.18 and says so once.
        final extra = rubberband(d.scale - 1, 0.18, 1);
        if (extra >= 0.17 && !_pinchLimit) {
          _pinchLimit = true;
          glassFire(ref, HapticEvent.zoomLimit);
        }
        setState(() => _pose = CameraPose(_to.scale * (1 + extra), _to.dx - (_viewport.width / 2 - _to.dx) * extra, _to.dy - (_viewport.height / 2 - _to.dy) * extra));
      }
      return;
    }
    _drag += d.focalPointDelta;
    if (_horizontal == null && _drag.distance >= 10) _horizontal = horizontalLocked(_drag.dx, _drag.dy);
    if ((_horizontal ?? false) && !_overview) {
      final stops = _stops(_page);
      final atEnd = _stop + 1 >= stops.length && _page >= _pages && (widget.rtl ? _drag.dx > 0 : _drag.dx < 0);
      final atStart = _stop == 0 && _page <= 1 && (widget.rtl ? _drag.dx < 0 : _drag.dx > 0);
      if (atEnd || atStart) {
        _over = rubberband(_drag.dx, 160, 0.35);
        final shown = _over.abs();
        if (shown >= 48 && !_armed) {
          _armed = true;
          glassFire(ref, HapticEvent.chapterArm);
        }
        setState(() => _pose = CameraPose(_to.scale, _to.dx + _over, _to.dy));
      }
    } else if (_horizontal == false && _drag.dy > 0 && !_overview) {
      setState(() => _pose = CameraPose(_to.scale, _to.dx, _to.dy + rubberband(_drag.dy, 400, 0.5)));
    }
  }

  void _scaleEnd(ScaleEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (_pinching) {
      _pinching = false;
      if (!_overview && _pinchScale < 0.85) {
        _openOverview();
      } else if (_overview && _pinchScale > 1.15) {
        _closeOverview();
      } else {
        _go(_to, _lensTo);
      }
      return;
    }
    if (_overview) return;
    if (_horizontal ?? false) {
      if (_over.abs() >= 72) {
        final next = widget.rtl ? _drag.dx > 0 : _drag.dx < 0;
        _over = 0;
        _chapterEdge(next: next);
        return;
      }
      if (_over != 0) {
        _over = 0;
        _armed = false;
        _go(_to, _lensTo);
        return;
      }
      // The recogniser starts after the 10 px slop: the finger has travelled that much more.
      final dir = swipeStep(_drag.dx + _drag.dx.sign * 10, v.dx, rtl: widget.rtl);
      if (dir != 0) {
        _step(dir, velocity: v.dx.abs());
      } else {
        _go(_to, _lensTo);
      }
      return;
    }
    if (_horizontal == false && exitByProjection(_drag.dy + 10, v.dy)) {
      _close();
      return;
    }
    _go(_to, _lensTo);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final single = ref.read(singleKeyShortcutsProvider);
    if (k == LogicalKeyboardKey.escape) {
      _overview ? _closeOverview() : _close();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowLeft) {
      final right = k == LogicalKeyboardKey.arrowRight;
      _step((right != widget.rtl) ? 1 : -1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      _step(shift ? -1 : 1);
      return KeyEventResult.handled;
    }
    if (single && e.character != null) {
      switch (e.character) {
        case 'j':
          _step(1);
          return KeyEventResult.handled;
        case 'k':
          _step(-1);
          return KeyEventResult.handled;
        case 'P':
          _close();
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(glassMotionPrefsProvider.select((p) => p.reduced));
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        if (_viewport != size) {
          _viewport = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _enter(_page, last: false, cut: true, announce: false);
          });
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _overview ? _closeOverview() : _close();
          },
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _onKey,
            child: Semantics(
              container: true,
              label: 'Guided view',
              customSemanticsActions: {
                const CustomSemanticsAction(label: 'Next panel'): () => _step(1),
                const CustomSemanticsAction(label: 'Previous panel'): () => _step(-1),
              },
              child: Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: Color(0xFF000000))),
                  Positioned.fill(
                    child: slop10(context, RawGestureDetector(
                      behavior: HitTestBehavior.opaque,
                      gestures: {
                        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(TapGestureRecognizer.new, (r) => r.onTapUp = _onTapUp),
                        ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                          ScaleGestureRecognizer.new,
                          (r) => r
                            ..onStart = _scaleStart
                            ..onUpdate = _scaleUpdate
                            ..onEnd = _scaleEnd,
                        ),
                      },
                      child: AnimatedBuilder(animation: _fade, builder: (context, child) => Opacity(opacity: _fade.value.clamp(0.0, 1.0), child: child), child: _stage()),
                    ),),
                  ),
                  if (!_overview && _lensTo != null && !_finding && !_whole) ..._dimAndLens(),
                  if (_overview) ..._overviewLayer(),
                  _counter(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stage() {
    final rect = _pageRect(_page);
    return Transform(
      transform: _pose.toMatrix(),
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: rect,
            child: _GuidedPageImage(
              key: ValueKey('guided-page-$_page'),
              chapter: _chapter,
              page: _page,
              provider: _engine.ambient.resolver?.call(_chapter.id, _page),
              onSize: (w, h) {
                if (_learned.containsKey(_page) || h == 0) return;
                _learned[_page] = Size(w.toDouble(), h.toDouble());
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_overview) _onPanels();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The lens rect on the same spring as the camera: from where it was to the framed panel's rect.
  Rect? get _liveLens {
    final to = _lensTo;
    if (to == null) return null;
    final from = _lensFrom ?? to;
    if (!_anim.isAnimating) return to;
    return Rect.lerp(from, to, _anim.value) ?? to;
  }

  List<Widget> _dimAndLens() {
    final lens = _liveLens!;
    return [
      Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _DimPainter(lens)))),
      Positioned.fromRect(
        rect: lens,
        child: IgnorePointer(
          child: SkinGlass(
            size: lens.size,
            tier: GlassTierId.t2,
            shape: const GlassShape.superellipse(14),
            lb: widget.lb,
            tint: widget.tint,
            layer: GlassLayerKind.overlays,
            debugLabel: 'guided lens',
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }

  List<Widget> _overviewLayer() {
    final r = _pageRect(_page);
    final panels = _panels;
    return [
      Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _OutlinePainter([for (final f in panels) _rectOf(r, f)])))),
      for (var i = 0; i < panels.length; i++)
        Positioned(
          left: _rectOf(r, panels[i]).left,
          top: _rectOf(r, panels[i]).top,
          child: _Chip(number: i + 1, onTap: () => _toPanel(i)),
        ),
      for (var i = 0; i < panels.length; i++)
        Positioned.fromRect(
          rect: _rectOf(r, panels[i]),
          child: Semantics(
            button: true,
            label: 'Panel ${i + 1}',
            excludeSemantics: true,
            onTap: () => _toPanel(i),
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _toPanel(i)),
          ),
        ),
    ];
  }

  Rect _rectOf(Rect page, Rect f) => Rect.fromLTWH(page.left + f.left * page.width, page.top + f.top * page.height, f.width * page.width, f.height * page.height);

  Widget _counter(BuildContext context) {
    final text = counterText(
      page: _page,
      panel: _panelNo,
      panelsBefore: _panelsBefore,
      total: _total,
      finding: _finding,
      whole: _whole,
    );
    final hit = math.max(44.0, GlassFrame.hitMin(context));
    final textW = measureText(context, text, roleStyle(context, gt.typeSubhead, onGlass: true)).width;
    final w = textW + 32 + 2 * hit + 8;
    return Positioned(
      left: 0,
      right: 0,
      bottom: widget.bottomInset,
      child: Center(
        child: SkinGlass(
          size: Size(w, 56),
          tier: GlassTierId.t3,
          lb: widget.lb,
          tint: widget.tint,
          layer: GlassLayerKind.overlays,
          debugLabel: 'guided counter',
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(child: Semantics(liveRegion: true, child: GlassText(text, role: gt.typeSubhead, onGlass: true, maxScale: 1.3, maxLines: 1))),
              _PillButton(icon: AmbientGlyph.squaresFour.regular, label: 'Show the whole page', size: hit, onTap: _overview ? _closeOverview : _openOverview),
              _PillButton(icon: GlassGlyph.x.regular, label: 'Close guided view', size: hit, onTap: _close),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.icon, required this.label, required this.size, required this.onTap});
  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Center(child: Icon(icon, size: 20, color: gt.colorOnGlass))),
        ),
      );
}

/// A numbered chip in the overview: a `fill2` twin (the overlay carries one glass surface only), 24 tall in a 44 pt hit.
class _Chip extends StatelessWidget {
  const _Chip({required this.number, required this.onTap});
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hit = math.max(44.0, GlassFrame.hitMin(context));
    return Semantics(
      button: true,
      label: 'Panel $number',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: hit,
          height: hit,
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              height: 24,
              constraints: const BoxConstraints(minWidth: 24),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(12)),
              child: GlassText('$number', role: gt.typeCaption1, wght: 600, color: gt.colorLabel1),
            ),
          ),
        ),
      ),
    );
  }
}

/// `#000000` at 85 % over the whole viewport with the lens rect cut out (`evenOdd`), one `CustomPaint` under the lens.
class _DimPainter extends CustomPainter {
  const _DimPainter(this.lens);
  final Rect lens;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(lens, const Radius.circular(14)));
    canvas.drawPath(path, Paint()..color = const Color(0xD9000000));
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.lens != lens;
}

/// Every panel outlined 2 px `iris400` at radius 6.
class _OutlinePainter extends CustomPainter {
  const _OutlinePainter(this.rects);
  final List<Rect> rects;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = gt.colorIris400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final r in rects) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), p);
    }
  }

  @override
  bool shouldRepaint(_OutlinePainter old) => !identical(old.rects, rects) && old.rects.length != rects.length;
}

/// The page image, reporting its decoded size so the camera knows the page's shape.
class _GuidedPageImage extends StatefulWidget {
  const _GuidedPageImage({super.key, required this.chapter, required this.page, required this.onSize, this.provider});
  final ReaderChapter chapter;
  final int page;
  final ImageProvider? provider;
  final void Function(int w, int h) onSize;

  @override
  State<_GuidedPageImage> createState() => _GuidedPageImageState();
}

class _GuidedPageImageState extends State<_GuidedPageImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
  Widget build(BuildContext context) => _image == null ? const SizedBox.expand() : RawImage(image: _image, fit: BoxFit.fill);
}
