import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// The pool of light beneath the one lit (tinted) object (glass 2.4.4): a `BlendMode.screen` ellipse
/// 1.2 x 0.7 of the object's size, offset `causticOffset` along the light, `iris500` at 0.14 (0.22 while
/// pressed), blurred by σ 18.
class GlassCausticPainter extends CustomPainter {
  const GlassCausticPainter({required this.alpha, required this.angle});

  final double alpha;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0) return;
    const t = glassTokens;
    final centre = size.center(Offset.zero) + lightDirection(angle) * t.causticOffset;
    final ellipse = Rect.fromCenter(center: centre, width: size.width * 1.2, height: size.height * 0.7);
    canvas.drawOval(
      ellipse,
      Paint()
        ..blendMode = BlendMode.screen
        ..color = t.colorIris500.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, t.causticBlur),
    );
  }

  @override
  bool shouldRepaint(GlassCausticPainter old) => old.alpha != alpha || old.angle != angle;
}

/// Wraps the lit object. Nothing under Solid glass or when the object floats over nothing.
class GlassCaustic extends ConsumerWidget {
  const GlassCaustic({super.key, required this.child, this.pressed = false, this.overContent = true});

  final Widget child;
  final bool pressed;
  final bool overContent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solid = ref.watch(glassA11yProvider.select((a) => a.solid));
    if (solid || !overContent) return child;
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final angle = ref.watch(glassLightAngleProvider).valueOrNull ?? kLightAngleRest;
    const t = glassTokens;
    // No press brightening under reduced motion.
    final target = pressed && !reduced ? t.causticAlphaPressed : t.causticAlpha;
    final duration = reduced ? Duration.zero : (pressed ? t.curveGlowIn.duration : t.curveGlowOut.duration);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: duration,
      builder: (context, alpha, child) => CustomPaint(painter: GlassCausticPainter(alpha: alpha, angle: angle), child: child),
      child: child,
    );
  }
}
