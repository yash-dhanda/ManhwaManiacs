import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass/palette.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/image_viewer_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/lit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart' show SpringToken;
import 'package:share_plus/share_plus.dart';

/// The clock of the double-tap window: a monotonic real clock (an idle viewer draws no frames, so a frame timestamp
/// would go stale). Tests replace it with the test binding's clock.
@visibleForTesting
Duration Function() glassViewerClock = () => Duration(microseconds: DateTime.now().microsecondsSinceEpoch);

/// Shares [path] from [origin] (the share button's rect); the default is `share_plus` 12.0.2.
typedef GlassShareFile = Future<ShareResult> Function(String path, Rect origin);

Future<ShareResult> _defaultShare(String path, Rect origin) =>
    SharePlus.instance.share(ShareParams(files: [XFile(path)], sharePositionOrigin: origin));

/// The image viewer (glass 7.31; `mobile/29` maps it to `?sheet=image`). A `PageRoute` with `opaque: false`; the image
/// flies from its thumbnail's rect to its fitted rect on `springZoom`, catchable during the flight, over `#000000`
/// with the ambient field at 40 % from the image's palette.
class GlassImageViewerRoute<T> extends PageRoute<T> {
  GlassImageViewerRoute({
    required this.image,
    required this.thumbRect,
    this.thumbnail,
    this.description = 'Image',
    this.sharePath,
    this.palette,
    this.lMax = 0.3,
    this.share = _defaultShare,
    this.onRetry,
  });

  final ImageProvider image;
  final ImageProvider? thumbnail;
  final Rect thumbRect;
  final String description;
  final String? sharePath;
  final CoverPalette? palette;

  /// The palette's brightest part: the close button's `Lb`.
  final double lMax;
  final GlassShareFile share;
  final VoidCallback? onRetry;

  @override
  bool get opaque => false;
  @override
  bool get barrierDismissible => false;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => Duration.zero;
  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => GlassImageViewer(route: this);
}

class GlassImageViewer extends ConsumerStatefulWidget {
  const GlassImageViewer({super.key, required this.route});
  final GlassImageViewerRoute<dynamic> route;

  @override
  ConsumerState<GlassImageViewer> createState() => _GlassImageViewerState();
}

class _GlassImageViewerState extends ConsumerState<GlassImageViewer> with TickerProviderStateMixin {
  // 0 at the thumbnail rect, 1 at the fitted rect (springZoom).
  late final AnimationController _open = AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _scale = AnimationController.unbounded(vsync: this, value: 1);
  late final AnimationController _tx = AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _ty = AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _chrome = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: 1);
  late final AnimationController _sharpen = AnimationController(vsync: this, duration: gt.curveFadeIn.duration);
  final FocusNode _focus = FocusNode(debugLabel: 'GlassImageViewer');
  VoidCallback? _unsuppress;
  Timer? _idle;
  GlassMotionEntry? _move;

  bool _closing = false;
  bool _loaded = false;
  bool _error = false;
  Size? _imageSize;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  // gesture state
  double _s0 = 1;
  Offset _t0 = Offset.zero;
  Offset _f0 = Offset.zero;
  double _dy = 0;
  bool _dragMode = false;
  bool _dismissLine = false;
  Duration _lastTapAt = const Duration(days: -1);
  Offset _lastTapPos = Offset.zero;
  bool _catchable = false;

  GlassImageViewerRoute<dynamic> get route => widget.route;
  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void initState() {
    super.initState();
    _unsuppress = suppressLit();
    _resolve();
    if (route.palette != null) {
      scheduleMicrotask(() {
        if (mounted) ref.read(glassAmbientProvider.notifier).state = GlassAmbientSpec.palette(route.palette!, opacity: 0.4);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _openUp();
    });
    _scheduleChromeHide();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _unsuppress?.call();
    _stream?.removeListener(_listener!);
    _open.dispose();
    _scale.dispose();
    _tx.dispose();
    _ty.dispose();
    _chrome.dispose();
    _sharpen.dispose();
    _focus.dispose();
    super.dispose();
  }

  // -- image loading -------------------------------------------------------------

  void _resolve() {
    _loaded = false;
    _error = false;
    final stream = route.image.resolve(const ImageConfiguration());
    _stream?.removeListener(_listener ?? ImageStreamListener((_, __) {}));
    _listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
      setState(() => _loaded = true);
      _sharpen.forward(from: 0);
    }, onError: (e, s) {
      if (mounted) setState(() => _error = true);
    });
    _stream = stream..addListener(_listener!);
  }

  // -- open and close --------------------------------------------------------------

  void _openUp() {
    if (_reduced) {
      _open.animateTo(1, duration: const Duration(milliseconds: 200));
      return;
    }
    _move = GlassMotion.recorder.begin(MotionName.zoom.label, 558);
    _catchable = true;
    _open.animateWith(SpringSimulation(springOf(gt.springZoom), _open.value, 1, _open.velocity)).whenComplete(() {
      _catchable = false;
      if (_move != null) GlassMotion.recorder.end(_move!);
      _move = null;
    });
  }

  Future<void> _closeUp({double velocity = 0}) async {
    if (_closing) return;
    _closing = true;
    if (_reduced) {
      await _open.animateTo(0, duration: const Duration(milliseconds: 200));
    } else {
      _move = GlassMotion.recorder.begin(MotionName.zoom.label, 558);
      // The image flies back into its thumbnail carrying the release velocity.
      final k = _dyToOpen(velocity);
      await _open.animateWith(SpringSimulation(springOf(gt.springZoom), _open.value, 0, k));
      if (_move != null) GlassMotion.recorder.end(_move!);
      _move = null;
    }
    if (mounted) Navigator.of(context).pop();
  }

  double _dyToOpen(double vy) => -vy.abs() / 600;

  // -- geometry -----------------------------------------------------------------------

  Rect _fitted(Size view) {
    final s = _imageSize ?? Size(route.thumbRect.width, route.thumbRect.height);
    final scale = math.min(view.width / s.width, view.height / s.height);
    final w = s.width * scale, h = s.height * scale;
    return Rect.fromCenter(center: view.center(Offset.zero), width: w, height: h);
  }

  // -- gestures -------------------------------------------------------------------------

  void _showChrome() {
    _chrome.animateTo(1);
    _scheduleChromeHide();
  }

  void _scheduleChromeHide() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 2), () {
      if (mounted) _chrome.animateTo(0);
    });
  }

  void _down(PointerDownEvent e) {
    if (_open.isAnimating && _catchable && !_closing) {
      _open.stop();
      glassFire(ref, HapticEvent.motionCatch);
      _catchable = false;
    }
  }

  void _up(PointerUpEvent e) {
    if (!_open.isAnimating && _open.value < 1 && !_closing) {
      _open.animateWith(SpringSimulation(springOf(gt.springZoom), _open.value, 1, 0));
    }
  }

  void _scaleStart(ScaleStartDetails d, Size view) {
    _tx.stop();
    _ty.stop();
    _scale.stop();
    _s0 = _scale.value;
    _t0 = Offset(_tx.value, _ty.value);
    _f0 = d.localFocalPoint - view.center(Offset.zero);
    _dy = 0;
    _dragMode = false;
    _dismissLine = false;
  }

  void _scaleUpdate(ScaleUpdateDetails d, Size view) {
    final fNow = d.localFocalPoint - view.center(Offset.zero);
    final zoomed = _scale.value > 1.001 || d.pointerCount >= 2 || (d.scale - 1).abs() > 0.02;
    if (!zoomed && d.pointerCount == 1) {
      // At 1x a vertical drag dismisses: the image follows the finger.
      _dragMode = true;
      _dy = fNow.dy - _f0.dy;
      _tx.value = fNow.dx - _f0.dx;
      _ty.value = _dy;
      final line = _dy.abs() >= gt.thresholdImageDismiss;
      if (line != _dismissLine) {
        _dismissLine = line;
        glassFire(ref, line ? HapticEvent.thresholdCross : HapticEvent.thresholdBack);
      }
      return;
    }
    _dragMode = false;
    final target = rubberScale(_s0 * d.scale);
    final t = fNow - (_f0 - _t0) * (target / _s0);
    _scale.value = target;
    final lim = panLimit(image: _fitted(view).size, viewport: view, scale: target);
    _tx.value = panClamp(t.dx, lim.dx);
    _ty.value = panClamp(t.dy, lim.dy);
    if (scaleAtLimit(_s0 * d.scale) && (target - _s0).abs() > 0.001 && (target >= kZoomMax || target <= kZoomMin) && (_s0 * d.scale < kZoomMin || _s0 * d.scale > kZoomMax)) {
      glassFire(ref, HapticEvent.zoomLimit);
    }
  }

  void _scaleEnd(ScaleEndDetails d, Size view) {
    final v = d.velocity.pixelsPerSecond;
    if (_dragMode) {
      _dragMode = false;
      if (shouldDismissImage(_dy, v.dy)) {
        unawaited(_closeUp(velocity: v.dy));
      } else {
        _spring(_tx, 0, v.dx);
        _spring(_ty, 0, v.dy, token: gt.springSettle);
      }
      return;
    }
    // Snap the scale into 1 to 4 on springCamera, keep the pan inside the image, with momentum.
    final s = _scale.value.clamp(kZoomMin, kZoomMax);
    final lim = panLimit(image: _fitted(view).size, viewport: view, scale: s);
    _spring(_scale, s, 0, token: gt.springCamera);
    _spring(_tx, project(_tx.value, v.dx).clamp(-lim.dx, lim.dx), v.dx, token: gt.springCamera);
    _spring(_ty, project(_ty.value, v.dy).clamp(-lim.dy, lim.dy), v.dy, token: gt.springCamera);
  }

  void _spring(AnimationController c, double to, double v, {SpringToken? token}) {
    if (_reduced) {
      c.animateTo(to, duration: const Duration(milliseconds: 150));
      return;
    }
    c.animateWith(SpringSimulation(springOf(token ?? gt.springCamera), c.value, to, v));
  }

  void _tap(TapUpDetails d, Size view, Duration now) {
    final dt = now - _lastTapAt;
    final dist = (d.localPosition - _lastTapPos).distance;
    if (isDoubleTap(dt: dt, distance: dist)) {
      _lastTapAt = const Duration(days: -1);
      final focal = d.localPosition - view.center(Offset.zero);
      final target = doubleTapTarget(_scale.value);
      final t = target == kZoomMin ? Offset.zero : zoomAround(focal: focal, translation: Offset(_tx.value, _ty.value), s0: _scale.value, s1: target);
      final lim = panLimit(image: _fitted(view).size, viewport: view, scale: target);
      glassFire(ref, HapticEvent.zoomSnap);
      _spring(_scale, target, 0);
      _spring(_tx, t.dx.clamp(-lim.dx, lim.dx), 0);
      _spring(_ty, t.dy.clamp(-lim.dy, lim.dy), 0);
    } else {
      _lastTapAt = now;
      _lastTapPos = d.localPosition;
      _showChrome();
    }
  }

  void _zoomBy(double factor, Size view) {
    final target = (_scale.value * factor).clamp(kZoomMin, kZoomMax);
    final lim = panLimit(image: _fitted(view).size, viewport: view, scale: target);
    final t = zoomAround(focal: Offset.zero, translation: Offset(_tx.value, _ty.value), s0: _scale.value, s1: target);
    _spring(_scale, target, 0);
    _spring(_tx, t.dx.clamp(-lim.dx, lim.dx), 0);
    _spring(_ty, t.dy.clamp(-lim.dy, lim.dy), 0);
    if (target == _scale.value) glassFire(ref, HapticEvent.zoomLimit);
    _showChrome();
  }

  void _pan(Offset by, Size view) {
    final lim = panLimit(image: _fitted(view).size, viewport: view, scale: _scale.value);
    _spring(_tx, (_tx.value + by.dx).clamp(-lim.dx, lim.dx), 0);
    _spring(_ty, (_ty.value + by.dy).clamp(-lim.dy, lim.dy), 0);
  }

  Future<void> _share(Rect origin) async {
    final path = route.sharePath;
    if (path == null) return;
    try {
      final r = await route.share(path, origin);
      if (!mounted) return;
      if (r.status == ShareResultStatus.success) {
        showGlassToast(ref, const GlassToastSpec('Shared', kind: GlassToastKind.success));
      } else if (r.status == ShareResultStatus.unavailable) {
        showGlassToast(ref, const GlassToastSpec("Couldn't share this image", kind: GlassToastKind.error));
      }
    } catch (_) {
      if (mounted) showGlassToast(ref, const GlassToastSpec("Couldn't share this image", kind: GlassToastKind.error));
    }
  }

  // -- build ----------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.sizeOf(context);
    final hit = GlassFrame.hitMin(context);
    final safe = MediaQuery.paddingOf(context);
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final fitted = _fitted(view);

    Widget image() => _loaded && !_error
        ? FadeTransition(
            opacity: _sharpen,
            child: Image(image: route.image, fit: BoxFit.fill, gaplessPlayback: true, filterQuality: FilterQuality.medium),
          )
        : const SizedBox.expand();

    final content = AnimatedBuilder(
      animation: Listenable.merge([_open, _scale, _tx, _ty]),
      builder: (context, _) {
        final t = _open.value;
        final base = reduced ? fitted : Rect.lerp(route.thumbRect, fitted, t.clamp(-0.2, 1.4))!;
        final dy = _ty.value, dx = _tx.value;
        final dismissing = _scale.value <= 1.001;
        final sc = dismissing ? dismissScale(dy) : _scale.value;
        final radius = dismissing ? dismissRadius(dy) : 0.0;
        final backdrop = (dismissing ? dismissBackdrop(dy) : 1.0) * (reduced ? t.clamp(0.0, 1.0) : t.clamp(0.0, 1.0));
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: backdrop,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: ColoredBox(key: ValueKey('glass-viewer-backdrop'), color: Color(0xFF000000))),
                      if (route.palette != null) const Positioned.fill(child: Opacity(opacity: 0.4, child: GlassAmbientField())),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: base,
              child: Opacity(
                opacity: reduced ? t.clamp(0.0, 1.0) : 1,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..translate(dx, dy)..scale(sc, sc),
                  child: ClipRSuperellipse(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (route.thumbnail != null)
                          ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8, tileMode: TileMode.clamp),
                            child: Opacity(
                              opacity: 1 - _sharpen.value,
                              child: Image(image: route.thumbnail!, fit: BoxFit.fill),
                            ),
                          ),
                        image(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    final chromeLb = route.lMax;
    Widget glassButton({required String label, required IconData icon, required VoidCallback onTap, required Rect rect, Key? key, Key? widgetKey}) => Positioned.fromRect(
          key: widgetKey,
          rect: rect,
          child: GlassPressable(
            key: key,
            material: GlassMaterial.glass,
            growth: GlassGrowth.light,
            sink: 0.92,
            shape: const GlassShape.circle(),
            onTap: onTap,
            semanticsLabel: label,
            tooltip: label,
            builder: (context, info) => SkinGlass(
              size: rect.size,
              tier: GlassTierId.t1,
              finish: GlassFinishKind.clear,
              shape: const GlassShape.circle(),
              lb: chromeLb,
              glow: info.glow,
              layer: GlassLayerKind.hud,
              debugLabel: 'GlassViewerButton',
              child: Center(child: Icon(icon, size: 22, color: gt.colorOnGlass)),
            ),
          ),
        );
    final shareKey = GlobalKey();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_closeUp());
      },
      child: FocusScope(
        child: Focus(
          focusNode: _focus,
          onKeyEvent: (n, e) {
            if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
            final k = e.logicalKey;
            if (k == LogicalKeyboardKey.escape) {
              unawaited(_closeUp());
            } else if (k == LogicalKeyboardKey.equal || k == LogicalKeyboardKey.add || k == LogicalKeyboardKey.numpadAdd) {
              _zoomBy(1.5, view);
            } else if (k == LogicalKeyboardKey.minus || k == LogicalKeyboardKey.numpadSubtract) {
              _zoomBy(1 / 1.5, view);
            } else if (k == LogicalKeyboardKey.digit0 || k == LogicalKeyboardKey.numpad0) {
              _zoomBy(1 / _scale.value, view);
            } else if (k == LogicalKeyboardKey.arrowLeft) {
              _pan(const Offset(60, 0), view);
            } else if (k == LogicalKeyboardKey.arrowRight) {
              _pan(const Offset(-60, 0), view);
            } else if (k == LogicalKeyboardKey.arrowUp) {
              _pan(const Offset(0, 60), view);
            } else if (k == LogicalKeyboardKey.arrowDown) {
              _pan(const Offset(0, -60), view);
            } else {
              return KeyEventResult.ignored;
            }
            _showChrome();
            return KeyEventResult.handled;
          },
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: route.description,
            child: Listener(
              onPointerDown: _down,
              onPointerUp: _up,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Semantics(
                      customSemanticsActions: {
                        const CustomSemanticsAction(label: 'Zoom in'): () => _zoomBy(1.5, view),
                        const CustomSemanticsAction(label: 'Zoom out'): () => _zoomBy(1 / 1.5, view),
                        const CustomSemanticsAction(label: 'Close'): () => unawaited(_closeUp()),
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: (d) => _scaleStart(d, view),
                        onScaleUpdate: (d) => _scaleUpdate(d, view),
                        onScaleEnd: (d) => _scaleEnd(d, view),
                        onTapUp: (d) => _tap(d, view, glassViewerClock()),
                        child: content,
                      ),
                    ),
                  ),
                  if (_error)
                    Center(
                      child: GlassHost(
                        child: Stack(
                          children: [
                            Positioned.fill(child: SkinGlass(tier: GlassTierId.t4, shape: GlassShape.superellipse(gt.radiusXl), layer: GlassLayerKind.hud, debugLabel: 'GlassViewerError', child: const SizedBox.shrink())),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.imageBroken, size: 22, color: gt.colorDanger)),
                                  const SizedBox(height: 8),
                                  GlassText("Couldn't load this image", role: gt.typeCallout, onGlass: true),
                                  const SizedBox(height: 12),
                                  GlassButton(
                                    label: 'Retry',
                                    size: GlassButtonSize.small,
                                    onPressed: () {
                                                      route.onRetry?.call();
                                      setState(_resolve);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  AnimatedBuilder(
                    animation: _chrome,
                    builder: (context, _) => IgnorePointer(
                      ignoring: _chrome.value < 0.05,
                      child: Opacity(
                        opacity: _chrome.value,
                        child: Stack(
                          children: [
                            if (chromeLb > 0.45)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                height: safe.top + hit + 24,
                                child: const IgnorePointer(child: ColoredBox(key: ValueKey('glass-dim-clear'), color: Color(0x59000000))),
                              ),
                            glassButton(label: 'Close', icon: PhosphorBold.x, onTap: () => unawaited(_closeUp()), rect: Rect.fromLTWH(12, safe.top + 8, hit, hit), key: const ValueKey('glass-viewer-close')),
                            if (route.sharePath != null)
                              glassButton(
                                label: 'Share',
                                icon: GlassGlyph.arrowSquareOut.regular,
                                onTap: () {
                                  final box = shareKey.currentContext?.findRenderObject();
                                  final rect = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : Rect.fromLTWH(view.width - hit - 12, safe.top + 8, hit, hit);
                                  unawaited(_share(rect));
                                },
                                rect: Rect.fromLTWH(view.width - hit - 12, safe.top + 8, hit, hit),
                                key: shareKey,
                                widgetKey: const ValueKey('glass-viewer-share'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
