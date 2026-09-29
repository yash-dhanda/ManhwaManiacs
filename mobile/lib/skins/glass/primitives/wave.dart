import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:motor/motor.dart';

/// glass 4.8: `delay_i = min(distance_i / 1.6 px/ms, 240 ms)` from the cause point. Items outside the
/// viewport get `null` (no entrance).
Map<int, Duration?> waveDelays(List<Rect> items, Offset cause, Rect viewport) {
  final out = <int, Duration?>{};
  for (var i = 0; i < items.length; i++) {
    final r = items[i];
    if (!r.overlaps(viewport)) {
      out[i] = null;
      continue;
    }
    final ms = math.min((r.center - cause).distance / GlassPhysics.waveSpeed, GlassPhysics.waveMaxDelay);
    out[i] = Duration(microseconds: (ms * 1000).round());
  }
  return out;
}

/// The entrance wave (glass 4.8): each item enters by `GlassMotion` (the Wave row): opacity 0 to 1 over
/// `curveFadeIn`, a 12 px translate toward rest from the cause's direction and scale 0.98 to 1 on
/// `springSnappy`, [waveDelays] after the cause. Exits never stagger. Reduced motion: everything fades
/// together over 150 ms. Items outside the viewport get no entrance.
class GlassWave extends ConsumerStatefulWidget {
  const GlassWave({super.key, required this.children, required this.cause, this.layout = _column, this.enabled = true});

  final List<Widget> children;

  /// The touch point for taps, the source element's centre for route arrivals, the top-left of the list
  /// for data arrivals (global coordinates).
  final Offset cause;
  final Widget Function(List<Widget> items) layout;
  final bool enabled;

  static Widget _column(List<Widget> items) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: items);

  @override
  ConsumerState<GlassWave> createState() => _GlassWaveState();
}

class _GlassWaveState extends ConsumerState<GlassWave> {
  late List<GlobalKey<_WaveItemState>> _keys = List.generate(widget.children.length, (_) => GlobalKey<_WaveItemState>());
  bool _started = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    if (widget.enabled) WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void didUpdateWidget(GlassWave old) {
    super.didUpdateWidget(old);
    if (old.children.length != widget.children.length) {
      _keys = List.generate(widget.children.length, (_) => GlobalKey<_WaveItemState>());
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _run() {
    if (!mounted || _started) return;
    _started = true;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    final rects = <Rect>[];
    for (final k in _keys) {
      final ro = k.currentContext?.findRenderObject();
      rects.add(ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero);
    }
    final size = MediaQuery.sizeOf(context);
    final delays = waveDelays(rects, widget.cause, Offset.zero & size);
    for (var i = 0; i < _keys.length; i++) {
      final item = _keys[i].currentState;
      if (item == null) continue;
      final d = delays[i];
      if (d == null) {
        item.show();
      } else if (reduced) {
        item.fade();
      } else {
        final dir = widget.cause - rects[i].center;
        final unit = dir.distance == 0 ? Offset.zero : dir / dir.distance;
        _timers.add(Timer(d, () => item.enter(unit * 12)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.layout([
        for (var i = 0; i < widget.children.length; i++) _WaveItem(key: _keys[i], initiallyShown: !widget.enabled, child: widget.children[i]),
      ]);
}

class _WaveItem extends StatefulWidget {
  const _WaveItem({super.key, required this.child, required this.initiallyShown});
  final Widget child;
  final bool initiallyShown;

  @override
  State<_WaveItem> createState() => _WaveItemState();
}

class _WaveItemState extends State<_WaveItem> with TickerProviderStateMixin {
  late final SingleMotionController _c = SingleMotionController(motion: SpringMotion(springOf(glassTokens.springSnappy)), vsync: this, initialValue: widget.initiallyShown ? 1 : 0);
  late final AnimationController _f = AnimationController(vsync: this, duration: glassTokens.curveFadeIn.duration, value: widget.initiallyShown ? 1 : 0);
  Offset _from = Offset.zero;

  void show() {
    _c.value = 1;
    _f.value = 1;
  }

  void fade() {
    _c.value = 1;
    _f.animateTo(1, duration: glassTokens.curveReducedCrossfade.duration);
  }

  void enter(Offset from) {
    _from = from;
    unawaited(_f.animateTo(1, curve: glassTokens.curveFadeIn.curve));
    unawaited(GlassMotion.playMotor(MotionName.wave, _c, 1));
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([_c, _f]),
        child: widget.child,
        builder: (context, child) {
          final v = _c.value;
          return Opacity(
            opacity: _f.value.clamp(0.0, 1.0),
            child: Transform.translate(offset: _from * (1 - v), child: Transform.scale(scale: 0.98 + 0.02 * v, child: child)),
          );
        },
      );
}
