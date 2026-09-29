import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

const GlassTokens gt = glassTokens;

/// One answer to "is motion reduced" (glass 4.11): the OS flag merged with the in-app switch.
bool glassReduced(WidgetRef ref) => ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));

/// The reduced-motion answer as a provider selection, for widgets that watch it in `build`.
final glassReducedProvider = Provider<bool>((ref) => ref.watch(glassMotionPrefsProvider.select((m) => m.reduced)));

bool glassSolid(WidgetRef ref) => ref.watch(glassA11yProvider.select((a) => a.solid));

/// Fires a haptic through the Glass haptics (rate limited and logged in debug).
void glassFire(WidgetRef ref, HapticEvent e, {double? velocity}) {
  unawaited(ref.read(glassHapticsProvider).fire(e, velocity: velocity));
}

/// Announces a transient error assertively (glass 14).
void announceAssertive(BuildContext context, String message) {
  try {
    unawaited(SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
      assertiveness: Assertiveness.assertive,
    ),);
  } catch (_) {}
}

/// `x(t) = A * e^(-t / 90 ms) * sin(2 pi * 7 Hz * t)` for 420 ms (glass 4.10, Error shake).
double shakeOffset(double tMs, {double amplitude = 8}) =>
    tMs >= 420 ? 0 : amplitude * math.exp(-tMs / 90) * math.sin(2 * math.pi * 7 * tMs / 1000);

/// Shakes its child every time [trigger] increases. None under reduced motion.
class GlassShake extends ConsumerStatefulWidget {
  const GlassShake({super.key, required this.trigger, required this.child, this.amplitude = 8});
  final int trigger;
  final double amplitude;
  final Widget child;

  @override
  ConsumerState<GlassShake> createState() => _GlassShakeState();
}

class _GlassShakeState extends ConsumerState<GlassShake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(GlassShake old) {
    super.didUpdateWidget(old);
    if (widget.trigger > old.trigger && !ref.read(glassMotionPrefsProvider).reduced) {
      final e = GlassMotion.recorder.begin(MotionName.errorShake.label, 420);
      _c.forward(from: 0).whenComplete(() => GlassMotion.recorder.end(e));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(_c.isAnimating ? shakeOffset(_c.value * 420, amplitude: widget.amplitude) : 0, 0),
          child: child,
        ),
      );
}

/// A glyph on the backing disc (glass 2.1.2): 28 px behind a 22 px glyph, 20 px behind a 16 px glyph.
class GlassBacking extends StatelessWidget {
  const GlassBacking({super.key, required this.size, required this.child});
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: gt.colorBackingDisc, shape: BoxShape.circle),
        child: child,
      );
}

/// The natural size of a single-style text (the same scaled style GlassText draws).
Size measureText(BuildContext context, String text, TextStyle style, {double maxWidth = double.infinity, int maxLines = 1}) {
  final p = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  final s = p.size;
  p.dispose();
  return s;
}

TextStyle roleStyle(BuildContext context, GlassTypeRole role, {bool onGlass = false, bool legible = false, int? wght, double? size, double? height, double maxScale = double.infinity}) =>
    GlassTypeStyle.style(context, role, onGlass: onGlass, legible: legible, wght: wght, size: size, height: height, maxScale: maxScale);

/// Parses `#RRGGBB` style constants written in this step's spec.
Color hexColor(int rgb, [double opacity = 1]) => Color(0xFF000000 | rgb).withValues(alpha: opacity);

/// The two colour-blind safe helpers the spec repeats: a colour at 18 % over black with the colour as text.
Color wash(Color c, [double a = 0.18]) => c.withValues(alpha: a);

/// Plays a sound (off by default; the skin's audio service decides) without ever throwing into a gesture.
void glassSound(WidgetRef ref, SoundEvent e) {
  try {
    unawaited(ref.read(skinAudioProvider).play(e));
  } catch (_) {}
}
