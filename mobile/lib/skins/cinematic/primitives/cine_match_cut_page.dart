import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

const kMatchCutIn = Duration(milliseconds: 480);
const kMatchCutOut = Duration(milliseconds: 336);
const kPredictiveCommit = Duration(milliseconds: 240);

bool get _reduced =>
    WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

/// The Android fade-through, a pure function of route progress so a
/// predictive back gesture paints it too: outgoing scale 1.00 -> 0.95 and
/// opacity 1 -> 0 over progress 0 - 0.6, incoming opacity 0 -> 1 over 0.4 - 1.0.
({double outScale, double outOpacity, double inOpacity}) fadeThrough(double progress) {
  final p = progress.clamp(0.0, 1.0);
  final o = (p / 0.6).clamp(0.0, 1.0);
  return (
    outScale: 1 - 0.05 * o,
    outOpacity: 1 - o,
    inOpacity: ((p - 0.4) / 0.6).clamp(0.0, 1.0),
  );
}

/// Android: the match-cut route. The cover `Hero` carries the match; the rest
/// dissolves in 480 ms and out in 336 ms; predictive back fades through.
/// TODO(mobile/06): `CinePageTransitionsBuilder` owns the real gesture.
class CineMatchCutPage<T> extends CustomTransitionPage<T> {
  CineMatchCutPage({required super.child, super.key, super.name})
      : super(
          transitionDuration: _reduced ? const Duration(milliseconds: 200) : kMatchCutIn,
          reverseTransitionDuration: _reduced ? const Duration(milliseconds: 200) : kMatchCutOut,
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: CineCurves.turn,
              reverseCurve: CineCurves.settle,
            );
            return AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final f = fadeThrough(curved.value);
                return Opacity(
                  opacity: f.inOpacity,
                  child: child,
                );
              },
            );
          },
        );
}

/// The page a series opens on: `SwipeablePage` (edge swipe only, 20 pt) on
/// iOS so the cover `Hero` follows the finger; [CineMatchCutPage] elsewhere.
Page<void> cineMatchCutPage(GoRouterState state, Widget child) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return SwipeablePage<void>(
      key: state.pageKey,
      name: state.name,
      canOnlySwipeFromEdge: true,
      backGestureDetectionWidth: 20,
      transitionDuration: _reduced ? const Duration(milliseconds: 200) : kMatchCutIn,
      reverseTransitionDuration: _reduced ? const Duration(milliseconds: 200) : kMatchCutOut,
      transitionBuilder: (context, animation, secondary, isSwipe, child) => isSwipe
          ? SlideTransition(
              position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
              child: child,
            )
          : FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: CineCurves.turn),
              child: child,
            ),
      builder: (_) => child,
    );
  }
  return CineMatchCutPage<void>(key: state.pageKey, name: state.name, child: child);
}
