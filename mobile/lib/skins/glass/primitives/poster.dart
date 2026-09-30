import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/lb.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster_throw.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail_focus.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:motor/motor.dart';

/// The widths of a poster by frame (glass 7.8): phone 124 in rails, tablet 148, desktop frame 168, wide 184.
double posterWidthFor(GlassFrameKind f) => switch (f) {
      GlassFrameKind.phone => 124,
      GlassFrameKind.tablet => 148,
      GlassFrameKind.desktop => 168,
      GlassFrameKind.wide => 184,
    };

/// What a poster wears (glass 7.8, 7.20). Every overlay sits on an opaque backing, because a cover can be white.
class GlassPosterMeta {
  const GlassPosterMeta({this.status, this.newCount = 0, this.downloaded = false, this.mature = false, this.favourite = false, this.progress});
  final GlassStatus? status;
  final int newCount;
  final bool downloaded;

  /// Mature and the gate is open: the 18+ capsule.
  final bool mature;
  final bool favourite;

  /// 0..1: a 3 px `iris500` bar along the bottom.
  final double? progress;
}

/// The cover, arriving: opacity 0 to 1 over `curveFadeIn` and scale 1.02 to 1 on `springSnappy`. It asks the
/// cover proxy for a right-sized image with the session credentials, like every cover in the app (the
/// data layer's helpers, not a Cinematic widget).
class GlassCoverImage extends ConsumerWidget {
  const GlassCoverImage({super.key, required this.url, this.width, this.withCredentials = true});
  final String url;

  /// The declared slot width, so the disk cache keys on one URL per device.
  final double? width;
  final bool withCredentials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headers = withCredentials ? apiImageHttpHeaders(ref.watch(authTokenStoreProvider).token, profileId: ref.watch(activeProfileProvider)?.id) : null;
    final imageUrl = coverUrlAtWidth(url, coverRequestWidth(width, MediaQuery.devicePixelRatioOf(context)));
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: headers,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      imageBuilder: (context, image) => _Arrival(child: Image(image: image, fit: BoxFit.cover)),
      placeholder: (_, __) => ColoredBox(color: gt.colorSurface2),
      errorWidget: (_, __, ___) => ColoredBox(color: gt.colorSurface2, child: const Center(child: GlyphIcon(GlassGlyph.imageBroken, size: 24, color: GlassColors.g600))),
    );
  }
}

class _Arrival extends ConsumerWidget {
  const _Arrival({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(glassReducedProvider);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: gt.curveFadeIn.duration,
      curve: gt.curveFadeIn.curve,
      builder: (context, o, c) => Opacity(opacity: o, child: Transform.scale(scale: 1.02 - 0.02 * o, child: c)),
      child: child,
    );
  }
}

/// Where a lifted poster is (glass 7.8): [growing] from 150 ms, [lifted] at 450 ms (a physical object), [ended] on release.
enum GlassLiftPhase { growing, lifted, ended }

/// A poster (glass 7.8): 2:3, radius 14 (or [GlassPoster.radius]), a 1 px top highlight, no outer border. Touch: a tap is a release
/// before 450 ms within the slop; at 150 ms it grows toward 1.06 (`press.lift`), at 450 ms it calls
/// [onContextPreview] and becomes a physical object: drag moves it 1:1, a release throws it up (open),
/// sideways (away, on AI cards), onto a friend orb, or back on `springZoom`; a touch during the return
/// catches it. Hover pointer: tilt to 6 degrees, a specular highlight, lift -2 px, a peek capsule after
/// 600 ms. Keyboard: focus scale 1.04 and the ring, `.` or `Shift+F10` for the menu, `Enter` opens.
class GlassPoster extends ConsumerStatefulWidget {
  const GlassPoster({
    super.key,
    required this.cover,
    required this.title,
    this.width,
    this.lMax = 0.5,
    this.meta = const GlassPosterMeta(),
    this.onTap,
    this.onContextPreview,
    this.onThrowOpen,
    this.onThrowAway,
    this.onDropOnTarget,
    this.allowAway = false,
    this.targets,
    this.viewport,
    this.selectMode = false,
    this.selected = false,
    this.onFavourite,
    this.onFollow,
    this.following = false,
    this.peekLabel,
    this.onPeek,
    this.loading = false,
    this.error = false,
    this.enabled = true,
    this.disabledReason,
    this.forceStates = GlassWidgetStates.none,
    this.forceHoverButtons = false,
    this.radius = 14,
    this.onLiftPhase,
    this.onMagnetChanged,
  });

  final Widget cover;

  /// The corner radius (14 on rails; the Home spotlight card uses 26).
  final double radius;

  /// Reports the lift: `growing` at 150 ms, `lifted` at 450 ms, `ended` on release or cancel.
  final ValueChanged<GlassLiftPhase>? onLiftPhase;

  /// The id of the friend orb the poster is captured by (null when it lets go): the orb swells while it holds.
  final ValueChanged<Object?>? onMagnetChanged;

  /// The semantics label's title; the badges add their fragments.
  final String title;
  final double? width;

  /// The cover's brightest part, for the bars above it (`GlassLbItem`).
  final double lMax;
  final GlassPosterMeta meta;
  final VoidCallback? onTap;
  final VoidCallback? onContextPreview;
  final ValueChanged<Offset>? onThrowOpen;
  final ValueChanged<Offset>? onThrowAway;
  final ValueChanged<Object?>? onDropOnTarget;
  final bool allowAway;

  /// Registered friend-orb targets, in global coordinates.
  final List<MagnetTarget> Function()? targets;

  /// The viewport used to decide the throw; defaults to the media size.
  final Size? viewport;
  final bool selectMode;
  final bool selected;
  final VoidCallback? onFavourite;
  final VoidCallback? onFollow;
  final bool following;
  final String? peekLabel;
  final VoidCallback? onPeek;
  final bool loading;
  final bool error;
  final bool enabled;
  final String? disabledReason;
  final GlassWidgetStates forceStates;

  /// For captures: show the hover corner buttons.
  final bool forceHoverButtons;

  @override
  ConsumerState<GlassPoster> createState() => _GlassPosterState();
}

class _GlassPosterState extends ConsumerState<GlassPoster> with TickerProviderStateMixin {
  late final SingleMotionController _scale = SingleMotionController(motion: SpringMotion(springOf(gt.springPress)), vsync: this, initialValue: 1);
  late final SingleMotionController _px = SingleMotionController(motion: SpringMotion(springOf(gt.springZoom)), vsync: this);
  late final SingleMotionController _py = SingleMotionController(motion: SpringMotion(springOf(gt.springZoom)), vsync: this);
  late final SingleMotionController _tx = SingleMotionController(motion: SpringMotion(springOf(gt.springTrack)), vsync: this);
  late final SingleMotionController _ty = SingleMotionController(motion: SpringMotion(springOf(gt.springTrack)), vsync: this);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _t0 = Duration.zero;
  double _heldMs = 0;
  final GlobalKey _box = GlobalKey();
  final VelocityTracker _velocity = VelocityTracker.withKind(PointerDeviceKind.touch);
  late final Magnet _magnet = Magnet(
    onCapture: (t) {
      glassFire(ref, HapticEvent.magnetCapture);
      widget.onMagnetChanged?.call(t.id);
    },
    onRelease: (_) {
      glassFire(ref, HapticEvent.magnetDrop);
      widget.onMagnetChanged?.call(null);
    },
  );

  bool _lifting = false;
  bool _lifted = false;
  bool _haptic150 = false;
  bool _menuFired = false;
  bool _hovering = false;
  bool _focused = false;
  bool _peek = false;
  bool _overPeek = false;
  bool _gone = false;
  Timer? _peekTimer;
  Offset _downGlobal = Offset.zero;
  Offset _lastPos = Offset.zero;
  Offset _grab = Offset.zero;
  Offset? _hoverLocal;
  double _lift = 0;

  @override
  void initState() {
    super.initState();
    _ticker.isActive; // create the ticker and the controllers while the element is active
    _scale.value = 1;
    _px.value = 0;
    _py.value = 0;
    _tx.value = 0;
    _ty.value = 0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _peekTimer?.cancel();
    _scale.dispose();
    _px.dispose();
    _py.dispose();
    _tx.dispose();
    _ty.dispose();
    super.dispose();
  }

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  Size get _size {
    final ro = _box.currentContext?.findRenderObject();
    return ro is RenderBox && ro.hasSize ? ro.size : Size.zero;
  }

  Offset get _centreGlobal {
    final ro = _box.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached ? ro.localToGlobal(ro.size.center(Offset.zero)) : Offset.zero;
  }

  // -- touch: press, lift, throw ------------------------------------------------

  void _onTick(Duration elapsed) {
    _heldMs = elapsed.inMicroseconds / 1000;
    if (!_lifting || _reduced) return;
    final ms = _heldMs;
    if (ms >= GlassThresholds.liftStart) {
      if (!_haptic150) {
        _haptic150 = true;
        glassFire(ref, HapticEvent.pressLift);
        widget.onLiftPhase?.call(GlassLiftPhase.growing);
      }
      _scale.stop();
      _scale.value = liftScale(ms);
      final l = ((ms - GlassThresholds.liftStart) / (GlassThresholds.liftMenu - GlassThresholds.liftStart)).clamp(0.0, 1.0);
      if (l != _lift) setState(() => _lift = l);
    }
  }

  void _down(PointerDownEvent e) {
    if (widget.selectMode || !widget.enabled) return;
    _downGlobal = e.position;
    _lastPos = e.position;
    _velocity.addPosition(e.timeStamp, e.position);
    _t0 = e.timeStamp;
    _heldMs = 0;
    _lifting = true;
    _haptic150 = false;
    _menuFired = false;
    if (_px.isAnimating || _py.isAnimating) {
      // A touch during the return catches it (glass 4.3).
      _px.stop();
      _py.stop();
      _lifted = true;
      _grab = e.position - Offset(_px.value, _py.value);
      glassFire(ref, HapticEvent.motionCatch);
      GlassMotion.recorder.end(GlassMotion.recorder.begin(MotionName.catchMove.label, 0));
    } else {
      _grab = e.position;
    }
    if (!_reduced) {
      _scale.motion = SpringMotion(springOf(gt.springPress));
      unawaited(GlassMotion.playMotor(MotionName.contentSink, _scale, 0.97));
    }
    if (!_ticker.isActive) unawaited(_ticker.start());
    setState(() {});
  }

  void _claimed() {
    if (!_lifting) return;
    if (!_menuFired) {
      _menuFired = true;
      glassFire(ref, HapticEvent.longpressOpen);
      widget.onContextPreview?.call();
    }
    _lifted = true;
    widget.onLiftPhase?.call(GlassLiftPhase.lifted);
    _px.stop();
    _py.stop();
    _grab = _lastPos - Offset(_px.value, _py.value);
  }

  void _move(PointerMoveEvent e) {
    _velocity.addPosition(e.timeStamp, e.position);
    _lastPos = e.position;
    if (!_lifted) return;
    var d = e.position - _grab;
    final targets = widget.targets?.call() ?? const [];
    if (targets.isNotEmpty) {
      final centre = _centreGlobal - Offset(_px.value, _py.value);
      final pulled = _magnet.step(centre + d, targets);
      d = pulled - centre;
    }
    _px.stop();
    _py.stop();
    _px.value = d.dx;
    _py.value = d.dy;
  }

  void _up(PointerUpEvent e) {
    final ms = (e.timeStamp - _t0).inMicroseconds / 1000;
    final moved = (e.position - _downGlobal).distance;
    _lifting = false;
    _ticker.stop();
    if (_haptic150) widget.onLiftPhase?.call(GlassLiftPhase.ended);
    if (!_lifted) {
      _settleScale();
      if (ms < GlassThresholds.tapMax && moved <= _slop) widget.onTap?.call();
      return;
    }
    _lifted = false;
    final v = _velocity.getVelocity().pixelsPerSecond;
    final view = widget.viewport ?? MediaQuery.sizeOf(context);
    final decision = decideThrow(
      centre: _centreGlobal,
      velocity: v,
      viewport: view,
      targets: widget.targets?.call() ?? const [],
      allowAway: widget.allowAway,
    );
    _settleScale();
    switch (decision) {
      case ThrowOpen():
        glassFire(ref, HapticEvent.throwCommit, velocity: v.distance);
        widget.onThrowOpen?.call(v);
        _return(v);
      case ThrowAway():
        glassFire(ref, HapticEvent.throwCommit, velocity: v.distance);
        _leave(v, view);
        widget.onThrowAway?.call(v);
      case ThrowTarget(:final target):
        glassFire(ref, HapticEvent.magnetDrop);
        widget.onDropOnTarget?.call(target.id);
        _return(v);
      case ThrowDrop():
        _return(v);
    }
  }

  double get _slop => Scrollable.maybeOf(context) != null ? GlassThresholds.dragSlopTouchScroll : GlassThresholds.dragSlopTouch;

  void _cancel() {
    if (_haptic150) widget.onLiftPhase?.call(GlassLiftPhase.ended);
    _lifting = false;
    _lifted = false;
    _ticker.stop();
    _settleScale();
    _return(Offset.zero);
  }

  void _settleScale() {
    _scale.motion = SpringMotion(springOf(gt.springPress));
    if (_reduced) {
      _scale.value = 1;
    } else {
      unawaited(GlassMotion.playMotor(MotionName.contentSink, _scale, 1));
    }
    if (mounted) setState(() => _lift = 0);
  }

  void _return(Offset v) {
    if (_reduced) {
      _px.value = 0;
      _py.value = 0;
      return;
    }
    unawaited(GlassMotion.playMotor(MotionName.throwMove, _px, 0, withVelocity: v.dx));
    unawaited(GlassMotion.playMotor(MotionName.throwMove, _py, 0, withVelocity: v.dy));
  }

  void _leave(Offset v, Size view) {
    if (_reduced) {
      setState(() => _gone = true);
      return;
    }
    _px.motion = SpringMotion(springOf(gt.springDismiss));
    _py.motion = SpringMotion(springOf(gt.springDismiss));
    final dir = v.dx.sign == 0 ? 1.0 : v.dx.sign;
    unawaited(_px.animateTo(_px.value + dir * view.width, withVelocity: v.dx));
    unawaited(_py.animateTo(_py.value + v.dy * 0.3, withVelocity: v.dy));
    setState(() => _gone = true);
  }

  // -- hover --------------------------------------------------------------------

  void _onHover(PointerHoverEvent e) {
    final s = _size;
    if (s.isEmpty || _reduced) return;
    final ro = _box.currentContext?.findRenderObject();
    if (ro is! RenderBox) return;
    final local = ro.globalToLocal(e.position);
    _hoverLocal = local;
    final nx = ((local.dx / s.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny = ((local.dy / s.height) * 2 - 1).clamp(-1.0, 1.0);
    _tx.animateTo(nx);
    _ty.animateTo(ny);
    setState(() {});
  }

  void _hoverChanged(bool h) {
    _hovering = h;
    _peekTimer?.cancel();
    if (h) {
      if (widget.peekLabel != null && !_reduced) {
        _peekTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted && _hovering) setState(() => _peek = true);
        });
      }
    } else {
      _tx.animateTo(0);
      _ty.animateTo(0);
      _hoverLocal = null;
      _closePeekSoon();
    }
    if (mounted) setState(() {});
  }

  void _closePeekSoon() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted && !_hovering && !_overPeek && !_focused) setState(() => _peek = false);
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (_peek && k == LogicalKeyboardKey.escape) {
      setState(() => _peek = false);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.period || (k == LogicalKeyboardKey.f10 && HardwareKeyboard.instance.isShiftPressed)) {
      widget.onContextPreview?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    final frame = GlassFrame.of(context);
    final w = widget.width ?? posterWidthFor(frame);
    final h = w * 1.5;
    final forced = widget.forceStates;
    final disabled = !widget.enabled || forced.disabled;
    final hover = _hovering || forced.hovered;
    final focus = _focused || forced.focused;
    final showCorner = (hover || focus || widget.forceHoverButtons) && !widget.selectMode && !disabled;
    final m = widget.meta;

    final badges = <GlassBadge>[
      if (m.status != null) GlassBadge.status(m.status!, onCover: true),
      if (m.newCount > 0) GlassBadge.newChapters(m.newCount),
      if (m.downloaded) const GlassBadge.downloaded(onCover: true),
      if (m.mature) const GlassBadge.mature(onCover: true),
    ];
    var label = badgeLabel(widget.title, badges);
    if (m.favourite) label += ', favourite';
    if (widget.selectMode) label = widget.title + (m.newCount > 0 ? ', ${m.newCount} new' : '');

    final actions = <CustomSemanticsAction, VoidCallback>{
      if (widget.onContextPreview != null) const CustomSemanticsAction(label: 'More actions'): widget.onContextPreview!,
    };

    Widget poster = SizedBox(
      key: _box,
      width: w,
      height: h,
      child: _face(context, w, h, showCorner, reduced),
    );

    poster = AnimatedBuilder(
      animation: Listenable.merge([_scale, _px, _py, _tx, _ty]),
      child: poster,
      builder: (context, child) {
        final tilt = hover && !reduced && !_lifting ? 6 * math.pi / 180 : 0.0;
        final m4 = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(-_ty.value.clamp(-1.0, 1.0) * tilt)
          ..rotateY(_tx.value.clamp(-1.0, 1.0) * tilt);
        final lift = hover && !reduced ? -2.0 : 0.0;
        final shadow = _lift > 0
            ? [BoxShadow(color: const Color(0x8C000000).withValues(alpha: 0.55 * _lift), blurRadius: 40 * _lift, offset: Offset(0, 18 * _lift))]
            : (hover ? const [BoxShadow(color: Color(0x80000000), blurRadius: 32, offset: Offset(0, 12))] : const <BoxShadow>[]);
        return Transform.translate(
          offset: Offset(_px.value, _py.value + lift),
          child: Transform.scale(
            scale: _scale.value,
            child: Transform(
              alignment: Alignment.center,
              transform: m4,
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.radius), boxShadow: shadow),
                child: child,
              ),
            ),
          ),
        );
      },
    );

    poster = Opacity(opacity: _gone ? 0 : (disabled ? 0.55 : 1), child: poster);

    final posterInner = poster;
    poster = GlassPressable(
      material: GlassMaterial.content,
      sink: 1,
      shape: GlassShape.superellipse(widget.radius),
      minHit: false,
      onTap: disabled ? null : widget.onTap,
      enabled: !disabled,
      suppressTap: true,
      claimAfter: widget.selectMode ? null : const Duration(milliseconds: 450),
      onLongPress: widget.selectMode || !widget.enabled ? null : _claimed,
      cancelDistance: _slop,
      onRawDown: _down,
      onRawMove: _move,
      onRawUp: (e) {
        if (widget.selectMode) {
          widget.onTap?.call();
        } else {
          _up(e);
        }
      },
      onRawCancel: _cancel,
      forceStates: forced,
      semanticsLabel: label,
      semanticsHint: widget.disabledReason,
      checked: widget.selectMode ? widget.selected : null,
      selected: widget.selected,
      customActions: actions,
      focusNode: GlassRailItemScope.maybeOf(context),
      focusScale: 1.04,
      hoverGlow: false,
      onHoverChanged: _hoverChanged,
      builder: (context, info) => posterInner,
    );
    poster = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (!f) _closePeekSoon();
      },
      onKeyEvent: _key,
      child: MouseRegion(onHover: _onHover, child: poster),
    );
    return GlassLbItem(lMax: widget.lMax, child: poster);
  }

  Widget _face(BuildContext context, double w, double h, bool showCorner, bool reduced) {
    final m = widget.meta;
    final hover = _hovering || widget.forceStates.hovered;
    final sel = widget.selectMode && widget.selected;
    final cornerVisible = showCorner;
    final hideTags = widget.selectMode || cornerVisible;

    Widget fade(bool visible, Widget child) => AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: ExcludeFocus(excluding: !visible, child: IgnorePointer(ignoring: !visible, child: child)),
        );

    Widget disc(double size, Widget child, {Color? colour}) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colour ?? const Color(0xB8000000), shape: BoxShape.circle),
          child: child,
        );

    Widget cornerButton(IconData icon, Color colour, String label, VoidCallback? onTap, {IconData? fill, bool on = false}) => GlassPressable(
          material: GlassMaterial.content,
          sink: 0.92,
          shape: const GlassShape.circle(),
          minHit: false,
          onTap: onTap,
          semanticsLabel: label,
          toggled: on,
          tooltip: label,
          builder: (context, info) => disc(32, Icon(on ? (fill ?? icon) : icon, size: 18, color: colour), colour: const Color(0xDB000000)),
        );

    final cover = ClipRSuperellipse(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: gt.colorSurface2),
          if (widget.error)
            const Center(child: GlyphIcon(GlassGlyph.imageBroken, size: 24, color: GlassColors.g600))
          else if (widget.loading)
            const GlassSkeletonGroup(child: GlassSkeleton(radius: 0, delayed: false))
          else
            Opacity(opacity: sel ? 0.8 : 1, child: widget.cover),
          // A 1 px inner highlight along the top edge.
          const Positioned(left: 0, right: 0, top: 0, height: 1, child: ColoredBox(color: Color(0x14FFFFFF))),
          if (hover && _hoverLocal != null && !reduced)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _SpecularPainter(_hoverLocal!))),
            ),
          if (m.progress != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 5,
              child: ColoredBox(
                color: const Color(0xDB000000),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(widthFactor: m.progress!.clamp(0.0, 1.0), heightFactor: 0.6, child: ColoredBox(color: gt.colorIris500)),
                ),
              ),
            ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: cover),
        if (sel) Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: ShapeDecoration(shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(widget.radius), side: BorderSide(color: gt.colorIris500, width: 2)))))),
        // Top-left: the status tag, or the favourite star on hover and focus.
        Positioned(
          left: 8,
          top: 8,
          child: Stack(
            children: [
              if (m.status != null || (m.mature && !cornerVisible)) fade(!hideTags, Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (m.status != null) GlassBadge.status(m.status!, onCover: true),
                if (m.mature && !cornerVisible) ...[if (m.status != null) const SizedBox(height: 4), const GlassBadge.mature(onCover: true)],
              ],),),
              fade(cornerVisible && widget.onFavourite != null, cornerButton(GlassGlyph.star.regular, gt.colorStreakCore, 'Favourite', widget.onFavourite, fill: GlassGlyph.star.fill, on: m.favourite)),
            ],
          ),
        ),
        // Top-right: "N new", or the follow bell on hover and focus; the check orb in select mode.
        Positioned(
          right: 8,
          top: 8,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              if (m.newCount > 0) fade(!hideTags, GlassBadge.newChapters(m.newCount)),
              fade(cornerVisible && widget.onFollow != null, cornerButton(GlassGlyph.bellSimple.regular, gt.colorIris400, 'Follow', widget.onFollow, fill: GlassGlyph.bellRinging.fill, on: widget.following)),
              if (widget.selectMode)
                SpringValue(
                  value: sel ? 1 : 0,
                  spring: gt.springTick,
                  builder: (context, v, _) => Transform.scale(
                    scale: v.clamp(0.0, 1.3),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: sel ? gt.colorIris500 : const Color(0xB8000000), shape: BoxShape.circle, border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
                      child: sel ? const GlyphIcon(GlassGlyph.check, size: 14, color: Color(0xFF000000)) : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Bottom-left: the downloaded droplet. Bottom-right: the age-gate glyph, the favourite star, and 18+ when the corners are busy.
        if (m.downloaded && !widget.selectMode) Positioned(left: 8, bottom: (m.progress != null ? 13 : 8), child: const GlassBadge.downloaded(onCover: true)),
        Positioned(
          right: 8,
          bottom: (m.progress != null ? 13 : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.mature && cornerVisible) const GlassBadge.mature(onCover: true),
              if (m.favourite && !cornerVisible && !widget.selectMode) ...[const SizedBox(width: 4), disc(22, Icon(GlassGlyph.star.fill, size: 14, color: gt.colorStreakCore), colour: const Color(0xB8000000))],
            ],
          ),
        ),
        if (_peek && widget.peekLabel != null) Positioned(left: 8, right: 8, bottom: 8, child: _peekBar()),
      ],
    );
  }

  Widget _peekBar() => MouseRegion(
        onEnter: (_) => _overPeek = true,
        onExit: (_) {
          _overPeek = false;
          _closePeekSoon();
        },
        child: SpringValue(
          value: 1,
          spring: gt.springMorph,
          name: MotionName.bloom,
          builder: (context, v, _) => Transform.scale(
            scale: 0.9 + 0.1 * v.clamp(0.0, 1.2),
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Container(
                height: 36,
                padding: const EdgeInsets.only(left: 12, right: 4),
                decoration: BoxDecoration(color: const Color(0xDB131317), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
                child: Row(
                  children: [
                    Expanded(child: GlassLabel(widget.peekLabel!, role: gt.typeFootnote, wght: 600, color: gt.colorOnGlass)),
                    GlassPressable(
                      material: GlassMaterial.content,
                      sink: 0.92,
                      shape: const GlassShape.circle(),
                      minHit: false,
                      onTap: widget.onPeek ?? widget.onContextPreview,
                      semanticsLabel: 'More actions',
                      builder: (context, info) => SizedBox(width: 28, height: 28, child: Center(child: GlyphIcon(GlassGlyph.dotsThree, size: 18, color: gt.colorOnGlass))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _SpecularPainter extends CustomPainter {
  const _SpecularPainter(this.at);
  final Offset at;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      at,
      size.width * 0.9,
      Paint()..shader = const RadialGradient(colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)]).createShader(Rect.fromCircle(center: at, radius: size.width * 0.9)),
    );
  }

  @override
  bool shouldRepaint(_SpecularPainter old) => old.at != at;
}
