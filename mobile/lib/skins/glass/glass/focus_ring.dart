import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The two-tone focus ring (glass 2.6, 14.4): a 2 px `#000000` ring around the shape, a 2 px `iris300`
/// ring outside it (3 px under Increase Contrast) and a 6 px glow. Never masked: it is a
/// `foregroundPainter` on the widget that WRAPS the clipped glass, outside `ClipRSuperellipse`.
class GlassFocusPainter extends CustomPainter {
  const GlassFocusPainter({required this.shape, required this.opacity, this.highContrast = false});

  final GlassShape shape;
  final double opacity;
  final bool highContrast;

  static const Color glow = Color(0x47BCB0FF);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final rect = Offset.zero & size;
    final iris = glassTokens.colorIris300;
    final irisW = highContrast ? 3.0 : 2.0;
    Paint stroke(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c.withValues(alpha: c.a * opacity);
    // Glow first, then the iris ring, then the black ring next to the glass.
    canvas.drawPath(
      shape.path(rect.inflate(2 + irisW + 3)),
      stroke(glow, 6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(shape.path(rect.inflate(2 + irisW / 2)), stroke(iris, irisW));
    canvas.drawPath(shape.path(rect.inflate(1)), stroke(const Color(0xFF000000), 2));
  }

  @override
  bool shouldRepaint(GlassFocusPainter old) => old.shape != shape || old.opacity != opacity || old.highContrast != highContrast;
}

/// Shows [GlassFocusPainter] around [child] while a descendant has keyboard focus.
class GlassFocusRing extends ConsumerStatefulWidget {
  const GlassFocusRing({super.key, required this.shape, required this.child, this.forceVisible = false});

  final GlassShape shape;
  final Widget child;

  /// For captures and tests that need the ring without a hardware keyboard.
  final bool forceVisible;

  @override
  ConsumerState<GlassFocusRing> createState() => _GlassFocusRingState();
}

class _GlassFocusRingState extends ConsumerState<GlassFocusRing> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  bool _focused = false;

  bool get _traditional => FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  void _sync() {
    final show = widget.forceVisible || (_focused && _traditional);
    if (show) {
      _fade.forward();
    } else {
      _fade.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  void _onMode(FocusHighlightMode _) => _sync();

  @override
  void didUpdateWidget(GlassFocusRing old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onMode);
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hc = ref.watch(glassA11yProvider.select((a) => a.increaseContrast));
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) {
        _focused = f;
        _sync();
      },
      child: AnimatedBuilder(
        animation: _fade,
        builder: (context, child) => CustomPaint(
          foregroundPainter: GlassFocusPainter(shape: widget.shape, opacity: _fade.value, highContrast: hc),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
