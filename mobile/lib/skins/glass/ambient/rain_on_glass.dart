import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';

/// One droplet in unit space (fractions of the surface's width and height): where its run started, its radius in logical px, its age.
class Droplet {
  Droplet({required this.x0, required this.y0, required this.radius, required this.phase, required this.travel});
  final double x0, y0, radius, phase;

  /// How far (a fraction of the height) the run falls in [RainSim.run].
  final double travel;
  double age = 0;

  /// The run's progress along a gravity path: `t^2`.
  double get fall => travel * math.pow(age / RainSim.run.inMicroseconds * 1e6, 2).toDouble().clamp(0.0, 1.0);

  double get y => y0 + fall;

  /// A 15 % lateral wobble: at most 0.15 of the height travelled so far.
  double get x => x0 + 0.15 * fall * math.sin(phase + 3 * age);
}

/// The rain (glass 9.4.2): 6 to 10 droplets of radius 3 to 6 px, each running 4 s down a gravity path with a 15 % lateral wobble from a
/// random start, a new one every 0.6 s up to the cap of 10. Pure, so it runs under `flutter test`.
class RainSim {
  RainSim({int seed = 4}) : _r = math.Random(seed);

  static const Duration run = Duration(seconds: 4), spawn = Duration(milliseconds: 600);
  static const int cap = 10;

  final math.Random _r;
  final List<Droplet> drops = [];
  Duration _sinceSpawn = spawn; // the first droplet is immediate
  int spawned = 0;

  /// Advances by [dt]; returns the droplets spawned in it.
  List<Droplet> advance(Duration dt) {
    final born = <Droplet>[];
    for (final d in drops) {
      d.age += dt.inMicroseconds / 1e6;
    }
    drops.removeWhere((d) => d.age >= run.inMicroseconds / 1e6);
    _sinceSpawn += dt;
    while (_sinceSpawn >= spawn && drops.length < cap) {
      _sinceSpawn -= spawn;
      final y0 = _r.nextDouble() * 0.6;
      final d = Droplet(
        x0: 0.08 + _r.nextDouble() * 0.84,
        y0: y0,
        radius: 3 + _r.nextDouble() * 3,
        phase: _r.nextDouble() * 2 * math.pi,
        travel: 0.4 + _r.nextDouble() * 0.5,
      );
      drops.add(d);
      born.add(d);
      spawned++;
    }
    if (drops.length >= cap) _sinceSpawn = Duration.zero;
    return born;
  }
}

/// The program, loaded once.
abstract final class RainShader {
  static Future<ui.FragmentProgram>? _program;
  static Future<ui.FragmentProgram> load() => _program ??= ui.FragmentProgram.fromAsset('lib/skins/glass/shaders/rain_on_glass.frag');
}

/// Owns the one clock and the one layer registration of the rain, and hands both to every [RainOnGlass] below it. It counts as one extra
/// Flutter layer while it runs (glass 15.7). [active] is decided by the screen: the Rain scene is playing, the chrome is visible, and
/// Reduce Motion, Reduce Transparency and Solid glass are all off.
class RainOnGlassHost extends ConsumerStatefulWidget {
  const RainOnGlassHost({super.key, required this.active, required this.light, required this.child});
  final bool active;

  /// The live light angle in radians.
  final double light;
  final Widget child;

  @override
  ConsumerState<RainOnGlassHost> createState() => _RainOnGlassHostState();
}

class _RainOnGlassHostState extends ConsumerState<RainOnGlassHost> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final RainSim sim = RainSim();
  final ValueNotifier<int> frame = ValueNotifier(0);
  late final Ticker _ticker = createTicker(_tick);
  late final GlassRegistryController _registry = ref.read(glassRegistryProvider.notifier);
  Duration? _last;
  double time = 0;
  int? _regId;
  bool _background = false;

  bool get _running => widget.active && !_background;

  @override
  void initState() {
    super.initState();
    _registry;
    WidgetsBinding.instance.addObserver(this);
    _sync();
  }

  @override
  void didUpdateWidget(RainOnGlassHost old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (_running) {
      if (!_ticker.isActive) {
        _last = null;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
    // The registry notifies listeners, which is not allowed while the tree builds: after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = _regId;
      if (_running && id == null) {
        final next = _regId = _registry.newId();
        // One extra layer, no shapes of its own: the filter runs inside the capsules' own bounds.
        _registry.registerSafe(GlassRegistration(id: next, label: 'rain on glass', kind: GlassLayerKind.hud, shapes: 0, rect: () => null));
      } else if (!_running && id != null) {
        _regId = null;
        _registry.unregisterSafe(id);
      }
    });
  }

  void _tick(Duration t) {
    final prev = _last;
    _last = t;
    if (prev == null) return;
    final dt = t - prev;
    time += dt.inMicroseconds / 1e6;
    sim.advance(dt > const Duration(milliseconds: 100) ? const Duration(milliseconds: 16) : dt);
    frame.value++;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    final id = _regId, registry = _registry;
    if (id != null) Future<void>.microtask(() => registry.unregisterSafe(id));
    frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _RainScope(host: this, running: _running, light: widget.light, child: widget.child);
}

class _RainScope extends InheritedWidget {
  const _RainScope({required this.host, required this.running, required this.light, required super.child});
  final _RainOnGlassHostState host;
  final bool running;
  final double light;

  @override
  bool updateShouldNotify(_RainScope old) => old.running != running || old.light != light;
}

/// Wraps one capsule's glass: a `ClipRSuperellipse` over the capsule's own radius, then a `BackdropFilter(ImageFilter.shader)` that
/// refracts the droplets. Draws only where `ImageFilter.isShaderFilterSupported` (Impeller). Without a [RainOnGlassHost] above, or while
/// it is not running, it is just [child].
///
/// Coordinate space: `FlutterFragCoord()` and `uDrops` are device pixels of the filter input (the backdrop clipped to this surface), so
/// a droplet at unit position (u, v) sits at `(u w, v h) x devicePixelRatio` and its radius is scaled the same way.
class RainOnGlass extends StatelessWidget {
  const RainOnGlass({super.key, required this.radius, required this.child});
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RainScope>();
    if (scope == null || !scope.running || !ui.ImageFilter.isShaderFilterSupported) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ClipRSuperellipse(
                borderRadius: radius,
                child: _RainFilter(host: scope.host, light: scope.light),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RainFilter extends StatefulWidget {
  const _RainFilter({required this.host, required this.light});
  final _RainOnGlassHostState host;
  final double light;

  @override
  State<_RainFilter> createState() => _RainFilterState();
}

class _RainFilterState extends State<_RainFilter> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    RainShader.load().then((p) {
      if (mounted) setState(() => _shader = p.fragmentShader());
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) return const SizedBox.expand();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) => ValueListenableBuilder<int>(
        valueListenable: widget.host.frame,
        builder: (context, _, __) {
          final w = box.maxWidth * dpr, h = box.maxHeight * dpr;
          shader.setFloat(2, widget.host.time);
          final drops = widget.host.sim.drops;
          for (var i = 0; i < RainSim.cap; i++) {
            final base = 3 + i * 3;
            if (i < drops.length) {
              final d = drops[i];
              shader
                ..setFloat(base, d.x * w)
                ..setFloat(base + 1, d.y * h)
                ..setFloat(base + 2, d.radius * dpr);
            } else {
              shader
                ..setFloat(base, 0)
                ..setFloat(base + 1, 0)
                ..setFloat(base + 2, 0);
            }
          }
          shader.setFloat(33, widget.light);
          return BackdropFilter(filter: ui.ImageFilter.shader(shader), child: const SizedBox.expand());
        },
      ),
    );
  }
}
