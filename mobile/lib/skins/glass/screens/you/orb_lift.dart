import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show springOf;
import 'package:manhwamaniacs/skins/glass/shell/dock_geometry.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show GlassTab;
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:motor/motor.dart';

/// The profiles that have had their Orb lift this app session (in memory: `AppRestart` resets it).
final youOrbLiftShownProvider = StateProvider<Set<int>>((ref) => <int>{}, name: 'youOrbLiftShown');

/// The global rect of a dock tab on the phone frame (glass 7.15). The dock's geometry is a pure function of the window, so no
/// per-tab key is needed.
Rect dockTabRect(BuildContext context, GlassTab tab) => GlassDockGeometry.of(MediaQuery.sizeOf(context), MediaQuery.paddingOf(context)).tabRect(tab);

/// The Orb lift (glass 8.24, 4.10): a copy of the orb leaves the dock's You tab and lands in the profile block on `springZoom`,
/// scaling 24 -> 72. [progress] carries the recorded move (`GlassMotion.playMotor(MotionName.orbLift)`); [size] follows on the same
/// spring. Returns when the copy has landed and its entry is gone.
Future<void> runOrbLift({
  required BuildContext context,
  required TickerProvider vsync,
  required Rect from,
  required Rect to,
  required Widget Function(double size) orb,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final progress = SingleMotionController(motion: SpringMotion(springOf(GlassSprings.zoom)), vsync: vsync);
  final size = SingleMotionController(motion: SpringMotion(springOf(GlassSprings.zoom)), vsync: vsync, initialValue: 24);
  final entry = OverlayEntry(
    builder: (_) => AnimatedBuilder(
      animation: Listenable.merge([progress, size]),
      builder: (_, __) {
        final t = progress.value;
        final c = Offset.lerp(from.center, to.center, t)!;
        final s = size.value.clamp(12.0, 96.0);
        return Positioned(left: c.dx - s / 2, top: c.dy - s / 2, width: s, height: s, child: IgnorePointer(child: orb(s)));
      },
    ),
  );
  overlay.insert(entry);
  try {
    final scale = size.animateTo(to.width);
    await GlassMotion.playMotor(MotionName.orbLift, progress, 1);
    await scale.orCancel.catchError((Object _) {});
  } finally {
    entry.remove();
    entry.dispose();
    progress.dispose();
    size.dispose();
  }
}
