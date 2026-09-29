import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A Cinematic dialog route (cinematic 7.10, Insert): a top-anchored clip reveal in 320 ms
/// `settle` with the barrier reaching 0.78 in 200 ms, a 160 ms `lift` fade out; reduced motion a
/// 150 ms cross-fade. Not dismissible while a destructive request runs ([locked]).
class CineDialogRoute<T> extends RawDialogRoute<T> {
  CineDialogRoute({
    required super.pageBuilder,
    this.reduced = false,
    super.settings,
    super.barrierLabel = 'Dismiss',
  }) : super(
          barrierColor: CineScrim.modal,
          transitionDuration: reduced ? CineDur.reduced : CineDur.column,
          transitionBuilder: (context, animation, secondary, child) => _insert(animation, child, reduced),
        );

  final bool reduced;
  bool _locked = false;

  /// While true the barrier and Android back do nothing.
  bool get locked => _locked;
  set locked(bool v) {
    if (_locked == v) return;
    _locked = v;
    changedInternalState();
  }

  @override
  bool get barrierDismissible => !_locked;

  @override
  Duration get reverseTransitionDuration => reduced ? CineDur.reduced : CineDur.beat;

  @override
  Curve get barrierCurve => reduced ? Curves.linear : Interval(0, CineDur.clip.inMilliseconds / CineDur.column.inMilliseconds);

  static Widget _insert(Animation<double> animation, Widget child, bool reduced) {
    if (reduced) return FadeTransition(opacity: animation, child: child);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final leaving = animation.status == AnimationStatus.reverse;
        final t = leaving ? 1.0 : CineCurves.settle.transform(animation.value.clamp(0.0, 1.0));
        final opacity = leaving ? CineCurves.lift.flipped.transform(animation.value.clamp(0.0, 1.0)) : 1.0;
        return Opacity(opacity: opacity, child: ClipRect(clipper: _InsertClip(t), child: child));
      },
    );
  }
}

class _InsertClip extends CustomClipper<Rect> {
  const _InsertClip(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, size.height * t);

  @override
  bool shouldReclip(_InsertClip old) => old.t != t;
}

/// Pushes [builder] as a [CineDialogRoute] on the root navigator.
Future<T?> showCineDialog<T>(BuildContext context, {required WidgetBuilder builder, bool rootNavigator = true}) {
  late final CineDialogRoute<T> route;
  route = CineDialogRoute<T>(
    reduced: CineMotion.reduced(context),
    pageBuilder: (ctx, _, __) => _RouteScope(route: route, child: Builder(builder: builder)),
  );
  return Navigator.of(context, rootNavigator: rootNavigator).push(route);
}

class _RouteScope extends InheritedWidget {
  const _RouteScope({required this.route, required super.child});
  final CineDialogRoute<dynamic> route;

  @override
  bool updateShouldNotify(_RouteScope old) => old.route != route;
}

/// The enclosing [CineDialogRoute], to lock it while a request runs.
CineDialogRoute<dynamic>? cineDialogRouteOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_RouteScope>()?.route;
