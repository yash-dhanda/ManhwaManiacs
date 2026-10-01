import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show springOf;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart' show GlassSprings;

/// The effects that must survive a router reset, so they live above the router in the app builder: the profile hand-off flight
/// (an orb flying from its menu row to the dock or sidebar, glass 8.25.2) and the skin melt (glass 4.10).
class GlassEffectsController {
  _GlassEffectsLayerState? _layer;

  /// Flies [orb] from [from] to [to] on `springZoom` (reduced: a 200 ms cross-fade). Completes when it lands.
  Future<void> flyOrb(
          {required Rect from, required Rect to, required Widget orb, bool tail = false,}) =>
      _layer?._fly(from, to, orb, tail: tail) ?? Future.value();

  /// The Skin melt, 615 ms: every live glass surface dematerialises (350 ms), the root blurs 0 to 40 px, a circular clip closes from
  /// the screen diagonal to the centre over black. Reduced: a 200 ms fade to black.
  Future<void> playMelt() => _layer?._melt() ?? Future.value();

  /// Reverses the melt over 200 ms.
  Future<void> unmelt() => _layer?._unmelt() ?? Future.value();

  bool get melted => _layer?._meltC.value == 1;
}

final glassEffectsProvider =
    Provider<GlassEffectsController>((ref) => GlassEffectsController());

/// Wraps the router in the Glass root: hosts [GlassEffectsController].
class GlassEffectsLayer extends ConsumerStatefulWidget {
  const GlassEffectsLayer({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassEffectsLayer> createState() => _GlassEffectsLayerState();
}

class _Flight {
  _Flight(this.from, this.to, this.orb, this.controller, this.done, {this.tail = false});
  final bool tail;
  final Rect from;
  final Rect to;
  final Widget orb;
  final AnimationController controller;
  final Completer<void> done;
}

class _GlassEffectsLayerState extends ConsumerState<GlassEffectsLayer>
    with TickerProviderStateMixin {
  late final AnimationController _meltC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 615),);
  final List<_Flight> _flights = [];

  late final GlassEffectsController _controller = ref.read(glassEffectsProvider);

  @override
  void initState() {
    super.initState();
    _controller._layer = this;
  }

  @override
  void dispose() {
    if (_controller._layer == this) _controller._layer = null;
    for (final f in _flights) {
      f.controller.dispose();
    }
    _meltC.dispose();
    super.dispose();
  }

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  Future<void> _fly(Rect from, Rect to, Widget orb, {bool tail = false}) {
    final c = AnimationController(vsync: this);
    final f = _Flight(from, to, orb, c, Completer<void>(), tail: tail);
    setState(() => _flights.add(f));
    unawaited(
      GlassMotion.play(MotionName.zoom, controller: c, target: 1)
          .whenComplete(() {
        if (!mounted) return;
        setState(() => _flights.remove(f));
        c.dispose();
        f.done.complete();
      }),
    );
    return f.done.future;
  }

  Future<void> _melt() async {
    if (_reduced) {
      _meltC.duration = const Duration(milliseconds: 200);
      await _meltC.forward();
      return;
    }
    _meltC.duration = const Duration(milliseconds: 615);
    unawaited(dematerializeAllGlass());
    await GlassMotion.play(MotionName.skinMelt, controller: _meltC, target: 1);
  }

  Future<void> _unmelt() async {
    await _meltC.animateBack(0, duration: const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _meltC,
          child: widget.child,
          builder: (context, child) {
            final t = _meltC.value;
            if (t == 0) return child!;
            if (_reduced) {
              return Stack(fit: StackFit.expand, children: [
                child!,
                Positioned.fill(
                    child: ColoredBox(color: Color.fromRGBO(0, 0, 0, t)),),
              ],);
            }
            final m = glassMeltAt(t);
            final blur = 40 * m.blur;
            final size = MediaQuery.sizeOf(context);
            final diag =
                math.sqrt(size.width * size.width + size.height * size.height) /
                    2;
            final r = diag * (1 - m.mask);
            return Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                        sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal,),
                    child: child,),
                Positioned.fill(
                    child: IgnorePointer(
                        child: CustomPaint(painter: _IrisPainter(radius: r)),),),
              ],
            );
          },
        ),
        for (final f in _flights)
          if (f.tail && !_reduced)
            AnimatedBuilder(
              animation: f.controller,
              builder: (context, _) => IgnorePointer(
                child: CustomPaint(
                  painter: MeniscusTailPainter(from: f.from.center, to: Rect.lerp(f.from, f.to, f.controller.value)!.center, width: 12, fade: (1 - ((f.controller.value - 0.46) / 0.54).clamp(0.0, 1.0))),
                  size: Size.infinite,
                ),
              ),
            ),
        for (final f in _flights)
          AnimatedBuilder(
            animation: f.controller,
            builder: (context, _) {
              final t = _reduced ? 1.0 : f.controller.value;
              final rect = Rect.lerp(f.from, f.to, t)!;
              final fade = _reduced ? f.controller.value : 1.0;
              return Positioned.fromRect(
                  rect: rect,
                  child: IgnorePointer(
                      child: Opacity(
                          opacity: fade,
                          child: FittedBox(
                              child: SizedBox.fromSize(
                                  size: f.to.size, child: f.orb,),),),),);
            },
          ),
      ],
    );
  }
}

class _IrisPainter extends CustomPainter {
  const _IrisPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(
          Rect.fromCircle(center: size.center(Offset.zero), radius: radius),);
    canvas.drawPath(path, Paint()..color = const Color(0xFF000000));
  }

  @override
  bool shouldRepaint(_IrisPainter old) => old.radius != radius;
}

/// The meniscus tail of a profile flight (glass 4.10): a tapered path from the origin to the orb, [width] px at the orb tapering to 0,
/// `iris400` at 30 %, fading with [fade].
class MeniscusTailPainter extends CustomPainter {
  const MeniscusTailPainter({required this.from, required this.to, required this.width, required this.fade});
  final Offset from;
  final Offset to;
  final double width;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    final d = to - from;
    final len = d.distance;
    if (len < 1 || fade <= 0) return;
    final n = Offset(-d.dy, d.dx) / len * (width / 2);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx + n.dx, to.dy + n.dy)
      ..lineTo(to.dx - n.dx, to.dy - n.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFA99BFF).withValues(alpha: 0.3 * fade));
  }

  @override
  bool shouldRepaint(MeniscusTailPainter old) => old.from != from || old.to != to || old.fade != fade || old.width != width;
}

final SpringSimulation _meltBlur = SpringSimulation(springOf(GlassSprings.smooth), 0, 1, 0);
final SpringSimulation _meltMask = SpringSimulation(springOf(GlassSprings.page), 0, 1, 0);

/// The skin melt at linear progress [t] (0..1 over 615 ms, glass 4.10 Skin melt): the blur rides `smooth` (0 -> 40 px) and the
/// circular mask rides `page`, whose settle ends the melt. Both 0..1.
({double blur, double mask}) glassMeltAt(double t) {
  final s = t * 0.615;
  return (blur: _meltBlur.x(s).clamp(0.0, 1.0), mask: t >= 1 ? 1.0 : _meltMask.x(s).clamp(0.0, 1.0));
}
