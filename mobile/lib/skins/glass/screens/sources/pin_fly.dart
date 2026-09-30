import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// The pin fly (glass 4.10): a copy of the row travels in the root overlay from [from] into [to] on `springZoom` (scale 1.03 while it
/// flies). Reduced motion: nothing flies; the row is simply there. Returns when the copy has landed.
Future<void> runPinFly(BuildContext context, WidgetRef ref, {required Rect from, required Rect to, required Widget Function() copy, required TickerProvider vsync}) async {
  if (ref.read(glassReducedProvider)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final c = AnimationController(vsync: vsync);
  final entry = OverlayEntry(
    builder: (_) => AnimatedBuilder(
      animation: c,
      builder: (_, child) {
        final t = c.value;
        final r = Rect.lerp(from, to, t)!;
        return Positioned.fromRect(rect: r, child: IgnorePointer(child: Transform.scale(scale: 1.03, child: child)));
      },
      child: copy(),
    ),
  );
  overlay.insert(entry);
  try {
    await GlassMotion.play(MotionName.pinFly, controller: c, target: 1);
  } finally {
    entry.remove();
    c.dispose();
  }
}
