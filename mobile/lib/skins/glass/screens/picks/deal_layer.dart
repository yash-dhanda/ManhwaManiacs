import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/deal_path.dart';

/// Gap between two flights (glass 4.10, Deal).
const Duration kDealSpacing = Duration(milliseconds: 40);

/// One card in flight: from the Ask button's centre to its slot's rect.
class DealFlight {
  const DealFlight({required this.slot, required this.child});
  final Rect slot;
  final Widget child;
}

/// The Deal (glass 4.10): copies of the answer cards leave the Ask button's centre along a quadratic Bezier (control point 48 px off
/// the chord, toward the top), each landing on `springSnappy` 40 ms after the one before. Mount it in an `OverlayEntry`; [onDone]
/// fires when the last copy has landed. Reduced motion: no flight, [onDone] at once (the list fades in by itself).
class DealLayer extends ConsumerStatefulWidget {
  const DealLayer(
      {super.key,
      required this.origin,
      required this.flights,
      required this.onDone,
      this.reduced = false,});
  final Offset origin;
  final List<DealFlight> flights;
  final VoidCallback onDone;
  final bool reduced;

  @override
  ConsumerState<DealLayer> createState() => _DealLayerState();
}

class _DealLayerState extends ConsumerState<DealLayer>
    with TickerProviderStateMixin {
  late final List<AnimationController> _c = [
    for (final _ in widget.flights) AnimationController.unbounded(vsync: this),
  ];
  final List<Timer> _timers = [];

  /// The first-frame offset of flight [i] (its start), for tests.
  Offset startOf(int i) =>
      widget.origin -
      Offset(
          widget.flights[i].slot.width / 2, widget.flights[i].slot.height / 2,);

  @override
  void initState() {
    super.initState();
    if (widget.reduced || widget.flights.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return;
    }
    for (var i = 0; i < _c.length; i++) {
      _timers.add(Timer(kDealSpacing * i, () {
        if (!mounted) return;
        final f =
            GlassMotion.play(MotionName.deal, controller: _c[i], target: 1);
        if (i == _c.length - 1) {
          unawaited(f.whenComplete(() => mounted ? widget.onDone() : null));
        }
      }),);
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (var i = 0; i < widget.flights.length; i++)
            AnimatedBuilder(
              key: ValueKey('deal-flight-$i'),
              animation: _c[i],
              builder: (_, child) {
                final f = widget.flights[i];
                final t = _c[i].value;
                final start =
                    startOf(i) + Offset(f.slot.width / 2, f.slot.height / 2);
                final end = f.slot.center;
                final p = dealPoint(start, end, t);
                return Positioned(
                    left: p.dx - f.slot.width / 2,
                    top: p.dy - f.slot.height / 2,
                    width: f.slot.width,
                    height: f.slot.height,
                    child: Opacity(opacity: t <= 0 ? 0.0 : 1.0, child: child),);
              },
              child: widget.flights[i].child,
            ),
        ],
      ),
    );
  }
}
