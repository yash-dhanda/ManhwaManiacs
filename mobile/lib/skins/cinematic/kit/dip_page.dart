import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const _dipOut = 160;
const _dipHold = 40;
const _dipIn = 240;
const _dipTotal = _dipOut + _dipHold + _dipIn;

/// Dip (§4.5): the old page dims to black over 160 ms, holds 40 ms, the new
/// page fades in over 240 ms. Reduced motion: a 150 ms fade.
///
/// TODO(mobile/06): the router's Dip builder owns this.
Widget dipTransition(BuildContext context, Animation<double> animation, Widget child) {
  if (cineReduced(context)) return FadeTransition(opacity: animation, child: child);
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final ms = animation.value * _dipTotal;
      final cover = (ms / _dipOut).clamp(0.0, 1.0);
      final inn = ((ms - _dipOut - _dipHold) / _dipIn).clamp(0.0, 1.0);
      return Stack(fit: StackFit.expand, children: [
        Opacity(opacity: cover, child: const ColoredBox(color: CineColors.paper0)),
        Opacity(opacity: CineCurves.settle.transform(inn), child: child),
      ],);
    },
  );
}

CustomTransitionPage<T> dipPage<T>({required LocalKey key, required Widget child}) => CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: _dipTotal),
      reverseTransitionDuration: const Duration(milliseconds: _dipTotal),
      transitionsBuilder: (context, animation, secondary, child) => dipTransition(context, animation, child),
    );

/// A non-opaque overlay route (the milestone title card): no path, same Dip.
class DipOverlayRoute<T> extends PageRoute<T> {
  DipOverlayRoute({required this.builder, this.label});

  final WidgetBuilder builder;
  final String? label;

  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => label;
  @override
  bool get opaque => false;
  @override
  bool get barrierDismissible => false;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: _dipTotal);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (cineReduced(context)) return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.linear), child: child);
    return dipTransition(context, animation, child);
  }
}
