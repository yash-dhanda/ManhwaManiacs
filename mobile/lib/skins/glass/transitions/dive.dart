import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart' show glassSound;
import 'package:manhwamaniacs/skins/skins.dart';

/// The shell root's dive state: 0 at rest, 1 fully dived. The shell scales to 0.94 and darkens with it (glass 4.10, Dive).
final ValueNotifier<double> glassDiveProgress = ValueNotifier(0);

/// Dive into a reader (glass 8.0.4): a black rect clip-reveals from [fromRect] to full screen on `springZoom` (558 ms) while the
/// shell scales to 0.94 and darkens; the route pushes at 60 % of the travel (the reader page has no transition of its own) and the
/// black fades out over the last 40 %. `reader.enter` and the `dive` cue fire on landing. Reduced motion: a 200 ms cross-fade.
/// The chapter start is prefetched on press by the reader engine (`mobile/34`) before this is called.
Future<void> enterReader(BuildContext context, WidgetRef ref, String location, {required Rect fromRect}) {
  final done = Completer<void>();
  final overlay = Overlay.of(context, rootOverlay: true);
  final router = ref.read(skinRouterProvider);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _DiveOverlay(
      from: fromRect,
      onPush: () => unawaited(router.push<void>(location)),
      onLanded: () {
        unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.readerEnter));
        glassSound(ref, SoundEvent.readerEnter);
      },
      onDone: () {
        entry.remove();
        glassDiveProgress.value = 0;
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _DiveOverlay extends StatefulWidget {
  const _DiveOverlay({required this.from, required this.onPush, required this.onLanded, required this.onDone});
  final Rect from;
  final VoidCallback onPush;
  final VoidCallback onLanded;
  final VoidCallback onDone;

  @override
  State<_DiveOverlay> createState() => _DiveOverlayState();
}

class _DiveOverlayState extends State<_DiveOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _pushed = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_tick);
    unawaited(GlassMotion.play(MotionName.dive, controller: _c, target: 1).whenComplete(() {
      widget.onLanded();
      widget.onDone();
    }),);
  }

  void _tick() {
    glassDiveProgress.value = _c.value.clamp(0.0, 1.0);
    if (!_pushed && _c.value >= 0.6) {
      _pushed = true;
      widget.onPush();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value.clamp(0.0, 1.0);
          final rect = Rect.lerp(widget.from, Offset.zero & size, t)!;
          // Black covers the travel, then fades over the last 40 %.
          final fade = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);
          return Opacity(
            opacity: fade,
            child: Stack(children: [Positioned.fromRect(rect: rect, child: const ColoredBox(color: Color(0xFF000000)))]),
          );
        },
      ),
    );
  }
}

/// Wraps the shell root: scales to 0.94 and darkens while a dive runs.
class GlassDiveScope extends StatelessWidget {
  const GlassDiveScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: glassDiveProgress,
        child: child,
        builder: (context, t, child) {
          if (t <= 0) return child!;
          return Transform.scale(scale: 1 - 0.06 * t, child: Stack(fit: StackFit.passthrough, children: [child!, Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, t))))]));
        },
      );
}
