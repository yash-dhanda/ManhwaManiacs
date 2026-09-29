import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/cinematic/wipe_geometry.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

ReaderEntry readerEntryFromExtra(Object? extra) =>
    extra is Map && extra['entry'] == 'wipe' ? ReaderEntry.wipe : ReaderEntry.dip;

const _kSnap = Duration(milliseconds: 120);
const _kReducedWipe = Duration(milliseconds: 200);
const _kReducedDip = Duration(milliseconds: 150);
const _kReaderBack = Duration(milliseconds: 440);

/// Route durations of a reader page, read once when the page is built.
({Duration forward, Duration reverse}) readerDurations(ReaderEntry entry, double width, {required bool reduced}) {
  if (reduced) {
    return (forward: entry == ReaderEntry.wipe ? _kReducedWipe : _kReducedDip, reverse: _kReducedDip);
  }
  return (
    forward: entry == ReaderEntry.wipe ? Duration(milliseconds: wipeTotalMs(wipeBladeCount(width))) : _kReaderBack,
    reverse: _kReaderBack,
  );
}

/// The one route page of every reader (`reader`, `readAll`, `novel` and their aliases): a
/// `SwipeablePage` whose child is the reader screen. `canSwipe` starts false on Android and true
/// on iOS; mobile/12 narrows it by layout and zoom. The transition builder paints the blades while
/// the route is going forward and the entry is `wipe`, the Dip for a `dip` entry, the Dip while the
/// route is reversing (a pop never replays the blades), and the finger-tracked slide during a
/// swipe.
Page<void> cineReaderPage(BuildContext context, GoRouterState state, Widget child) {
  final entry = readerEntryFromExtra(state.extra);
  final size = MediaQuery.sizeOf(context);
  final d = readerDurations(entry, size.width, reduced: CineRouteMotion.reduced);
  final reduced = CineRouteMotion.reduced;
  return SwipeablePage<void>(
    key: state.pageKey,
    name: state.name,
    canSwipe: defaultTargetPlatform == TargetPlatform.iOS,
    canOnlySwipeFromEdge: true,
    backGestureDetectionWidth: 20,
    transitionDuration: d.forward,
    reverseTransitionDuration: d.reverse,
    transitionBuilder: (context, animation, secondaryAnimation, isSwipeGesture, child) {
      if (isSwipeGesture && (ModalRoute.of(context)?.isCurrent ?? true)) {
        return CineSwipeSlide.top(animation: animation, child: child);
      }
      return AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        child: child,
        builder: (context, child) {
          if (secondaryAnimation.status != AnimationStatus.dismissed &&
              !(ModalRoute.of(context)?.isCurrent ?? true) &&
              Navigator.of(context).userGestureInProgress) {
            return CineSwipeSlide.beneath(secondaryAnimation: secondaryAnimation, child: child!);
          }
          if (animation.status == AnimationStatus.forward && entry == ReaderEntry.wipe) {
            return _WipeLayer(animation: animation, width: size.width, reduced: reduced, child: child!);
          }
          if (animation.status == AnimationStatus.forward || animation.status == AnimationStatus.reverse) {
            return _DipLayer(animation: animation, entryLanded: entry == ReaderEntry.dip, child: child!);
          }
          return child!;
        },
      );
    },
    builder: (_) => child,
  );
}

/// The Dip of a reader: the enter fires `reader.enter` once when the black holds.
class _DipLayer extends StatefulWidget {
  const _DipLayer({required this.animation, required this.entryLanded, required this.child});
  final Animation<double> animation;

  /// Whether a forward run of this layer is the reader's entry (fires `reader.enter` once).
  final bool entryLanded;
  final Widget child;

  @override
  State<_DipLayer> createState() => _DipLayerState();
}

class _DipLayerState extends State<_DipLayer> {
  bool _fired = false;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.animation,
        builder: (context, _) {
          if (widget.entryLanded && !_fired && widget.animation.status == AnimationStatus.forward && widget.animation.value >= 200 / 440) {
            _fired = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) cineFeedback(context, HapticEvent.readerEnter, sound: SoundEvent.readerEnter);
            });
          }
          return cineDipTransition(context: context, animation: widget.animation, child: widget.child);
        },
      );
}

/// The Column wipe: blades close over the previous page, hold, and open on page one. A tap during
/// the wipe jumps it to the open state in 120 ms. `reader.enter` fires when the last blade lands.
class _WipeLayer extends StatefulWidget {
  const _WipeLayer({required this.animation, required this.width, required this.reduced, required this.child});
  final Animation<double> animation;
  final double width;
  final bool reduced;
  final Widget child;

  @override
  State<_WipeLayer> createState() => _WipeLayerState();
}

class _WipeLayerState extends State<_WipeLayer> with SingleTickerProviderStateMixin {
  late final int _blades = wipeBladeCount(widget.width);
  late final AnimationController _snap = AnimationController(vsync: this, duration: _kSnap);
  bool _fired = false;
  bool _snapped = false;

  double get _total => widget.reduced ? _kReducedWipe.inMilliseconds.toDouble() : wipeTotalMs(_blades).toDouble();
  double get _landedAt => widget.reduced ? 100 : (wipeCloseMs(_blades) + kWipeHoldMs).toDouble();

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _tap() {
    if (_snapped) return;
    final route = context.getSwipeablePageRoute<void>();
    // ignore: invalid_use_of_protected_member
    final controller = route?.controller;
    if (controller == null || !controller.isAnimating) return;
    _snapped = true;
    _fireOnce();
    _snap.forward(from: 0);
    controller.animateTo(1, duration: _kSnap);
  }

  void _fireOnce() {
    if (_fired) return;
    _fired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cineFeedback(context, HapticEvent.readerEnter, sound: SoundEvent.readerEnter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return CineMoveTracker(
      name: MotionName.columnWipe,
      animation: widget.animation,
      plannedIn: _total.round(),
      plannedOut: _total.round(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _tap(),
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.animation, _snap]),
          child: widget.child,
          builder: (context, child) {
            final ms = widget.animation.value * _total;
            if (ms >= _landedAt) _fireOnce();
            final covered = ms < _landedAt && !_snapped;
            final fade = _snapped ? 1 - _snap.value : 1.0;
            final overlay = widget.reduced
                ? ColoredBox(color: Color.fromRGBO(0, 0, 0, (ms < 100 ? ms / 100 : (200 - ms) / 100).clamp(0.0, 1.0) * fade))
                : CustomPaint(
                    painter: ColumnWipePainter(
                      progress: widget.animation.value,
                      blades: _blades,
                      viewLeft: mq.viewPadding.left,
                      viewRight: mq.viewPadding.right,
                      opacity: fade,
                    ),
                  );
            return Stack(fit: StackFit.passthrough, children: [
              Opacity(opacity: covered ? 0 : 1, child: child),
              Positioned.fill(child: IgnorePointer(child: overlay)),
            ],);
          },
        ),
      ),
    );
  }
}
