import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_physics.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// What `onRefresh()` found: `changed` fills the spinner into a check (the caller runs the entrance wave for the new
/// rows), `unchanged` fades.
enum RefreshResult { changed, unchanged }

/// The scroll physics of a refreshable Glass list: bouncing on both platforms (glass 7.33).
const ScrollPhysics kGlassRefreshPhysics = BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

/// `R` on hardware keyboards and a Refresh item in a screen's menu call [refresh].
class GlassPullToRefreshController {
  _GlassPullToRefreshState? _state;
  final ValueNotifier<bool> refreshing = ValueNotifier(false);

  /// Runs the same refresh pipeline as a pull (spinner, announcement, haptics) without the pull.
  Future<void> refresh() => _state?._run() ?? Future.value();

  void dispose() => refreshing.dispose();
}

enum _Phase { idle, refreshing, changed, unchanged }

/// Pull to refresh (glass 7.33), built on `CupertinoSliverRefreshControl(refreshTriggerPullDistance: 100,
/// refreshIndicatorExtent: 60)` with bouncing physics on both platforms (a debug assert checks the scroll view bounces).
/// A `glassThin` droplet hangs from the top edge on a meniscus neck: its radius grows 0 to 16 px over the first 60 px,
/// the neck is `12 x (1 - progress)` px and the `droplet` glyph turns 360 degrees per 100 px. At 100 px the neck snaps:
/// the droplet pops free (`refresh.arm`), springs to the 60 px rest line on `springLens` and becomes a liquid ring
/// spinner while `onRefresh()` runs (`refresh.fire`, no haptic). Done: a check on `changed` (`refresh.done`), a fade on
/// `unchanged`; a polite announcement says "Updated", or the error. Reduced motion: a static spinner at the rest line.
class GlassPullToRefresh extends ConsumerStatefulWidget {
  const GlassPullToRefresh({super.key, required this.onRefresh, this.controller});
  final Future<RefreshResult> Function() onRefresh;
  final GlassPullToRefreshController? controller;

  @override
  ConsumerState<GlassPullToRefresh> createState() => _GlassPullToRefreshState();
}

class _GlassPullToRefreshState extends ConsumerState<GlassPullToRefresh> {
  final ValueNotifier<_Phase> _phase = ValueNotifier(_Phase.idle);
  bool _armedFired = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _phase.dispose();
    super.dispose();
  }

  void _announce(String message) {
    try {
      unawaited(SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context)));
    } catch (_) {}
  }

  Future<void> _run() async {
    glassFire(ref, HapticEvent.refreshFire);
    widget.controller?.refreshing.value = true;
    _phase.value = _Phase.refreshing;
    try {
      final r = await widget.onRefresh();
      if (!mounted) return;
      if (r == RefreshResult.changed) {
        glassFire(ref, HapticEvent.refreshDone);
        _phase.value = _Phase.changed;
      } else {
        _phase.value = _Phase.unchanged;
      }
      _announce('Updated');
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) _announce("Couldn't refresh");
    } finally {
      if (mounted) {
        _phase.value = _Phase.idle;
        widget.controller?.refreshing.value = false;
      }
    }
    _armedFired = false;
  }

  @override
  Widget build(BuildContext context) => CupertinoSliverRefreshControl(
        refreshTriggerPullDistance: glassTokens.thresholdPullTrigger,
        refreshIndicatorExtent: glassTokens.thresholdPullRest,
        onRefresh: _run,
        builder: (context, mode, pulled, trigger, extent) {
          assert(() {
            final s = Scrollable.maybeOf(context);
            if (s != null && s.position.physics is! BouncingScrollPhysics) {
              throw FlutterError('GlassPullToRefresh needs a scroll view with BouncingScrollPhysics (use kGlassRefreshPhysics).');
            }
            return true;
          }());
          if (mode == RefreshIndicatorMode.armed && !_armedFired) {
            _armedFired = true;
            scheduleMicrotask(() {
              if (!mounted) return;
              glassFire(ref, HapticEvent.refreshArm);
              glassSound(ref, SoundEvent.refreshArm);
            });
          }
          if (mode == RefreshIndicatorMode.drag) _armedFired = false;
          return _Droplet(pulled: pulled, mode: mode, phase: _phase);
        },
      );
}

class _Droplet extends ConsumerStatefulWidget {
  const _Droplet({required this.pulled, required this.mode, required this.phase});
  final double pulled;
  final RefreshIndicatorMode mode;
  final ValueNotifier<_Phase> phase;

  @override
  ConsumerState<_Droplet> createState() => _DropletState();
}

class _DropletState extends ConsumerState<_Droplet> with SingleTickerProviderStateMixin {
  // The droplet's centre line: it follows the pull, then springs to the rest line on springLens.
  late final AnimationController _y = AnimationController.unbounded(vsync: this);
  bool _popped = false;
  GlassMotionEntry? _move;

  @override
  void didUpdateWidget(_Droplet old) {
    super.didUpdateWidget(old);
    final released = widget.mode == RefreshIndicatorMode.armed || widget.mode == RefreshIndicatorMode.refresh || widget.mode == RefreshIndicatorMode.done;
    if (released && !_popped) {
      _popped = true;
      _pop();
    } else if (!released && _popped && widget.mode != RefreshIndicatorMode.done) {
      _popped = false;
    }
    if (widget.mode == RefreshIndicatorMode.inactive) _popped = false;
  }

  void _pop() {
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    final rest = pullRestLine / 2;
    if (reduced) {
      _y.value = rest;
      return;
    }
    _move = GlassMotion.recorder.begin(MotionName.meniscusRefresh.label, 467);
    _y.animateWith(SpringSimulation(springOf(gt.springLens), _y.value, rest, 0)).whenComplete(() {
      if (_move != null) GlassMotion.recorder.end(_move!);
      _move = null;
    });
  }

  @override
  void dispose() {
    _y.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pulled;
    final armedOrBeyond = widget.mode == RefreshIndicatorMode.refresh || widget.mode == RefreshIndicatorMode.done || _popped;
    final r = dropletRadius(p);
    final followY = math.min(p * 0.55, 40.0);
    if (!armedOrBeyond) _y.value = followY;
    return ValueListenableBuilder<_Phase>(
      valueListenable: widget.phase,
      builder: (context, phase, _) => AnimatedBuilder(
        animation: _y,
        builder: (context, _) {
          final refreshing = phase != _Phase.idle || widget.mode == RefreshIndicatorMode.refresh || widget.mode == RefreshIndicatorMode.done;
          final cy = _y.value;
          final size = refreshing ? 32.0 : 2 * r;
          return SizedBox(
            key: const ValueKey('glass-pull'),
            height: p,
            child: ClipRect(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (!armedOrBeyond && p > 0)
                    Positioned.fill(child: CustomPaint(key: const ValueKey('glass-pull-neck'), painter: _NeckPainter(neck: neckWidth(p), cy: cy, r: r))),
                  if (size > 1)
                    Positioned(
                      top: cy - size / 2,
                      child: SkinGlass(
                        key: const ValueKey('glass-pull-droplet'),
                        size: Size.square(size),
                        tier: GlassTierId.t2,
                        shape: const GlassShape.circle(),
                        layer: GlassLayerKind.hud,
                        materialize: false,
                        debugLabel: 'GlassPullDroplet',
                        child: Center(child: _inside(phase, refreshing, p)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inside(_Phase phase, bool refreshing, double p) {
    if (phase == _Phase.changed) return const GlassCheckPop(size: 18);
    if (phase == _Phase.unchanged) return const SizedBox.shrink();
    if (refreshing) return const GlassSpinner(size: 20);
    return Transform.rotate(angle: glyphTurns(p) * 2 * math.pi, child: Icon(GlassGlyphs.dropletFill, size: math.max(6, 16 * dropletRadius(p) / 16), color: gt.colorOnGlass));
  }
}

class _NeckPainter extends CustomPainter {
  const _NeckPainter({required this.neck, required this.cy, required this.r});
  final double neck;
  final double cy;
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    if (neck <= 0.2) return;
    final cx = size.width / 2;
    final top = cy - r;
    final path = Path()
      ..moveTo(cx - neck / 2, 0)
      ..quadraticBezierTo(cx - neck / 4, top * 0.6, cx - math.min(neck / 3, 4), top + 2)
      ..lineTo(cx + math.min(neck / 3, 4), top + 2)
      ..quadraticBezierTo(cx + neck / 4, top * 0.6, cx + neck / 2, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = gt.colorFill2);
  }

  @override
  bool shouldRepaint(_NeckPainter old) => old.neck != neck || old.cy != cy || old.r != r;
}
