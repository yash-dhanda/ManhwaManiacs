import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The effects that must survive a router reset, so they live above the router in the app builder: the profile hand-off flight
/// (an orb flying from its menu row to the dock or sidebar, glass 8.25.2) and the skin melt (glass 4.10).
class GlassEffectsController {
  _GlassEffectsLayerState? _layer;

  /// Flies [orb] from [from] to [to] on `springZoom` (reduced: a 200 ms cross-fade). Completes when it lands.
  Future<void> flyOrb(
          {required Rect from, required Rect to, required Widget orb,}) =>
      _layer?._fly(from, to, orb) ?? Future.value();

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
  _Flight(this.from, this.to, this.orb, this.controller, this.done);
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

  @override
  void initState() {
    super.initState();
    ref.read(glassEffectsProvider)._layer = this;
  }

  @override
  void dispose() {
    final c = ref.read(glassEffectsProvider);
    if (c._layer == this) c._layer = null;
    for (final f in _flights) {
      f.controller.dispose();
    }
    _meltC.dispose();
    super.dispose();
  }

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  Future<void> _fly(Rect from, Rect to, Widget orb) {
    final c = AnimationController(vsync: this);
    final f = _Flight(from, to, orb, c, Completer<void>());
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
            final blur = 40 * Curves.easeOut.transform(t);
            final size = MediaQuery.sizeOf(context);
            final diag =
                math.sqrt(size.width * size.width + size.height * size.height) /
                    2;
            final r = diag * (1 - Curves.easeInOutCubic.transform(t));
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
