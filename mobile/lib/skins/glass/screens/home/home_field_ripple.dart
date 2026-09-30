import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/glass/palette.dart' show fieldColours;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';

/// The field ripple of Home's first paint (glass 4.10): a ring between the field and the content, 12 % brighter than the field, expanding
/// from the spotlight card's centre to the farthest screen corner over 600 ms on `curveFadeIn` while its opacity falls to 0. None under
/// reduced motion.
class HomeFieldRipple extends ConsumerStatefulWidget {
  const HomeFieldRipple({super.key, required this.palette, required this.origin, this.fieldOpacity = 0.26});
  final CoverPalette? palette;

  /// The spotlight card's centre in global coordinates.
  final Offset origin;
  final double fieldOpacity;

  @override
  ConsumerState<HomeFieldRipple> createState() => _HomeFieldRippleState();
}

class _HomeFieldRippleState extends ConsumerState<HomeFieldRipple> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _done = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await GlassMotion.play(MotionName.fieldRipple, controller: _c, target: 1);
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final base = fieldColours(widget.palette, moodColour(Mood.neutral)).colors.first;
    final colour = base.withValues(alpha: (widget.fieldOpacity + 0.12).clamp(0.0, 1.0));
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(size: Size.infinite, painter: RipplePainter(origin: widget.origin, t: _c.value, colour: colour)),
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  const RipplePainter({required this.origin, required this.t, required this.colour});
  final Offset origin;
  final double t;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final far = [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)].map((c) => (c - origin).distance).reduce((a, b) => a > b ? a : b);
    canvas.drawCircle(
      origin,
      far * t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = colour.withValues(alpha: colour.a * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(RipplePainter old) => old.t != t || old.origin != origin || old.colour != colour;
}
