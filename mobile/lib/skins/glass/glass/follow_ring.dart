import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// Plays the follow ring over a host: `GlassFollowRing.play(bandRect, origin)` (glass 2.4.4).
class GlassFollowRingController extends ChangeNotifier {
  Rect? _band;
  Offset? _origin;
  int _serial = 0;

  Rect? get band => _band;
  Offset? get origin => _origin;
  int get serial => _serial;

  /// [bandRect] and [origin] are in the host's local coordinates.
  void play(Rect bandRect, Offset origin) {
    _band = bandRect;
    _origin = origin;
    _serial++;
    notifyListeners();
  }
}

/// A ring centred on the origin: radius 0 to the distance to the band's far corner, stroke 2 to 24 px,
/// `iris300` at 30 % fading to 0, blurred by σ 6, `BlendMode.screen`, clipped to the band, 700 ms.
class GlassFollowRingPainter extends CustomPainter {
  const GlassFollowRingPainter({required this.band, required this.origin, required this.t});

  final Rect band;
  final Offset origin;
  final double t;

  static double farDistance(Rect band, Offset origin) => [band.topLeft, band.topRight, band.bottomLeft, band.bottomRight]
      .map((c) => (c - origin).distance)
      .reduce(math.max);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    canvas.save();
    canvas.clipRect(band);
    canvas.drawCircle(
      origin,
      farDistance(band, origin) * t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 22 * t
        ..blendMode = BlendMode.screen
        ..color = glassTokens.colorIris300.withValues(alpha: 0.30 * (1 - t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassFollowRingPainter old) => old.t != t || old.band != band || old.origin != origin;
}

class GlassFollowRing extends ConsumerStatefulWidget {
  const GlassFollowRing({super.key, required this.controller, required this.child});

  final GlassFollowRingController controller;
  final Widget child;

  @override
  ConsumerState<GlassFollowRing> createState() => _GlassFollowRingState();
}

class _GlassFollowRingState extends ConsumerState<GlassFollowRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: glassTokens.curveFollowRing.duration);

  void _onPlay() {
    if (ref.read(glassMotionPrefsProvider).reduced) return; // Reduced motion: none.
    _c.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPlay);
  }

  @override
  void didUpdateWidget(GlassFollowRing old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onPlay);
      widget.controller.addListener(_onPlay);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlay);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = glassTokens.curveFollowRing.curve;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final band = widget.controller.band, origin = widget.controller.origin;
        return CustomPaint(
          foregroundPainter: band == null || origin == null
              ? null
              : GlassFollowRingPainter(band: band, origin: origin, t: curve.transform(_c.value)),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
