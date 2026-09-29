import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Blades and timings of the Column wipe (DESIGN §4): phone 4 blades,
/// 248 + 40 + 328 = 616 ms; tablet 8 blades, 312 + 40 + 392 = 744 ms.
class WipeTimings {
  const WipeTimings(this.blades);
  final int blades;
  static const stagger = 16;
  static const hold = 40;
  int get closeMs => CineDur.wipeClose.inMilliseconds + stagger * (blades - 1);
  int get openMs => CineDur.wipeOpen.inMilliseconds + stagger * (blades - 1);
  int get totalMs => closeMs + hold + openMs;
  static WipeTimings forWidth(double w) => WipeTimings(w >= 600 ? 8 : 4);
}

/// Pushes [location] behind the Column wipe: blades close top-down, hold on
/// black while the route is pushed, then open bottom-down. [onLand] runs as
/// they land (the `reader.enter` haptic). Reduced motion: a 200 ms cross-fade
/// through black. TODO(mobile/06): the shared reader-entry helper replaces this.
Future<void> enterReader(BuildContext context, String location, {VoidCallback? onLand}) {
  final router = GoRouter.of(context);
  return columnWipe(context, onCovered: () {
    onLand?.call();
    unawaited(router.push<void>(location));
  },);
}

Future<void> columnWipe(BuildContext context, {required VoidCallback onCovered}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    onCovered();
    return Future.value();
  }
  final done = Completer<void>();
  final reduced = MediaQuery.disableAnimationsOf(context);
  final timings = WipeTimings.forWidth(MediaQuery.sizeOf(context).width);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Wipe(
      timings: timings,
      reduced: reduced,
      onCovered: onCovered,
      onDone: () {
        entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _Wipe extends StatefulWidget {
  const _Wipe({
    required this.timings,
    required this.reduced,
    required this.onCovered,
    required this.onDone,
  });
  final WipeTimings timings;
  final bool reduced;
  final VoidCallback onCovered;
  final VoidCallback onDone;

  @override
  State<_Wipe> createState() => _WipeState();
}

class _WipeState extends State<_Wipe> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.reduced ? 200 : widget.timings.totalMs),
  );
  bool _covered = false;

  int get _coverAt => widget.reduced ? 100 : widget.timings.closeMs + WipeTimings.hold;

  @override
  void initState() {
    super.initState();
    _c
      ..addListener(() {
        if (!_covered && _c.value * _c.duration!.inMilliseconds >= _coverAt) {
          _covered = true;
          widget.onCovered();
        }
      })
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _c.value * _c.duration!.inMilliseconds;
            if (widget.reduced) {
              final o = ms < 100 ? ms / 100 : (200 - ms) / 100;
              return ColoredBox(color: Colors.black.withValues(alpha: o.clamp(0.0, 1.0)));
            }
            final tm = widget.timings;
            return LayoutBuilder(
              builder: (context, box) => Row(
                children: [
                  for (var i = 0; i < tm.blades; i++)
                    Expanded(
                      child: Builder(builder: (_) {
                        final closeP = ((ms - i * WipeTimings.stagger) /
                                CineDur.wipeClose.inMilliseconds)
                            .clamp(0.0, 1.0);
                        final openStart = tm.closeMs + WipeTimings.hold;
                        final openP = ((ms - openStart - i * WipeTimings.stagger) /
                                CineDur.wipeOpen.inMilliseconds)
                            .clamp(0.0, 1.0);
                        final opening = ms >= openStart;
                        final h = opening
                            ? box.maxHeight * (1 - CineCurves.settle.transform(openP))
                            : box.maxHeight * CineCurves.settle.transform(closeP);
                        return Align(
                          alignment: opening ? Alignment.bottomCenter : Alignment.topCenter,
                          child: SizedBox(
                              height: h, width: double.infinity, child: const ColoredBox(color: Colors.black),),
                        );
                      },),
                    ),
                ],
              ),
            );
          },
        ),
      );
}
