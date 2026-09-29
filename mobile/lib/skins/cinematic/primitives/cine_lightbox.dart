import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/lightbox_math.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Opens the Lightbox (cinematic 7.30): the surface `colorLightbox`, square corners, no bloom,
/// grain or drift. The art flies from its source frame (a [Hero] with [heroTag], 480 ms, straight
/// `RectTween`) to a `contain` rect never larger than 1.5 x its natural pixels; the crop
/// ([image]) shows at once and [fullImage] fades in over it. Pinch 1-4x, double tap 1x / 2.5x at
/// the tap point, `=` `-` `0`; a vertical drag at 1x dismisses past 120 px or 800 px/s; `x`, `Esc`
/// and Android back close. [folio] is `COVER · 720 × 1080` or `PAGE 18 · 800 × 12400`.
Future<void> openCineLightbox(
  BuildContext context, {
  required Object heroTag,
  required ImageProvider image,
  ImageProvider? fullImage,
  required String title,
  required String folio,
}) {
  final trigger = FocusManager.instance.primaryFocus;
  cineFeedback(context, HapticEvent.longpressOpen);
  final reduced = CineMotion.reduced(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final route = _LightboxRoute(
    reduced: reduced,
    builder: (ctx, route) => themes.wrap(_Lightbox(route: route, heroTag: heroTag, image: image, fullImage: fullImage, title: title, folio: folio, reduced: reduced)),
  );
  return navigator.push<void>(route).whenComplete(() {
    if (trigger != null && trigger.context != null && trigger.canRequestFocus) trigger.requestFocus();
  });
}

/// Marks the Lightbox route so the app frame's toast host can hide its stack under it
/// (cinematic 2.4: `z.lightbox` sits above `z.toast`).
abstract interface class CineLightboxRoute {}

class _LightboxRoute extends PageRoute<void> implements CineLightboxRoute {
  _LightboxRoute({required this.builder, required this.reduced});
  final Widget Function(BuildContext, _LightboxRoute) builder;
  final bool reduced;
  Duration reverse = CineDur.column;

  @override
  bool get opaque => false;
  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => false;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => reduced ? CineDur.reduced : CineDur.spread;
  @override
  Duration get reverseTransitionDuration => reduced ? CineDur.reduced : reverse;

  /// Pops with a spring-length reverse (a drag release) or the 320 ms button length.
  void close(BuildContext context, {bool spring = false}) {
    reverse = spring ? const Duration(milliseconds: 504) : CineDur.column;
    Navigator.of(context).maybePop();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> a, Animation<double> s) => builder(context, this);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> a, Animation<double> s, Widget child) => child;
}

class _Lightbox extends StatefulWidget {
  const _Lightbox({required this.route, required this.heroTag, required this.image, required this.fullImage, required this.title, required this.folio, required this.reduced});
  final _LightboxRoute route;
  final Object heroTag;
  final ImageProvider image;
  final ImageProvider? fullImage;
  final String title, folio;
  final bool reduced;

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> with TickerProviderStateMixin {
  final _tc = TransformationController();
  late final AnimationController _dragY;
  late final AnimationController _zoomAnim;
  Timer? _idle, _chip;
  Size? _natural;
  String? _chipText;
  bool _chrome = true, _failed = false, _focusInside = false;
  final _pointers = <int>{};
  double _dy = 0, _vy = 0;
  Duration? _lastT;
  bool _dragging = false;

  bool get _identity => _tc.value.getMaxScaleOnAxis() <= 1.001;

  @override
  void initState() {
    super.initState();
    _dragY = AnimationController.unbounded(vsync: this);
    _zoomAnim = AnimationController(vsync: this, duration: CineDur.line);
    final stream = widget.image.resolve(ImageConfiguration.empty);
    late ImageStreamListener l;
    l = ImageStreamListener((info, _) {
      if (mounted) setState(() => _natural = Size(info.image.width.toDouble(), info.image.height.toDouble()));
      stream.removeListener(l);
    }, onError: (_, __) => stream.removeListener(l),);
    stream.addListener(l);
    _tc.addListener(() => setState(() {}));
    _bump();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).nextFocus();
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    _chip?.cancel();
    _tc.dispose();
    _dragY.dispose();
    _zoomAnim.dispose();
    super.dispose();
  }

  void _bump() {
    _idle?.cancel();
    if (!_chrome) setState(() => _chrome = true);
    if (_focusInside) return;
    _idle = Timer(const Duration(milliseconds: 3000), () {
      if (mounted && !_focusInside) setState(() => _chrome = false);
    });
  }

  void _showChip() {
    _chip?.cancel();
    setState(() => _chipText = lightboxZoomLabel(_tc.value.getMaxScaleOnAxis()));
    _chip = Timer(CineDur.holdChip, () {
      if (mounted) setState(() => _chipText = null);
    });
  }

  void _animateTo(Matrix4 end) {
    final begin = _tc.value.clone();
    final tween = Matrix4Tween(begin: begin, end: end);
    void tick() => _tc.value = tween.evaluate(CurvedAnimation(parent: _zoomAnim, curve: CineCurves.settle));
    if (widget.reduced) {
      _tc.value = end;
      _showChip();
      return;
    }
    _zoomAnim
      ..removeListener(tick)
      ..addListener(tick);
    _zoomAnim.forward(from: 0).whenComplete(() {
      _zoomAnim.removeListener(tick);
      _showChip();
    });
  }

  Matrix4 _zoomAt(Offset p, double s) => Matrix4.identity()
    ..translateByDouble(p.dx * (1 - s), p.dy * (1 - s), 0, 1)
    ..scaleByDouble(s, s, 1, 1);

  void _doubleTap(Offset p) {
    cineFeedback(context, HapticEvent.zoomSnap);
    _animateTo(_identity ? _zoomAt(p, 2.5) : Matrix4.identity());
    _bump();
  }

  void _step(double factor) {
    final size = MediaQuery.sizeOf(context);
    final s = (_tc.value.getMaxScaleOnAxis() * factor).clamp(1.0, 4.0);
    _animateTo(s <= 1.001 ? Matrix4.identity() : _zoomAt(size.center(Offset.zero), s));
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.equal || k == LogicalKeyboardKey.add || k == LogicalKeyboardKey.numpadAdd) {
      _step(1.25);
    } else if (k == LogicalKeyboardKey.minus || k == LogicalKeyboardKey.numpadSubtract) {
      _step(0.8);
    } else if (k == LogicalKeyboardKey.digit0 || k == LogicalKeyboardKey.numpad0) {
      _animateTo(Matrix4.identity());
    } else if (k == LogicalKeyboardKey.escape) {
      widget.route.close(context);
    } else {
      return KeyEventResult.ignored;
    }
    _bump();
    return KeyEventResult.handled;
  }

  void _pointerMove(PointerMoveEvent e) {
    if (_pointers.length != 1 || !_identity || _zoomAnim.isAnimating) return;
    if (!_dragging && e.delta.dy.abs() <= e.delta.dx.abs()) return;
    _dragging = true;
    setState(() {
      _dy += e.delta.dy;
      final dt = _lastT == null ? 16 : (e.timeStamp - _lastT!).inMilliseconds.clamp(1, 100);
      _lastT = e.timeStamp;
      _vy = e.delta.dy / dt * 1000;
    });
  }

  void _pointerUp() {
    if (!_dragging) return;
    _dragging = false;
    if (lightboxShouldDismiss(_dy, _vy)) {
      widget.route.close(context, spring: true);
    } else {
      final from = _dy;
      _dragY.value = from;
      if (widget.reduced) {
        setState(() => _dy = 0);
      } else {
        _dragY
          ..removeListener(_springTick)
          ..addListener(_springTick);
        _dragY.animateWith(SpringSimulation(context.cine.springRelease.description, from, 0, 0));
      }
    }
    _vy = 0;
  }

  void _springTick() {
    if (mounted) setState(() => _dy = _dragY.value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final size = MediaQuery.sizeOf(context);
    final fit = _natural == null ? size : lightboxFitSize(_natural!, size);
    final barrier = _dragging || _dy != 0 ? lightboxBarrierOpacity(_dy) : kLightboxBarrier;
    final route = widget.route;
    final pointerTablet = size.shortestSide >= 600;
    final showZoom = _focusInside || pointerTablet;
    Widget art = SizedBox(
      width: fit.width,
      height: fit.height,
      child: Hero(
        tag: widget.heroTag,
        createRectTween: (a, b) => RectTween(begin: a, end: b),
        child: Stack(fit: StackFit.expand, children: [
          Image(image: widget.image, fit: BoxFit.contain),
          if (widget.fullImage != null && !_failed)
            Image(
              image: widget.fullImage!,
              fit: BoxFit.contain,
              frameBuilder: (context, child, frame, sync) => AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: widget.reduced ? CineDur.reduced : CineDur.rack, curve: CineCurves.settle, child: child),
              errorBuilder: (context, e, st) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_failed) setState(() => _failed = true);
                });
                return const SizedBox.shrink();
              },
            ),
        ],),
      ),
    );
    if (widget.reduced) art = HeroMode(enabled: false, child: art);
    final flag = BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorInk100));
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Cover of ${widget.title}',
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _key,
        onFocusChange: (v) {
          _focusInside = v && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
          if (_focusInside) {
            _idle?.cancel();
          } else {
            _bump();
          }
          setState(() {});
        },
        child: Listener(
          onPointerDown: (e) {
            _pointers.add(e.pointer);
            _lastT = null;
          },
          onPointerMove: _pointerMove,
          onPointerUp: (e) {
            _pointers.remove(e.pointer);
            _pointerUp();
          },
          onPointerCancel: (e) {
            _pointers.remove(e.pointer);
            _pointerUp();
          },
          child: Stack(fit: StackFit.expand, children: [
            AnimatedBuilder(
              animation: route.animation!,
              builder: (context, _) => ColoredBox(color: c.colorLightbox.withValues(alpha: barrier * (route.animation!.value.clamp(0.0, 1.0)))),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _chrome ? setState(() => _chrome = false) : _bump(),
              onDoubleTapDown: (d) => _lastTap = d.localPosition,
              onDoubleTap: () => _doubleTap(_lastTap),
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, _dy),
                  child: InteractiveViewer(
                    transformationController: _tc,
                    maxScale: 4,
                    onInteractionStart: (_) => _bump(),
                    onInteractionEnd: (_) => _showChip(),
                    child: Center(child: art),
                  ),
                ),
              ),
            ),
            if (_chipText != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 0,
                right: 0,
                child: Center(child: Container(key: const Key('lightbox-chip'), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: flag, child: CineRoleText(_chipText!, c.typeFolio))),
              ),
            AnimatedOpacity(
              duration: widget.reduced ? CineDur.reduced : CineDur.snap,
              opacity: _chrome ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_chrome,
                child: Stack(fit: StackFit.expand, children: [
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    right: 8,
                    child: CineIconButton(key: const Key('lightbox-close'), label: 'Close', role: CineIconRole.close, variant: CineIconButtonVariant.onArt, onPressed: () => route.close(context)),
                  ),
                  Positioned(
                    left: 12,
                    bottom: MediaQuery.paddingOf(context).bottom + 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: flag,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        CineRoleText(widget.title, c.typeCaption, color: c.colorInk60),
                        CineRoleText(widget.folio, c.typeFolio),
                        if (_failed) CineRoleText('Couldn’t load the full cover.', c.typeCaption, color: c.colorProof),
                      ],),
                    ),
                  ),
                  if (showZoom)
                    Positioned(
                      right: 8,
                      bottom: MediaQuery.paddingOf(context).bottom + 8,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        CineIconButton(key: const Key('lightbox-zoom-in'), label: 'Zoom in', codepoint: CineGlyph.plus, variant: CineIconButtonVariant.onArt, onPressed: () => _step(1.25)),
                        CineIconButton(key: const Key('lightbox-zoom-out'), label: 'Zoom out', codepoint: CineGlyph.minus, variant: CineIconButtonVariant.onArt, onPressed: () => _step(0.8)),
                        CineIconButton(key: const Key('lightbox-fit'), label: 'Fit', role: CineIconRole.fullscreenExit, variant: CineIconButtonVariant.onArt, onPressed: () => _animateTo(Matrix4.identity())),
                      ],),
                    ),
                ],),
              ),
            ),
          ],),
        ),
      ),
    );
  }

  Offset _lastTap = Offset.zero;
}
