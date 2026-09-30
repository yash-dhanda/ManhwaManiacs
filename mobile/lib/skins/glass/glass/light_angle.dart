import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';

/// The pinned light: 135 degrees, down-right (glass 2.4.2 rule 5), in radians.
const double kLightAngleRest = 135 * math.pi / 180;
const double _range = 25 * math.pi / 180;

/// Tilt of 30 degrees sweeps the whole 25 degree range.
const double _tiltFull = 30 * math.pi / 180;

/// 135 degrees + 25 degrees x clamp(roll / 30 degrees, -1, 1).
double lightAngleForRoll(double rollRad) => kLightAngleRest + _range * (rollRad / _tiltFull).clamp(-1.0, 1.0);

/// Hover in a desktop-frame window: 135 degrees + 25 degrees x (x / width - 0.5) x 2.
double lightAngleForHover(double xFraction) => kLightAngleRest + _range * (xFraction - 0.5) * 2;

/// Pointer x as a fraction of the window width, or null when nothing hovers.
final glassHoverLightProvider = StateProvider<double?>((ref) => null);

/// The live light angle in radians. Auto-dispose: the sensor runs only while a Glass surface listens,
/// at 30 Hz, low-passed with alpha 0.15, pinned at 135 degrees under reduced motion, with the
/// "Light follows the device" preference off, and while the app is not resumed.
final glassLightAngleProvider = StreamProvider.autoDispose<double>((ref) {
  final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
  final follows = ref.watch(glassInAppPrefsProvider.select((p) => p.lightFollowsDevice));
  final hover = ref.watch(glassHoverLightProvider);
  if (reduced || !follows) return Stream.value(kLightAngleRest);
  if (hover != null) return Stream.value(lightAngleForHover(hover));

  // One shared accelerometer subscription (core/platform/gravity.dart) feeds the light and the genre field.
  final gravity = ref.watch(gravityProvider);
  final out = StreamController<double>();
  double last = kLightAngleRest;
  out.add(kLightAngleRest);
  final sub = gravity.stream.listen((g) {
    final roll = math.asin(g.dx.clamp(-1.0, 1.0));
    // Quantised to a quarter degree so a resting hand does not rebuild every surface at 30 Hz.
    final a = (lightAngleForRoll(roll) * 720 / math.pi).roundToDouble() * math.pi / 720;
    if (a != last) {
      last = a;
      out.add(a);
    }
  }, onError: (_) {},);
  ref.onDispose(() {
    sub.cancel();
    out.close();
  });
  return out.stream;
});

/// Drives the hover light on window frames wider than a phone (iPad trackpad, Android mouse).
class GlassLightHover extends ConsumerWidget {
  const GlassLightHover({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (GlassFrame.of(context) == GlassFrameKind.phone) return child;
    final width = MediaQuery.sizeOf(context).width;
    return MouseRegion(
      onHover: (e) => ref.read(glassHoverLightProvider.notifier).state = (e.position.dx / width).clamp(0.0, 1.0),
      onExit: (_) => ref.read(glassHoverLightProvider.notifier).state = null,
      child: child,
    );
  }
}
