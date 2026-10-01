import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart' show VelocityTracker;
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/lb.dart' show GlassLbBar;
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/lit.dart' show suppressLit, GlassLitOverlay;
import 'package:manhwamaniacs/skins/glass/primitives/recede.dart';
import 'package:manhwamaniacs/skins/glass/primitives/sheet_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_form_route.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/transitions/predictive_back_detector.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

// ---------------------------------------------------------------------------
// Vocabulary
// ---------------------------------------------------------------------------

/// The detents a sheet may declare (glass 15.3 Detents): `peek` 96 px (the listen mini-player expansion),
/// `medium` 0.52 of the screen height, `large` = screen - safe-top - 10.
enum GlassDetent { peek, medium, large }

/// `monolith` is the listen full player (T5 at medium, `glassSolid2` at large).
enum GlassSheetMaterial { standard, monolith }

/// Tablet and desktop forms of a sheet (glass 7.10): a right-side panel, a centred window, the 960 px detail
/// window and the anchored popover.
enum GlassWideForm { panel, window, detailWindow, popover }

const double kSheetPeekPx = 96;
const double kSheetMediumFraction = 0.52;
const double kSheetTopGap = 10;
const double kSheetInset = 8;
const double kSheetRubberCap = 60;

SheetOffset sheetOffsetOf(GlassDetent d) => switch (d) {
      GlassDetent.peek => const SheetOffset.absolute(kSheetPeekPx),
      GlassDetent.medium => const SheetOffset.proportionalToViewport(kSheetMediumFraction),
      GlassDetent.large => const SheetOffset(1),
    };

/// `large` in px for a screen of [viewport] with [safeTop].
double sheetLargePx(double viewport, double safeTop) => viewport - safeTop - kSheetTopGap;

/// The px of [d].
double sheetDetentPx(GlassDetent d, {required double viewport, required double large}) => switch (d) {
      GlassDetent.peek => kSheetPeekPx,
      GlassDetent.medium => math.min(kSheetMediumFraction * viewport, large),
      GlassDetent.large => large,
    };

/// Where a release lands (glass 15.3 Detents and snapping). [detentsPx] ascending. Returns the index of the
/// nearest detent to the projected top edge, or -1 when the sheet dismisses: the projection falls more than 50 %
/// of the lowest detent's height below it, or the sheet sits at its lowest detent moving down at 1,500 px/s.
int snapDetentIndex({required double offset, required double velocity, required List<double> detentsPx, required double viewport}) {
  final lowest = detentsPx.first;
  final projected = projectCapped(offset, velocity, viewport);
  final atLowest = (offset - lowest).abs() <= 8;
  if (projected < lowest * 0.5 || (atLowest && velocity <= -gt.thresholdSheetDismissVelocity)) return -1;
  var best = 0;
  for (var i = 1; i < detentsPx.length; i++) {
    if ((detentsPx[i] - projected).abs() < (detentsPx[best] - projected).abs()) best = i;
  }
  return best;
}

/// The 60 px rubber band above the top detent (glass 4.5): `rubberband(x, viewport, 0.55)` capped at 60.
double sheetRubber(double raw, double viewport) => math.min(kSheetRubberCap, rubberband(raw, viewport, gt.physicsRubberBandC));

double _rubberInverse(double shown, double viewport) {
  final y = math.min(shown, kSheetRubberCap);
  final c = gt.physicsRubberBandC;
  return (viewport / c) * (1 / (1 - y / viewport) - 1);
}

/// The snap grid the sheet declares: the detents plus dismissal (glass 15.3).
class GlassSnapGrid implements SheetSnapGrid {
  GlassSnapGrid(Iterable<GlassDetent> detents) : detents = ([...detents]..sort((a, b) => a.index.compareTo(b.index)));
  final List<GlassDetent> detents;

  List<double> _px(ViewportLayout layout) {
    final vh = layout.viewportSize.height;
    final large = const SheetOffset(1).resolve(layout);
    return [for (final d in detents) sheetDetentPx(d, viewport: vh, large: large)];
  }

  @override
  SheetOffset getSnapOffset(ViewportLayout layout, double offset, double velocity) {
    final i = snapDetentIndex(offset: offset, velocity: velocity, detentsPx: _px(layout), viewport: layout.viewportSize.height);
    return i < 0 ? const SheetOffset(0) : sheetOffsetOf(detents[i]);
  }

  @override
  (SheetOffset, SheetOffset) getBoundaries(ViewportLayout layout) => (const SheetOffset(0), const SheetOffset(1));
}

/// A straight-line settle over [ms] (reduced motion: a 150 ms fade at the projected detent).
class _TimedSimulation extends Simulation {
  _TimedSimulation(this.from, this.to, this.ms);
  final double from, to;
  final double ms;
  @override
  double x(double time) => from + (to - from) * math.min(time * 1000 / ms, 1);
  @override
  double dx(double time) => time * 1000 >= ms ? 0 : (to - from) / (ms / 1000);
  @override
  bool isDone(double time) => time * 1000 >= ms;
}

/// The sheet physics (glass 15.3): the finger 1:1, a 60 px rubber band above the top detent and the
/// `sheetSnap` spring on release.
class GlassSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const GlassSheetPhysics({this.reduced = false});
  final bool reduced;

  @override
  SpringDescription get spring => springOf(glassTokens.springSheetSnap);

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) {
    final m = metrics;
    final max = m.maxOffset, min = m.minOffset, cur = m.offset;
    final vh = m.viewportSize.height;
    final raw = cur > max ? _rubberInverse(cur - max, vh) : cur - max; // negative below the top detent
    final next = raw + delta;
    final double target = next <= 0 ? math.max(min, max + next) : max + sheetRubber(next, vh);
    return target - cur;
  }

  @override
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics, SheetSnapGrid snapGrid) {
    if (!reduced) return super.createBallisticSimulation(velocity, metrics, snapGrid);
    final snap = snapGrid.getSnapOffset(metrics, metrics.offset, velocity).resolve(metrics);
    if ((snap - metrics.offset).abs() < 0.5) return null;
    return _TimedSimulation(metrics.offset, snap, 150);
  }
}

// ---------------------------------------------------------------------------
// Page and route
// ---------------------------------------------------------------------------

/// A sheet as a go_router-ready [Page] on `smooth_sheets` 1.2.0 (glass 15.3; not `GlassModalSheet`,
/// glass 15.10 G15).
class GlassSheetPage<T> extends Page<T> {
  const GlassSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required this.title,
    required this.builder,
    this.detents = const [GlassDetent.medium, GlassDetent.large],
    this.opening = GlassDetent.medium,
    this.material = GlassSheetMaterial.standard,
    this.originRect,
    this.wideForm,
    this.centerTitle = false,
    this.leading,
    this.trailing,
    this.status,
    this.onRetry,
    this.errorText,
    this.emptyText,
  });

  final String title;
  final WidgetBuilder builder;
  final List<GlassDetent> detents;
  final GlassDetent opening;
  final GlassSheetMaterial material;

  /// The trigger's global rect: the sheet grows out of it when it sits at the bottom of the screen; the
  /// window and popover forms bloom from it.
  final Rect? originRect;
  final GlassWideForm? wideForm;
  final bool centerTitle;
  final Widget? leading;
  final Widget? trailing;
  final ValueListenable<GlassSheetStatus>? status;
  final VoidCallback? onRetry;
  final String? errorText;
  final String? emptyText;

  @override
  Route<T> createRoute(BuildContext context) {
    if (wideForm != null && GlassFrame.of(context) != GlassFrameKind.phone) return GlassFormRoute<T>(this);
    return GlassSheetRoute<T>(this);
  }
}

/// The route of one phone sheet. It moves nothing itself: the sheet's offset is the animation, the barrier
/// follows the offset and the route's own transition only carries the predictive-back detector (glass 15.3).
class GlassSheetRoute<T> extends ModalSheetRoute<T> {
  GlassSheetRoute(this.page)
      : super(
          settings: page,
          builder: _empty,
          swipeDismissible: false,
          barrierDismissible: true,
          transitionDuration: const Duration(milliseconds: 447),
        );

  static Widget _empty(BuildContext _) => const SizedBox.shrink();

  final GlassSheetPage<T> page;
  final SheetController sheetController = SheetController();

  /// Predictive back progress 0..1 (scales the sheet 1 to 0.94 and lifts it 12 px).
  final ValueNotifier<double> backProgress = ValueNotifier(0);

  _GlassSheetBodyState<T>? _body;
  bool popping = false;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 378);

  @override
  Widget buildSheet(BuildContext context) => GlassSheetBody<T>(route: this);

  @override
  ModalSheetBarrierBuilder<T>? get barrierBuilder => (route, onDismiss) {
        final reduced = GlassMotion.isReduced();
        final Animation<Color?> color = reduced
            ? ColorTween(begin: const Color(0x00000000), end: GlassColors.dimSheet).animate(animation!)
            : ColorTween(begin: const Color(0x00000000), end: GlassColors.dimSheet).animate(SheetOffsetDrivenAnimation(
                controller: sheetController,
                initialValue: 0,
                startOffset: const SheetOffset(0),
                endOffset: sheetOffsetOf(page.opening),
              ),);
        return AnimatedModalBarrier(
          color: color,
          semanticsLabel: 'Dismiss',
          onDismiss: () {
            if (animation!.isCompleted && !popping) buttonDismiss();
          },
        );
      };

  /// The close button and a barrier tap: animate to 0 without popping; the listener pops at 0.
  void buttonDismiss() => _body?.closeAnimated(popAtEnd: true);

  @override
  bool didPop(T? result) {
    popping = true;
    // A sheet the button dismiss already brought to 0 leaves at once; otherwise the route's own reverse
    // (378 ms) runs while the sheet animates out.
    if (_body?.isClosed ?? false) controller?.reverseDuration = Duration.zero;
    _body?.closeAnimated(popAtEnd: false);
    return super.didPop(result);
  }

  // -- predictive back ----------------------------------------------------------

  @override
  void handleStartBackGesture({double progress = 0.0}) {
    backProgress.value = 0;
    navigator?.didStartUserGesture();
  }

  @override
  void handleUpdateBackGestureProgress({required double progress}) {
    if (!isCurrent) return;
    backProgress.value = 1 - progress;
  }

  @override
  void handleCancelBackGesture() {
    _body?.returnBack();
    navigator?.didStopUserGesture();
  }

  @override
  void handleCommitBackGesture() {
    navigator?.pop();
    navigator?.didStopUserGesture();
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      GlassPredictiveBackDetector(
        route: this,
        builder: (context, phase, start, current) => ValueListenableBuilder<double>(
          valueListenable: backProgress,
          child: child,
          builder: (context, b, child) => b == 0
              ? child!
              : Transform.translate(
                  offset: Offset(0, -12 * b),
                  child: Transform.scale(key: const ValueKey('glass-sheet-back'), scale: 1 - 0.06 * b, alignment: Alignment.bottomCenter, child: child),
                ),
        ),
      );

  @override
  void dispose() {
    backProgress.dispose();
    sheetController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// The body
// ---------------------------------------------------------------------------

/// The content of a phone sheet: `Sheet`, its surface, the scaffold and the behaviours of glass 15.3.
class GlassSheetBody<T> extends ConsumerStatefulWidget {
  const GlassSheetBody({super.key, required this.route});
  final GlassSheetRoute<T> route;

  @override
  ConsumerState<GlassSheetBody<T>> createState() => _GlassSheetBodyState<T>();
}

class _GlassSheetBodyState<T> extends ConsumerState<GlassSheetBody<T>> with TickerProviderStateMixin {
  GlassSheetRoute<T> get route => widget.route;
  GlassSheetPage<T> get page => route.page;
  SheetController get ctl => route.sheetController;

  late final FocusNode _title = FocusNode(debugLabel: 'GlassSheet.title');
  FocusNode? _trigger;
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  late final AnimationController _backC = AnimationController(vsync: this, duration: const Duration(milliseconds: 414));
  GlassSheetEntry? _entry;
  GlassRecedeController? _recede;
  VoidCallback? _unsuppress;
  GlassMotionEntry? _move;

  bool _armed = false, _dragging = false, _programmatic = false, _closing = false, _settleHaptic = false, _dismissLine = false, _popped = false;
  double _last = 0;
  final VelocityTracker _vt = VelocityTracker.withKind(PointerDeviceKind.touch);
  late final GlassSnapGrid _grid = GlassSnapGrid(page.detents);
  bool _fieldFocused = false;

  /// The surface moves under the stacking dim and scale when another sheet opens over this one; keyed so its content is not rebuilt.
  final GlobalKey _surfaceKey = GlobalKey(debugLabel: 'GlassSheet.surface');

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void initState() {
    super.initState();
    route._body = this;
    // Eager: a late controller first touched in dispose() would look up a deactivated ancestor.
    _fade.value;
    _backC.value;
    _trigger = FocusManager.instance.primaryFocus;
    _unsuppress = suppressLit();
    _fade.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recede = GlassRecedeScope.maybeOf(context);
      _entry = _recede?.open();
      _onOffset();
      _title.requestFocus();
      _present();
    });
    ctl.addListener(_onOffset, fireImmediately: true);
    FocusManager.instance.addListener(_onFocus);
  }

  @override
  void dispose() {
    route._body = null;
    ctl.removeListener(_onOffset);
    FocusManager.instance.removeListener(_onFocus);
    final e = _entry, r = _recede;
    if (e != null && r != null) {
      // The registry is a ValueNotifier read during build; close it after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => r.close(e));
    }
    _unsuppress?.call();
    final t = _trigger;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (t != null && t.context != null && t.canRequestFocus) t.requestFocus();
    });
    _title.dispose();
    _fade.dispose();
    _backC.dispose();
    super.dispose();
  }

  /// The sheet is fully out (offset 0, or faded out under reduced motion).
  bool get isClosed {
    if (_reduced) return _fade.value == 0;
    final v = ctl.value;
    return v != null && v <= 0.5;
  }

  // -- present and dismiss ------------------------------------------------------

  void _record(String label, int ms) {
    if (_move != null) GlassMotion.recorder.end(_move!);
    _move = GlassMotion.recorder.begin(label, ms);
  }

  void _endRecord() {
    if (_move != null) GlassMotion.recorder.end(_move!);
    _move = null;
  }

  void _present() {
    glassSound(ref, SoundEvent.sheetOpen);
    if (_reduced) {
      _armed = true;
      ctl.animateTo(sheetOffsetOf(page.opening), duration: const Duration(milliseconds: 1)).ignore();
      _fade.forward();
      return;
    }
    _record(MotionName.sheetPresent.label, 447);
    _programmatic = true;
    unawaited(ctl.animateTo(sheetOffsetOf(page.opening), duration: const Duration(milliseconds: 447), curve: SpringCurve(gt.springSheet)).whenComplete(() {
      _programmatic = false;
      _endRecord();
    }),);
  }

  /// [popAtEnd]: the button dismiss (the offset listener pops at 0); otherwise the route is already popping.
  void closeAnimated({required bool popAtEnd}) {
    if (!mounted || _closing) return;
    _closing = true;
    glassSound(ref, SoundEvent.sheetClose);
    if (_reduced) {
      _fade.reverse().whenComplete(() {
        if (popAtEnd && mounted) _pop();
      });
      return;
    }
    if (!ctl.hasClient) {
      if (popAtEnd) _pop();
      return;
    }
    _armed = true;
    _record(MotionName.sheetSnap.label, 378);
    _programmatic = true;
    unawaited(ctl.animateTo(const SheetOffset(0), duration: const Duration(milliseconds: 378), curve: SpringCurve(gt.springDismiss)).whenComplete(() {
      _programmatic = false;
      _endRecord();
      // Interrupted short of closed (a re-settle): the close button and the barrier must work again.
      if (mounted && !isClosed) _closing = false;
    }),);
  }

  void _pop() {
    if (_popped || route.popping || !mounted) return;
    final nav = Navigator.maybeOf(context);
    if (nav == null) return;
    _popped = true;
    // Something was pushed over the sheet while it animated out: remove it from under that route. Latching `_popped` without a
    // pop left an invisible sheet whose barrier swallowed every tap.
    if (route.isCurrent) {
      nav.pop();
    } else {
      nav.removeRoute(route);
    }
  }

  void returnBack() {
    final from = route.backProgress.value;
    _backC.stop();
    _backC.value = from;
    void tick() => route.backProgress.value = _backC.value;
    _backC.addListener(tick);
    _backC.animateWith(SpringSimulation(springOf(gt.springSettle), from, 0, 0)).whenComplete(() => _backC.removeListener(tick));
  }

  // -- notifications -------------------------------------------------------------

  List<double> _detentPx(SheetMetrics m) {
    final large = const SheetOffset(1).resolve(m);
    return [for (final d in _grid.detents) sheetDetentPx(d, viewport: m.viewportSize.height, large: large)];
  }

  bool _onNotification(SheetNotification n) {
    final m = n.metrics;
    if (n is SheetDragStartNotification) {
      if (_programmatic || _closing) {
        _programmatic = false;
        _closing = false;
        glassFire(ref, HapticEvent.motionCatch);
        _endRecord();
      }
      _dragging = true;
      _armed = true;
      _settleHaptic = false;
      _dismissLine = false;
      _vt.addPosition(_now(), Offset(0, -m.offset));
      _last = m.offset;
    } else if (n is SheetDragEndNotification || n is SheetDragCancelNotification) {
      _dragging = false;
      _settleHaptic = true;
      _dismissLine = false;
    } else if (n is SheetUpdateNotification || n is SheetDragUpdateNotification) {
      final px = _detentPx(m);
      if (_dragging) {
        _vt.addPosition(_now(), Offset(0, -m.offset));
        for (final d in px) {
          if ((_last - d) * (m.offset - d) < 0) {
            glassFire(ref, HapticEvent.sheetPass);
            break;
          }
        }
        final v = -_vt.getVelocity().pixelsPerSecond.dy;
        final line = projectCapped(m.offset, v, m.viewportSize.height) < px.first * 0.5;
        if (line != _dismissLine) {
          _dismissLine = line;
          glassFire(ref, line ? HapticEvent.thresholdCross : HapticEvent.thresholdBack);
        }
      } else if (_settleHaptic && (m.offset - _last).abs() < 0.3) {
        for (final d in px) {
          if ((m.offset - d).abs() < 0.5) {
            _settleHaptic = false;
            glassFire(ref, HapticEvent.sheetDetent);
            break;
          }
        }
      }
      if (!_armed && (m.offset - sheetOffsetOf(page.opening).resolve(m)).abs() < 1) _armed = true;
      if (_armed && m.offset <= 0.5 && !_dragging && (_closing || !_programmatic)) _pop();
      _last = m.offset;
    }
    return false;
  }

  Duration _now() => SchedulerBinding.instance.currentSystemFrameTimeStamp;

  void _onOffset() {
    final m = ctl.metrics;
    if (m == null) return;
    final e = _entry;
    if (e != null) {
      final mediumPx = sheetDetentPx(GlassDetent.medium, viewport: m.viewportSize.height, large: const SheetOffset(1).resolve(m));
      final large = const SheetOffset(1).resolve(m);
      e.largeProgress.value = large > mediumPx ? ((m.offset - mediumPx) / (large - mediumPx)).clamp(0.0, 1.0) : 0;
      e.atLarge = m.offset >= large - 0.5;
    }
  }

  // -- keyboard ---------------------------------------------------------------------

  void _onFocus() {
    final f = FocusManager.instance.primaryFocus;
    final editable = f?.context?.findAncestorStateOfType<EditableTextState>() != null || f?.context?.widget is EditableText;
    final inside = f != null && f.context != null && (context.mounted) && _isDescendantOf(f);
    final now = editable && inside;
    if (now && !_fieldFocused && ctl.hasClient && !_closing) {
      unawaited(ctl.animateTo(const SheetOffset(1), duration: const Duration(milliseconds: 342), curve: SpringCurve(gt.springSheetSnap)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = FocusManager.instance.primaryFocus?.context;
        if (c != null && c.mounted) Scrollable.ensureVisible(c, alignment: 0.3, duration: const Duration(milliseconds: 342));
      });
    }
    _fieldFocused = now;
  }

  bool _isDescendantOf(FocusNode f) {
    var found = false;
    context.visitAncestorElements((_) => false);
    f.context?.visitAncestorElements((e) {
      if (e == context) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  // -- detent cycling -----------------------------------------------------------------

  void _cycle() {
    final m = ctl.metrics;
    if (m == null) return;
    final px = _detentPx(m);
    var i = 0;
    for (var k = 0; k < px.length; k++) {
      if ((px[k] - m.offset).abs() < (px[i] - m.offset).abs()) i = k;
    }
    _go(px.length == 1 ? 0 : (i + 1) % px.length);
  }

  void _step(int dir) {
    final m = ctl.metrics;
    if (m == null) return;
    final px = _detentPx(m);
    var i = 0;
    for (var k = 0; k < px.length; k++) {
      if ((px[k] - m.offset).abs() < (px[i] - m.offset).abs()) i = k;
    }
    _go((i + dir).clamp(0, px.length - 1));
  }

  void _go(int i) {
    _armed = true;
    _record(MotionName.sheetSnap.label, 342);
    _programmatic = true;
    unawaited(ctl.animateTo(sheetOffsetOf(_grid.detents[i]), duration: const Duration(milliseconds: 342), curve: SpringCurve(gt.springSheetSnap)).whenComplete(() {
      _programmatic = false;
      _endRecord();
    }),);
  }

  // -- build ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final large = sheetLargePx(mq.size.height, mq.padding.top);
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final solid = ref.watch(glassA11yProvider.select((a) => a.solid));
    final r = SkinGlass.deviceCornerRadius(context);
    final driven = SheetOffsetDrivenAnimation(controller: ctl, initialValue: 0);

    final Widget scaffold = ValueListenableBuilder<GlassSheetStatus>(
      valueListenable: page.status ?? ValueNotifier(GlassSheetStatus.ready),
      builder: (context, status, _) => GlassSheetScaffold(
        title: page.title,
        centerTitle: page.centerTitle,
        leading: page.leading,
        trailing: page.trailing,
        titleFocus: _title,
        status: status,
        onRetry: page.onRetry,
        errorText: page.errorText ?? "Couldn't load this",
        emptyText: page.emptyText ?? 'Nothing here yet',
        onClose: route.buttonDismiss,
        onCycle: page.detents.length > 1 ? _cycle : null,
        onStepDetent: _step,
        body: AnimatedPadding(
          duration: const Duration(milliseconds: 342),
          curve: SpringCurve(gt.springSheetSnap),
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Builder(builder: page.builder),
        ),
      ),
    );

    final material = page.material;
    final surface = AnimatedBuilder(
      animation: driven,
      child: scaffold,
      builder: (context, child) {
        final p = driven.value;
        final q = ((p - 0.8) / 0.2).clamp(0.0, 1.0);
        final inset = kSheetInset * (1 - q);
        final solidTo = material == GlassSheetMaterial.monolith ? gt.glassSolid2 : gt.glassSolid1;
        final tier = material == GlassSheetMaterial.monolith && q < 1 ? GlassTierId.t5 : GlassTierId.t4;
        return Padding(
          padding: EdgeInsets.fromLTRB(inset, 0, inset, inset),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: -r * q,
                child: GlassLbBar(
                  fieldTerm: kOverlayFieldTerm,
                  builder: (context, lb) => SkinGlass(
                    key: const ValueKey('glass-sheet-surface'),
                    lb: lb,
                  tier: tier,
                  shape: GlassShape.superellipse(r),
                  layer: GlassLayerKind.overlays,
                  debugLabel: 'GlassSheet',
                  materialize: !reduced,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (q > 0)
                        IgnorePointer(
                          child: ClipRSuperellipse(
                            borderRadius: BorderRadius.circular(r),
                            child: ColoredBox(key: const ValueKey('glass-sheet-solid'), color: solidTo.withValues(alpha: solid ? 1 : q)),
                          ),
                        ),
                      Padding(padding: EdgeInsets.only(bottom: r * q), child: child),
                    ],
                  ),
                ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Widget content = SizedBox(key: _surfaceKey, height: large, child: surface);

    // Stacking (glass 15.3): a sheet with another over it drops to 70 % brightness; at `large` it scales to
    // 0.9165 and moves up 2 % of the screen height.
    final recede = GlassRecedeScope.maybeOf(context);
    if (recede != null) {
      content = ListenableBuilder(
        listenable: recede.count,
        child: content,
        builder: (context, child) {
          final e = _entry;
          if (e == null || !recede.hasAbove(e)) return child!;
          final atLarge = e.atLarge;
          Widget w = Stack(fit: StackFit.passthrough, children: [child!, const Positioned.fill(child: IgnorePointer(child: ColoredBox(key: ValueKey('glass-sheet-under-dim'), color: Color(0x4D000000))))]);
          if (atLarge && !reduced) {
            w = Transform.translate(
              offset: Offset(0, -0.02 * mq.size.height),
              child: Transform.scale(key: const ValueKey('glass-sheet-under-scale'), scale: 0.9165, alignment: Alignment.bottomCenter, child: w),
            );
          }
          return w;
        },
      );
    }

    return GlassLitOverlay(
      child: FocusScope(
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: page.title,
          child: AnimatedBuilder(
            animation: _fade,
            child: NotificationListener<SheetNotification>(
              onNotification: _onNotification,
              child: Sheet(
                controller: ctl,
                initialOffset: reduced ? sheetOffsetOf(page.opening) : const SheetOffset(0),
                physics: GlassSheetPhysics(reduced: reduced),
                snapGrid: _grid,
                scrollConfiguration: const SheetScrollConfiguration(),
                child: content,
              ),
            ),
            builder: (context, child) => reduced
                ? Opacity(opacity: _fade.value, child: Transform.translate(offset: Offset(0, 16 * (1 - _fade.value)), child: child))
                : child!,
          ),
        ),
      ),
    );
  }
}
